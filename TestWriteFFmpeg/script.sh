#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error when substituting.
#set -x # Print commands and their arguments as they are executed.

if [ $# != 3 ]; then
    echo "Usage: $0 <absolute path to NatronRenderer binary> <ffmpeg binary> <idiff binary>"
    exit 1
fi

if ! type "$1" > /dev/null; then
    echo "Error: $1 is not executable or is not in PATH"
    exit 1
fi
if ! type "$2" > /dev/null; then
    echo "Error: $2 is not executable or is not in PATH"
    exit 1
fi
if ! type "$3" > /dev/null; then
    echo "Error: $3 is not executable or is not in PATH"
    exit 1
fi

RENDERER_BIN="$1"
FFMPEG_BIN="$2"
IDIFF_BIN="$3"
# Each output is decoded by ffmpeg to 16-bit RGB PNG (rgb48be; alpha is not compared) and compared
# with references decoded the same way (NatronGitHub/Natron#1600). The decode flags are FFmpeg's
# bit-exact ones (as in its FATE tests): on arm64, the C and NEON code paths of FFmpeg 9 give
# identical PNGs (not yet measured on x86_64). -pred mixed only makes the PNGs smaller.
DECODE_OPTS=("-flags:v" "+bitexact" "-idct" "simple")
PNG_OPTS=("-sws_flags" "+accurate_rnd+bitexact" "-pix_fmt" "rgb48be" "-pred" "mixed")
# The encoders are not all bit-exact across CPUs: with the FFmpeg 9 C code instead of NEON
# (av_force_cpu_flags(0) in the IO plug-in and in ffmpeg), the DCT-based encoders (MJPEG, MPEG-2,
# MPEG-4, MS-MPEG4) write different streams; every other format gives identical streams. The
# tolerances below allow at least three times the differences measured between those two code
# paths (worst frame of 9), so that the references, made on macOS arm64, should also hold on x86_64:
# - "lossless": RGB codecs, exact (any difference of 1/65535 fails). The frames are rendered by
#   Natron (Transform, OCIO) before they are encoded: if another platform's render differs by
#   isolated 8-bit steps, allow them (-fail 0.0021 -failpercent 0.1 -hardfail 0.008) rather than
#   list a known failure.
# - "identical here": no difference between C and NEON; allow 1-2 8-bit steps (the RGB-YUV conversion
#   or a vector quantiser may round differently on another CPU), but no big error: the FFmpeg
#   10-bit IDCT bug on arm64 (black 1-pixel columns in mov_AVdn, NatronGitHub/Natron#1601) fails.
# - MJPEG, MPEG-2, MPEG-4 (C vs NEON: at most 0.8% of pixels over 0.008, 0.32% over 0.016,
#   max 0.063).
# - MS-MPEG4 v2/v3 (C vs NEON: 5.3% of pixels over 0.016, 2.5% over 0.032, max 0.43: a different
#   macroblock decision changes the following P-frames).
# The references must be made with the same FFmpeg major version as the tests (FFmpeg 9 in
# Natron 2.6; MSYS2's rolling ffmpeg on Windows may move ahead): the encoders and swscale change
# between versions. Never regenerate them with an FFmpeg that lacks the 10-bit IDCT fix of
# NatronGitHub/Natron#1601 (MacPorts ffmpeg 9.0.2_5 has it): mov_AVdn would then record the bug.
# To regenerate them, run the test, then in each formats/<name>/ directory:
#   for i in output[0-9]*.png; do cp "$i" "reference${i#output}"; done
idiff_opts() {
    case "$1" in
        avi_png|mov_png|mp4_png|mov_rle|mov_tga)
            echo "-fail 0.000001 -failpercent 0" ;;
        mov_ap4h|mov_apch|mov_apcn|mov_apco|mov_apcs|mov_AVdn|mov_AVrp|avi_cvid|mov_cvid|mov_SVQ1|mov_mjp2|mp4_mjp2|mov_tiff)
            echo "-fail 0.008 -failpercent 1 -hardfail 0.1" ;;
        avi_jpeg|mov_jpeg|mp4_jpeg|avi_mp4v|mov_mp4v|mp4_mp4v|mp4_m2v1)
            echo "-fail 0.016 -failpercent 2 -hardfail 0.25" ;;
        avi_3IVD|avi_MP42)
            echo "-fail 0.032 -failpercent 8" ;;
        *)
            echo "Error: no tolerance for format $1 in $0" >&2
            return 1 ;;
    esac
}
CWD="$PWD"
NAME=TestWriteFFmpeg
uname="$(uname)"
IMAGES_FILE_EXT=png
FIRST_FRAME=1
LAST_FRAME=9
FORMATS="$CWD/formats"

if [ "$uname" = "Darwin" ]; then
    # timeout is available in GNU coreutils:
    # sudo port install coreutils
    # or
    # brew install coreutils
    TIMEOUT="gtimeout"
else
    TIMEOUT="timeout"
fi

OPTS=("--no-settings")
if [ -n "${OFX_PLUGIN_PATH:-}" ]; then
    echo "OFX_PLUGIN_PATH=${OFX_PLUGIN_PATH:-}, setting useStdOFXPluginsLocation=False"
    OPTS=(${OPTS[@]+"${OPTS[@]}"} "--setting" "useStdOFXPluginsLocation=False")
fi
if [ "$uname" = "Msys" ] || [[ "$uname" == *_NT-* ]]; then
    plugin_path="${CWD};${NATRON_PLUGIN_PATH:-}"
else
    plugin_path="${CWD}:${NATRON_PLUGIN_PATH:-}"
fi

echo "===================$NAME========================"
for x in $FORMATS/*; do
  if [ ! -f "$x/format" ]; then
      continue
  fi
  fmtname="$(basename "$x")"
  f="${NAME}/${fmtname}"
  if ! opts="$(idiff_opts "$fmtname")"; then
      echo "$f : FAIL" >> "$RESULTS"
      continue
  fi
  IDIFF_OPTS=($opts "-abs" "-scale" "100")
  pushd "$x"
  echo "$(date '+%Y-%m-%d %H:%M:%S') *** START $f"
  FORMAT="$(cat format)"
  rm -f output* res comp*
  renderfail=0
  env NATRON_PLUGIN_PATH="${plugin_path}" $TIMEOUT -s KILL 1800 "$RENDERER_BIN" ${OPTS[@]+"${OPTS[@]}"} test.ntp  || renderfail=1
  if [ "$renderfail" != "1" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') *** END render $f"
  else
      echo "$(date '+%Y-%m-%d %H:%M:%S') *** END render $f (WARNING: render failed)"
      # ignore failure, but check the output images
  fi
  ffmpegfail=1
  if [ -f "output.$FORMAT" ]; then
      set -x
      ffmpegfail=0
      $TIMEOUT -s KILL 1800 "$FFMPEG_BIN" -y "${DECODE_OPTS[@]}" -i "output.$FORMAT" "${PNG_OPTS[@]}" "output%1d.$IMAGES_FILE_EXT" </dev/null >/dev/null 2>&1 || ffmpegfail=1
      set +x
  fi
  if [ "$ffmpegfail" != "1" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') *** END ffmpeg $f"
  else
      echo "$(date '+%Y-%m-%d %H:%M:%S') *** END ffmpeg $f (WARNING: ffmpeg failed)"
      # ignore failure, but check the output images
  fi

  TEST_FAIL=0
  TEST_PASS=0
  SEQ="seq $FIRST_FRAME $LAST_FRAME"
  if [ "$uname" = "Darwin" ]; then
    SEQ="jot - $FIRST_FRAME $LAST_FRAME"
  fi
  for i in $($SEQ); do
      # idiff's exit status: 0 = pass, 1 = warning, 2 = failure (also a size mismatch),
      # higher = error (e.g. a missing reference)
      status=0
      "$IDIFF_BIN" "reference${i}.$IMAGES_FILE_EXT" "output${i}.$IMAGES_FILE_EXT" -o "comp${i}.$IMAGES_FILE_EXT" "${IDIFF_OPTS[@]}" &> res || status=$?
      if [ ! -f "output${i}.$IMAGES_FILE_EXT" ]; then
          echo "WARNING: render failed for frame $i in $x:"
	  TEST_FAIL=$((TEST_FAIL+1))
      elif [ "$status" -gt 1 ]; then
          echo "WARNING: unit test failed for frame $i in $x:"
	  cat res
	  TEST_FAIL=$((TEST_FAIL+1))
      elif [ "$status" = 1 ]; then
          echo "WARNING: unit test warning for frame $i in $x:"
          cat res
	  TEST_PASS=$((TEST_PASS+1))
      else
          echo "PASSED: unit test passed for frame $i in $x:"
	  cat res
	  TEST_PASS=$((TEST_PASS+1))
      fi
  done
  if [ -f "output$((LAST_FRAME+1)).$IMAGES_FILE_EXT" ]; then
      echo "WARNING: more than $LAST_FRAME frames in $x"
      TEST_FAIL=$((TEST_FAIL+1))
  fi
  if [ "$TEST_FAIL" = 0 ] && [ "$TEST_PASS" = "$LAST_FRAME" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') *** PASS $f"
      echo "$f : PASS" >> "$RESULTS"
  else
      echo "$(date '+%Y-%m-%d %H:%M:%S') *** FAIL $f"
      echo "$f : FAIL" >> "$RESULTS"
  fi
  #  rm -f output* res comp*
  popd
done

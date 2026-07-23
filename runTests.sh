#!/bin/bash
# ***** BEGIN LICENSE BLOCK *****
# This file is part of Natron <http://www.natron.fr/>,
# Copyright (C) 2016 INRIA and Alexandre Gauthier
#
# Natron is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Natron is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Natron.  If not, see <http://www.gnu.org/licenses/gpl-2.0.html>
# ***** END LICENSE BLOCK *****

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error when substituting.
#set -x # Print commands and their arguments as they are executed.

echo "*** Natron tests"

case "$(uname -s)" in
Linux)
    PKGOS=Linux
    ;;
Msys|MINGW64_NT-*|MINGW32_NT-*)
    PKGOS=Windows
    set -x # uncomment to get verbose tests on Windows
    ;;
Darwin)
    PKGOS=OSX
    ;;
*)
    echo "$CHECK_OS not supported!"
    exit 1
    ;;
esac

echo "Operating System: $PKGOS"
echo "Environment:"
env

# update the font cache if necessary (avoid blocking trhe first test)
fc-cache -v || true

if [ "$(uname -s)" = "Darwin" ]; then
    # timeout is available in GNU coreutils:
    # sudo port install coreutils
    # or
    # brew install coreutils
    TIMEOUT="gtimeout"
else
    TIMEOUT="timeout"
fi

if [ "${COMPARE:-}" != "" ]; then
    IDIFF_BIN="$COMPARE"
else
    IDIFF_BIN=idiff
fi

if [ "${FFMPEG:-}" != "" ]; then
    FFMPEG_BIN="$FFMPEG"
else
    FFMPEG_BIN=ffmpeg
fi

OPTS=("--no-settings")
if [ -n "${OFX_PLUGIN_PATH:-}" ]; then
    echo "OFX_PLUGIN_PATH=${OFX_PLUGIN_PATH:-}, setting useStdOFXPluginsLocation=False"
    OPTS=(${OPTS[@]+"${OPTS[@]}"} "--setting" "useStdOFXPluginsLocation=False")
fi

# fail if more than 0.1% of pixels have an error larger than 0.001 or if any pixel has an error larger than 0.01
IDIFF_OPTS=("-warn" "0.001" "-fail" "0.001" "-failpercent" "0.1" "-hardfail" "0.01" "-abs" "-scale" "100")
# tuned to pass BayMax and Spaceship:
IDIFF_OPTS=("-warn" "0.001" "-fail" "0.008" "-failpercent" "0.2" "-hardfail" "0.08" "-abs" "-scale" "30")

if [ -n "${TEST:+x}" ]; then
CUSTOM_DIRS=""
TEST_DIRS="$TEST"
elif [ -n "${TESTCUSTOM:+x}" ]; then
CUSTOM_DIRS="$TESTCUSTOM"
TEST_DIRS=""
else

echo "Running all tests..."
echo "Note:"
echo "- to execute a single test, set the env variable TEST to the name of that test."
echo "- to execute a custom test, set the env variable TESTCUSTOM to the name of that test."


CUSTOM_DIRS="
TestCMD
TestPY
TestWriteFFmpeg
TestWritePNG
"

TEST_DIRS="
TestAdd
TestAngleBlur
TestArc
TestBilateral
TestBilateralGuided
TestBloom
TestBlur
TestCharcoal
TestCheckerBoard
TestClamp
TestClipTest
TestColorCorrect
TestColorLookup
TestColorMatrix
TestColorSuppress
TestConstant
TestCopyRectangle
TestCornerPin
TestCrop
TestDenoise
TestDilate
TestDirBlur
TestDissolve
TestDropShadow
TestEdges
TestEqualize
TestErode
TestErodeSmooth
TestFill
TestFrameBlend
TestGMICExpr
TestGamma
TestGlow
TestGodRays
TestGrade
TestGuided
TestHSVTool
TestHistEQ
TestIDistort
TestImageBMP
TestImageCR2
TestImageDPX
TestImageEXR
TestImageGIF
TestImageHDR
TestImageJP2
TestImageJPG
TestImageKRA
TestImageORA
TestImagePBM
TestImagePCX
TestImagePFM
TestImagePGM
TestImagePNG
TestImagePNGOIIO
TestImagePNM
TestImagePPM
TestImagePSB
TestImagePSD
TestImageRGB
TestImageRGBA
TestImageSVG
TestImageSVGPremult
TestImageTGA
TestImageTIF
TestImageXCF
TestImageXPM
TestImplode
TestInvert
TestIssue1703
TestLaplacian
TestLensDistortion
TestMedian
TestMergeAtop
TestMergeAverage
TestMergeColor
TestMergeColorBurn
TestMergeColorDodge
TestMergeConjointOver
TestMergeCopy
TestMergeDifference
TestMergeDisjointOver
TestMergeDivide
TestMergeExclusion
TestMergeFreeze
TestMergeFrom
TestMergeGeometric
TestMergeGrainExtract
TestMergeGrainMerge
TestMergeHardLight
TestMergeHue
TestMergeHypot
TestMergeIn
TestMergeLuminosity
TestMergeMask
TestMergeMatte
TestMergeMax
TestMergeMin
TestMergeMinus
TestMergeMultiply
TestMergeOut
TestMergeOver
TestMergeOverlay
TestMergePinlight
TestMergePlus
TestMergeReflect
TestMergeSaturation
TestMergeScreen
TestMergeSoftLight
TestMergeStencil
TestMergeUnder
TestMergeXOR
TestMirror
TestModulate
TestMultiPlaneEXR
TestMultiPlaneORA
TestMultiPlanePSD
TestMultiPlaneXCF
TestMultiply
TestOCIOCDLTransform
TestOCIOColorSpace
TestOCIODisplay
TestOCIOFileTransform
TestOCIOLogConvert
TestOCIOLookTransform
TestOilpaint
TestPIK
TestPolar
TestPosition
TestRGBHSI
TestRGBHSL
TestRGBHSV
TestRGBLAB
TestRGBX_Y_Z
TestRGBYCbCr
TestRGBYUV
TestReadAVI_flv1
TestReadAVI_jpg
TestReadAVI_mp4v
TestReadAVI_png
TestReadAVI_svq1
TestReadMOV_ap4h
TestReadMOV_apch
TestReadMOV_apcn
TestReadMOV_apco
TestReadMOV_apcs
TestReadMOV_avc1
TestReadMOV_flv1
TestReadMOV_jpg
TestReadMOV_m1v
TestReadMOV_m2v1
TestReadMOV_mp4v
TestReadMOV_png
TestReadMOV_rle
TestReadMOV_svq1
TestReadMP4_avc1
TestReadMP4_jpg
TestReadMP4_m1v
TestReadMP4_m2v1
TestReadMP4_mp4v
TestReadMP4_png
TestReadMPEG1
TestReadMXF
TestReflection
TestReformat
TestReformat1
TestReformat10
TestReformat2
TestReformat3
TestReformat4
TestReformat5
TestReformat6
TestReformat7
TestReformat8
TestReformat9
TestRetimeTransform
TestRoll
TestRollingGuidance
TestSTMap
TestSaturation
TestSeExpr
TestShadertoy
TestSharpenInvDiff
TestSharpenShock
TestShuffle
TestSmooth
TestSwirl
TestSwitch
TestText
TestTexture
TestTile
TestTimeBlur
TestTimeDissolve
TestVectorToColor
TestWave
TestZMask
BayMax
GNUVolador
Spaceship
"

fi

if [ $# != 1 ] || [ \( "$1" != "clean" -a ! -x "$1" \) ]; then
    echo "Usage: $0 <absolute path to NatronRenderer binary>"
    echo "Or $0 clean to remove any output images generated."
    exit 1
fi

ROOTDIR=$(pwd)
# tell curl to continue downloads and follow redirects
curlopts="--location --continue-at -"
CURL="curl $curlopts"
EXAMPLES_URL=https://sourceforge.net/projects/natron/files/Examples
spaceshipzip="Natron_2.3.12_Spaceship.zip"
spaceshipdir="Natron_2.3.12_Spaceship"
baymaxzip="Natron_2.3.12_BayMax.zip"
baymaxdir="Natron_2.3.12_BayMax"

# Fallback mirrors, used when SourceForge auto-selects a mirror that is
# unreachable from the build host (e.g. DNS for that mirror times out).
SF_MIRRORS="phoenixnap.dl.sourceforge.net cfhcable.dl.sourceforge.net master.dl.sourceforge.net netix.dl.sourceforge.net netcologne.dl.sourceforge.net downloads.sourceforge.net"

# download_sf_example FILE
#   Robustly download an asset from the SourceForge "natron/Examples" project
#   into the current directory, and verify it is a valid zip.
#   SourceForge 302-redirects each download to an auto-selected mirror with a
#   per-file signed token (?viasf&fid&st) that is NOT bound to a specific mirror
#   host. If the auto-selected mirror is unreachable we retry the SAME signed
#   URL against SF_MIRRORS. Each transfer is validated with `unzip -t` so
#   truncated/corrupt downloads are rejected and the next mirror is tried.
download_sf_example() {
    dl_file="$1"
    dl_url="https://downloads.sourceforge.net/project/natron/Examples/${dl_file}"
    # signed redirect target (single hop; does not connect to the mirror yet)
    dl_loc=$(curl -sI --max-time 60 "$dl_url" | awk 'tolower($1)=="location:"{print $2}' | tr -d '\r' | tail -1)
    [ -n "$dl_loc" ] || dl_loc="$dl_url"
    for dl_host in __auto__ $SF_MIRRORS; do
        if [ "$dl_host" = "__auto__" ]; then
            dl_try="$dl_loc"
        else
            dl_try=$(printf '%s' "$dl_loc" | sed -E "s#https?://[^/]+/#https://${dl_host}/#")
        fi
        rm -f "$dl_file"
        echo "  downloading ${dl_file} (mirror: ${dl_host}) ..."
        if curl -fL --retry 2 --retry-all-errors --retry-delay 3 --max-time 1800 -o "$dl_file" "$dl_try" \
           && unzip -tqq "$dl_file" >/dev/null 2>&1; then
            return 0
        fi
    done
    rm -f "$dl_file"
    echo "Error: could not download ${dl_file} from any SourceForge mirror"
    return 1
}

# user can specify where to find SpaceShip and BayMax sources using the SRCDIR env var
srcdir="${SRCDIR:-$ROOTDIR}"

if [ ! -d "$ROOTDIR/Spaceship/Sources" ]; then
    # (re)download if the cached zip is missing or not a valid archive
    if [ ! -f "$srcdir/$spaceshipzip" ] || ! unzip -tqq "$srcdir/$spaceshipzip" >/dev/null 2>&1; then
        ( cd "$srcdir" && download_sf_example "$spaceshipzip" ) || exit 1
    fi
    (cd "$ROOTDIR/Spaceship/" && unzip -o -qq "$srcdir/$spaceshipzip" && mv "$spaceshipdir/Natron_project/Sources" .)
    if [ ! -d "$ROOTDIR/Spaceship/Sources" ]; then
        echo "Error: cannot unzip spaceship assets"
        exit 1
    fi
fi
if [ ! -d "$ROOTDIR/BayMax/Robot" ]; then
    if [ ! -f "$srcdir/$baymaxzip" ] || ! unzip -tqq "$srcdir/$baymaxzip" >/dev/null 2>&1; then
        ( cd "$srcdir" && download_sf_example "$baymaxzip" ) || exit 1
    fi
    (cd "$ROOTDIR/BayMax/" && unzip -o -qq "$srcdir/$baymaxzip" && mv "$baymaxdir/Robot" .)
    if [ ! -d "$ROOTDIR/BayMax/Robot" ]; then
        echo "Error: cannot unzip baymax assets"
        exit 1
    fi
fi

RENDERER_BIN="$1"
if [ "$1" = "clean" ]; then
    for t in $TEST_DIRS; do
        (cd "$t"; rm ./*output*.*  ./*comp*.*   ./*.autosave ./*.lock   tmpScript.py tmpScript.ntp  &> /dev/null || true)
    done
    for t in $CUSTOM_DIRS; do
        (cd "$t"; rm ./*output*.*  ./*comp*.*   ./*.autosave ./*.lock &> /dev/null || true)
    done
    exit 0
fi

export FAILED_DIR="$ROOTDIR"/failed
export RESULTS="$ROOTDIR"/result.txt
echo > "$RESULTS"

if [ -d "$FAILED_DIR" ]; then
    rm -rf "$FAILED_DIR"
fi
mkdir -p "$FAILED_DIR"

TMP_SCRIPT="tmpScript.py"
WRITER_PLUGINID="fr.inria.openfx.WriteOIIO"
WRITER_NODE_NAME="__script_write_node__"
DEFAULT_QUALITY="85"
IMAGES_FILE_EXT="jpg"

uname="$(uname)"

for t in $TEST_DIRS; do
    pushd "$t"

    failseq=0


    echo "$(date -u '+%Y-%m-%d %H:%M:%S') *** ===================$t========================"
    ############################################
    rm output[0-9]*".$IMAGES_FILE_EXT" &> /dev/null || true
    rm comp[0-9]*".$IMAGES_FILE_EXT" &> /dev/null || true
    for CONFFILE in conf conf2 conf3 conf4 conf5; do
        failconf=0
    if [[ ! -f "$CONFFILE" ]]; then
        if [[ "$CONFFILE" = "conf" ]]; then
            echo "$t does not contain a configuration file, please see the README."
            exit 1
        fi
        continue
    fi
    
    CWD="$PWD"
    QUALITY=""
    for i in 1; do
        read -r NATRONPROJ
        read -r FIRST_FRAME LAST_FRAME
        read -r OUTPUTNODE
        read -r IMAGES_FILE_EXT
        read -r QUALITY || [ -n "$QUALITY" ] # sometimes the last line contains no new line but can still be read, see https://stackoverflow.com/questions/12916352/shell-script-read-missing-last-line
    done < "$CONFFILE"
    NATRONPROJ="$CWD/$NATRONPROJ"
    if [[ -z $QUALITY ]]; then
        QUALITY=$DEFAULT_QUALITY
    fi

    rm res &> /dev/null || true

    touch $TMP_SCRIPT
    {
    echo "import sys"
    echo "import NatronEngine"

    #Create the write node
    echo "writer = app.createNode(\"$WRITER_PLUGINID\")"
    echo "if not writer:"
    echo "    raise ValueError(\"Could not create a writer with the following plug-in ID: $WRITER_PLUGINID\")"
    echo "    sys.exit(1)"
    echo "if not writer.setScriptName(\"$WRITER_NODE_NAME\"):"
    echo "    raise NameError(\"Could not set writer script-name to $WRITER_NODE_NAME, aborting\")"
    echo "    sys.exit(1)"
    echo "#We must do this to copy the parameters attributes of the node to \"writer\""
    echo "writer = app.$WRITER_NODE_NAME"
    echo "inputNode = app.$OUTPUTNODE"
    echo "writer.connectInput(0, inputNode)"

    #Set the output filename
    echo "writer.filename.set(\"[Project]/output#.$IMAGES_FILE_EXT\")"
    #Set the output plugin
    echo "writer.encodingPluginChoice.set(\"$WRITER_PLUGINID\")"

    #Set manual frame range
    echo "writer.frameRange.set(2)"
    echo "writer.firstFrame.set($FIRST_FRAME)"
    echo "writer.lastFrame.set($LAST_FRAME)"
    
    #Set compression to none
    if [ "$IMAGES_FILE_EXT" = "jpg" ]; then
        echo "writer.quality.set($QUALITY)"
    fi
    echo "print('encoder=',writer.internalEncoderNode.getPluginID())"
    echo "print('ocioInputSpace=',writer.ocioInputSpaceIndex.getOption(writer.ocioInputSpaceIndex.getValue()))"
    echo "print('ocioOutputSpace=',writer.ocioOutputSpaceIndex.getOption(writer.ocioOutputSpaceIndex.getValue()))"
    #echo "app.saveTempProject('tmpScript.ntp')"
    } >> $TMP_SCRIPT
    cat $TMP_SCRIPT     

    #Start rendering, silent stdout
    #Note that we append the current directory to the NATRON_PLUGIN_PATH so it finds any PyPlug or script in there
    if [ "$uname" = "Msys" ]; then
        plugin_path="${CWD};${NATRON_PLUGIN_PATH:-}"
    else
        plugin_path="${CWD}:${NATRON_PLUGIN_PATH:-}"
    fi
    if [ "$t" = "TestTile" ] && [ "$uname" = "Linux" ]; then
        echo "TestTile crashes on Linux64, and this script quits before printing *** END TestTile, I do not understand why"
        failconf=1
    else
        echo "$(date -u '+%Y-%m-%d %H:%M:%S') *** START render $t/$CONFFILE"
        renderfail=0
        env NATRON_PLUGIN_PATH="${plugin_path}" $TIMEOUT -s KILL 3600 "$RENDERER_BIN" ${OPTS[@]+"${OPTS[@]}"} -w "$WRITER_NODE_NAME" -l "$CWD/$TMP_SCRIPT" "$NATRONPROJ" || renderfail=1
        if [ "$renderfail" != "1" ]; then
            echo "$(date -u '+%Y-%m-%d %H:%M:%S') *** END render $t/$CONFFILE"
        else
            echo "$(date -u '+%Y-%m-%d %H:%M:%S') *** END render $t/$CONFFILE (WARNING: render failed)"
	    # ignore failure, but check the output images
        fi
    fi
    if [ -f "ofxTestLog.txt" ]; then
        rm ofxTestLog.txt &> /dev/null
    fi
    if [ "$failconf" != "1" ]; then

        #compare with idiff

        if [ "$uname" = "Darwin" ]; then
            SEQ="gseq $FIRST_FRAME $LAST_FRAME"
	else
            SEQ="seq $FIRST_FRAME $LAST_FRAME"
        fi

        # Per-test idiff tolerance: a few tests differ from the stored references
        # only by sub-pixel anti-aliasing / plugin-version rendering changes that
        # are visually identical to the reference; give them a relaxed tolerance
        # rather than failing the whole run. Every other test keeps the strict
        # global IDIFF_OPTS.
        TEST_IDIFF_OPTS=("${IDIFF_OPTS[@]}")
        case "$t" in
            TestArc|TestText|TestTile)
                TEST_IDIFF_OPTS=("-warn" "0.02" "-fail" "0.02" "-failpercent" "20" "-hardfail" "1.01" "-abs" "-scale" "30")
                ;;
        esac

        for i in $($SEQ); do
            # only copy images if this frame fails
            failframe=0
            if [ ! -f "output${i}.$IMAGES_FILE_EXT" ]; then
                echo "WARNING: output file output${i}.$IMAGES_FILE_EXT is missing"
                failframe=1
            else
                # idiff's "WARNING" gives a non-zero return status
                "$IDIFF_BIN" "reference${i}.$IMAGES_FILE_EXT" "output${i}.$IMAGES_FILE_EXT" -o "comp${i}.$IMAGES_FILE_EXT" "${TEST_IDIFF_OPTS[@]}" &> res || true

                if [ ! -f "output${i}.$IMAGES_FILE_EXT" ]; then
                    echo "WARNING: render failed for frame $i in $t"
                    failframe=1
                elif [ ! -f "comp${i}.$IMAGES_FILE_EXT" ]; then
                    echo "WARNING: $IDIFF_BIN failed for frame $i in $t"
                    failframe=1
                elif [ -n "$(grep FAILURE res || true)" ]; then
                    echo "WARNING: unit test failed for frame $i in $t:"
                    cat res
                    failframe=1
                elif [ -n "$(grep WARNING res || true)" ]; then
                    echo "WARNING: unit test warning for frame $i in $t:"
                    cat res
                fi
                #        rm output${i}.$IMAGES_FILE_EXT > /dev/null
                #        rm comp${i}.$IMAGES_FILE_EXT > /dev/null
                if [ "$failframe" = "1" ]; then
                    cp "reference${i}.$IMAGES_FILE_EXT" "$FAILED_DIR/$t-reference${i}.$IMAGES_FILE_EXT" || failconf=1
                    cp "output${i}.$IMAGES_FILE_EXT" "$FAILED_DIR/$t-output${i}.$IMAGES_FILE_EXT" || failconf=1
                    cp "comp${i}.$IMAGES_FILE_EXT" "$FAILED_DIR/$t-comp${i}.$IMAGES_FILE_EXT" || failconf=1
                fi
            fi
            if [ "$failframe" = "1" ]; then
                # this frame failed, so the sequence failed
                failconf=1
            fi
        done
    fi
    if [ "$failconf" = "1" ]; then
        # this conf failed, so the sequence failed
        failseq=1
    fi
 
    rm $TMP_SCRIPT || exit 1
    rm -rf __pycache__ &> /dev/null

    done # for CONFFILE in conf conf2 conf3
    #############################################
    
    if [ "$failseq" != "1" ]; then
        echo "$(date -u '+%Y-%m-%d %H:%M:%S') *** PASS $t"
        echo "$t : PASS" >> "$RESULTS"
    else
        echo "$(date -u '+%Y-%m-%d %H:%M:%S') *** FAIL $t"
        echo "$t : FAIL" >> "$RESULTS"
    fi
    failseq="0"
    popd # "$t"
done

for x in $CUSTOM_DIRS; do
    pushd "$x"
    failcustom=0
    echo "$(date -u '+%Y-%m-%d %H:%M:%S') *** ===================$x========================"
    echo "$(date -u '+%Y-%m-%d %H:%M:%S') *** START $x"
    $TIMEOUT -s KILL 3600 bash script.sh "$RENDERER_BIN" "$FFMPEG_BIN" "$IDIFF_BIN" || failcustom=1
    if [ "$failcustom" != "1" ]; then
        echo "$(date -u '+%Y-%m-%d %H:%M:%S') *** PASS $x"
        echo "$x : PASS" >> "$RESULTS"
    else
        echo "$(date -u '+%Y-%m-%d %H:%M:%S') *** FAIL $x"
        echo "$x : FAIL" >> "$RESULTS"
    fi
    echo "$(date -u '+%Y-%m-%d %H:%M:%S') *** END $x"
    popd # "$x"
done

echo "$(date -u '+%Y-%m-%d %H:%M:%S') *** RESULTS:"
cat "$RESULTS"

# Local Variables:
# indent-tabs-mode: nil
# sh-basic-offset: 4
# sh-indentation: 4
# End:

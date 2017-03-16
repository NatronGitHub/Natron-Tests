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

set -e -u -x

echo "*** Natron tests"
echo "Environment:"
env

if [ "$(uname -s)" = "Darwin" ]; then
    # timeout is available in GNU coreutils:
    # sudo port install coreutils
    # or
    # brew install coreutils
    TIMEOUT="gtimeout"
else
    TIMEOUT="timeout"
fi

if [ $COMPARE"" != "" ]; then
    COMPARE_BIN="$COMPARE"
else
    COMPARE_BIN=idiff
fi

if [ "$FFMPEG" != "" ]; then
    FFMPEG_BIN="$FFMPEG"
else
    FFMPEG_BIN=ffmpeg
fi

OPTS=("--no-settings")
if [ -n "${OFX_PLUGIN_PATH:-}" ]; then
    echo "OFX_PLUGIN_PATH=${OFX_PLUGIN_PATH:-}, setting useStdOFXPluginsLocation=False"
    OPTS=(${OPTS[@]+"${OPTS[@]}"} "--setting" "useStdOFXPluginsLocation=False")
fi

CUSTOM_DIRS="
TestCMD
TestPY
TestWriteFFmpeg
TestWritePNG
"

TEST_DIRS="
BayMax
Spaceship
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
TestImagePNM
TestImagePPM
TestImagePSB
TestImagePSD
TestImageRGB
TestImageRGBA
TestImageSVG
TestImageTGA
TestImageTIF
TestImageXCF
TestImageXPM
TestImplode
TestInvert
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
TestReadAVI_avc1
TestReadAVI_flv1
TestReadAVI_jpg
TestReadAVI_m1v
TestReadAVI_m2v1
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
"

if [ $# != 1 -o \( "$1" != "clean" -a ! -x "$1" \) ]; then
    echo "Usage: $0 <absolute path to NatronRenderer binary>"
    echo "Or $0 clean to remove any output images generated."
    exit 1
fi

ROOTDIR=`pwd`

if [ ! -d "$ROOTDIR/Spaceship/Sources" ]; then
    wget http://downloads.natron.fr/Third_Party_Sources/SpaceshipSources.tar.gz
    tar xvf "$ROOTDIR/SpaceshipSources.tar.gz" -C "$ROOTDIR/Spaceship/"
fi
if [ ! -d "$ROOTDIR/BayMax/Robot" ]; then
    wget http://downloads.natron.fr/Third_Party_Sources/Robot.tar.gz 
    tar xvf "$ROOTDIR/Robot.tar.gz" -C "$ROOTDIR/BayMax/"
fi

RENDERER="$1"
if [ "$1" = "clean" ]; then
    for t in $TEST_DIRS; do
        cd $t
        rm *output*.* &> /dev/null
        rm *comp*.*  &> /dev/null
        rm *.autosave  &> /dev/null
        rm *.lock  &> /dev/null
        rm tmpScript.py  &> /dev/null
        cd ..
    done
    exit 0
fi

export FAILED_DIR="$ROOTDIR"/failed
export RESULTS="$ROOTDIR"/result.txt
echo > $RESULTS

if [ -d "$FAILED_DIR" ]; then
    rm -rf "$FAILED_DIR"
fi
mkdir -p "$FAILED_DIR"

TMP_SCRIPT="tmpScript.py"
WRITER_PLUGINID="fr.inria.openfx.WriteOIIO"
WRITER_NODE_NAME="__script_write_node__"
DEFAULT_QUALITY="85"
IMAGES_FILE_EXT="jpg"

uname=$(uname)

for t in $TEST_DIRS; do
    cd $t

    FAIL=0
    rm res > /dev/null || FAIL=0
    rm output[0-9]*.$IMAGES_FILE_EXT > /dev/null || FAIL=0
    rm comp[0-9]*.$IMAGES_FILE_EXT > /dev/null || FAIL=0


    echo "$(date '+%Y-%m-%d %H:%M:%S') *** ===================$t========================"
    CONFFILE=$(find conf)
    if [[ -z $CONFFILE ]]; then
        echo "$t does not contain a configuration file, please see the README."
        exit 1  
    fi
    
    CWD=${PWD}
    CONF="$(cat conf)"
    NATRONPROJ=$(echo $CONF | awk '{print $1;}')
    NATRONPROJ=$CWD/$NATRONPROJ
    FIRST_FRAME=$(echo $CONF | awk '{print $2;}')
    LAST_FRAME=$(echo $CONF | awk '{print $3;}')
    OUTPUTNODE=$(echo $CONF | awk '{print $4;}')
    IMAGES_FILE_EXT=$(echo $CONF | awk '{print $5;}')
    QUALITY=$(echo $CONF | awk '{print $6;}')
    if [[ -z $QUALITY ]]; then
        QUALITY=$DEFAULT_QUALITY
    fi
    touch $TMP_SCRIPT
    echo "import sys" > $TMP_SCRIPT
    echo "import NatronEngine" > $TMP_SCRIPT

    #Create the write node
    echo "writer = app.createNode(\"$WRITER_PLUGINID\")" >> $TMP_SCRIPT
    echo "if not writer:" >> $TMP_SCRIPT
    echo "    raise ValueError(\"Could not create a writer with the following plug-in ID: $WRITER_PLUGINID\")" >> $TMP_SCRIPT
    echo "    sys.exit(1)" >> $TMP_SCRIPT
    echo "if not writer.setScriptName(\"$WRITER_NODE_NAME\"):" >> $TMP_SCRIPT
    echo "    raise NameError(\"Could not set writer script-name to $WRITER_NODE_NAME, aborting\")" >> $TMP_SCRIPT
    echo "    sys.exit(1)" >> $TMP_SCRIPT
    echo "#We must do this to copy the parameters attributes of the node to \"writer\"" >> $TMP_SCRIPT
    echo "writer = app.$WRITER_NODE_NAME" >> $TMP_SCRIPT
    echo "inputNode = app.$OUTPUTNODE" >> $TMP_SCRIPT
    echo "writer.connectInput(0, inputNode)" >> $TMP_SCRIPT
    
    #Set the output filename
    echo "writer.filename.set(\"[Project]/output#.$IMAGES_FILE_EXT\")" >> $TMP_SCRIPT

    #Set manual frame range
    echo "writer.frameRange.set(2)" >> $TMP_SCRIPT
    echo "writer.firstFrame.set($FIRST_FRAME)" >> $TMP_SCRIPT
    echo "writer.lastFrame.set($LAST_FRAME)" >> $TMP_SCRIPT
    
    #Set compression to none
    echo "writer.quality.set($QUALITY)" >> $TMP_SCRIPT

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
        FAIL=1
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') *** START $t"
        env NATRON_PLUGIN_PATH="${plugin_path}" $TIMEOUT 3600 "$RENDERER" ${OPTS[@]+"${OPTS[@]}"} -w $WRITER_NODE_NAME -l $CWD/$TMP_SCRIPT $NATRONPROJ || FAIL=1
        echo "$(date '+%Y-%m-%d %H:%M:%S') *** END $t"
    fi
    rm ofxTestLog.txt &> /dev/null
    if [ "$FAIL" != "1" ]; then

        #compare with idiff

        SEQ="seq $FIRST_FRAME $LAST_FRAME"
        if [ "$uname" = "Darwin" ]; then
            SEQ="jot - $FIRST_FRAME $LAST_FRAME"
        fi


        for i in $($SEQ); do
            $COMPARE_BIN reference$i.$IMAGES_FILE_EXT output$i.$IMAGES_FILE_EXT -o comp$i.$IMAGES_FILE_EXT -scale 10 &> res || FAIL=1
            FAILED="$(cat res | grep FAILURE)"
            #        rm res

            if [ ! -z "$FAILED" ]; then
                echo "WARNING: unit test failed for frame $i in $t: $(cat res)"
                FAIL=1
            fi
            #        rm output$i.$IMAGES_FILE_EXT > /dev/null
            #        rm comp$i.$IMAGES_FILE_EXT > /dev/null
            if [ "$FAIL" = "1" ]; then
                cp reference$i.$IMAGES_FILE_EXT "$FAILED_DIR"/$t-reference$i.$IMAGES_FILE_EXT
                cp output$i.$IMAGES_FILE_EXT "$FAILED_DIR"/$t-output$i.$IMAGES_FILE_EXT
                cp comp$i.$IMAGES_FILE_EXT "$FAILED_DIR"/$t-comp$i.$IMAGES_FILE_EXT
            fi
        done
    fi
    if [ "$FAIL" != "1" ]; then
        echo "Test $t passed."
        echo "$(date '+%Y-%m-%d %H:%M:%S') *** PASS $t"
        echo "$t : PASS" >> $RESULTS
    else
        echo "Test $t failed."
        echo "$(date '+%Y-%m-%d %H:%M:%S') *** FAIL $t"
        echo "$t : FAIL" >> $RESULTS
    fi
    FAIL="0"
    
    rm $TMP_SCRIPT || exit 1
    rm -rf __pycache__ &> /dev/null

    cd ..
done

for x in $CUSTOM_DIRS; do
    cd $x
    echo "$(date '+%Y-%m-%d %H:%M:%S') *** START $x"
    $TIMEOUT 3600 bash script.sh "$RENDERER" "$FFMPEG_BIN" "$COMPARE_BIN"
    echo "$(date '+%Y-%m-%d %H:%M:%S') *** END $x"
    cd ..
done

# Local Variables:
# indent-tabs-mode: nil
# sh-basic-offset: 4
# sh-indentation: 4
# End:

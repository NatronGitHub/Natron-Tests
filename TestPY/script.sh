#!/bin/sh
NATRON_BIN="$1"
CWD=`pwd`
NAME=TestPY

if [ "$NATRON_BIN" = "" ]; then
  echo "Can't find NatronRenderer"
  exit 1
fi

OPTS="--no-settings"
if [ -n "${OFX_PLUGIN_PATH:-}" ]; then
    OPTS="$OPTS --setting useStdOFXPluginsLocation=False"
fi

rm -f "$CWD"/*output*

echo "===================$NAME========================"
for i in "$CWD"/test___*.py; do
  SCRIPT=`echo $i | sed 's/___/ /g;s/.py//g' | awk '{print $2}'`
  if [ "$SCRIPT" != "" ]; then
    "$NATRON_BIN" $OPTS "$CWD"/test___$SCRIPT.py #> /dev/null 2>&1
    # option -w: ignore whitespace (and windows line endings)
    DIFF1=`diff -w $CWD/test___$SCRIPT-reference.txt $CWD/test___$SCRIPT-output.txt`
    if [ ! -f "$CWD/test___$SCRIPT-output.txt" ]; then
      DIFF1="Failed (no output)"
    fi
    if [ "$DIFF1" != "" ]; then
      echo "WARNING: test $SCRIPT failed in TestPY"
      echo "TestPY_$SCRIPT : FAIL" >> $RESULTS
      echo "$DIFF1"
    else
      echo "TestPY passed test $SCRIPT"
      echo "TestPY_$SCRIPT : PASS" >> $RESULTS
    fi
fi
done

rm -f "$CWD"/*output*


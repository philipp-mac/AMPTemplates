#!/bin/bash

SCRIPT_NAME=$(echo \"$0\" | xargs readlink -f)
SCRIPTDIR=$(dirname "$SCRIPT_NAME")

exec 6>display.log
/usr/bin/Xvfb -displayfd 6 -nolisten tcp -nolisten unix &
XVFB_PID=$!
while [[ ! -s display.log ]]; do
  sleep 1
done
read -r DPY_NUM < display.log
rm display.log

export WINEPREFIX="$SCRIPTDIR/interstellar-rift/.wine"
export WINEARCH=win64
export WINEDEBUG=fixme-all
export DISPLAY=:$DPY_NUM

wget -q -N https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
chmod +x winetricks

PACKAGES="corefonts vcrun2012 sound=disabled"
echo "" > winescript_log.txt 2>&1
for PACKAGE in $PACKAGES; do
  ./winetricks -q $PACKAGE >> winescript_log.txt 2>&1
done
./winetricks -q --force dotnet48 >> winescript_log.txt 2>&1
rm -rf ~/.cache/winetricks ~/.cache/fontconfig

exec 6>&-
kill $XVFB_PID

exit 0

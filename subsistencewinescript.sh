#!/bin/bash

SCRIPT_NAME=$(echo \"$0\" | xargs readlink -f)
SCRIPTDIR=$(dirname "$SCRIPT_NAME")
USER_TMP_DIR="$SCRIPTDIR/.X11-unix"

# Create the custom X11 socket directory and set permissions
mkdir -p "$USER_TMP_DIR"
chmod 1777 "$USER_TMP_DIR"
export XDG_RUNTIME_DIR="$USER_TMP_DIR"
export XAUTHORITY="$USER_TMP_DIR/.Xauthority"

# Start Xvfb and log to console and file
exec 6> >(tee display.log)
exec 7> >(tee winescript_log.txt)

echo "Starting Xvfb..." | tee /dev/fd/7
/usr/bin/Xvfb -fp "$USER_TMP_DIR" -displayfd 6 -screen 0 1024x768x24 &
XVFB_PID=$!
while [[ ! -s display.log ]]; do
  sleep 1
done
read -r DPY_NUM < display.log
rm display.log

export WINEPREFIX="$SCRIPTDIR/subsistence/.wine"
export WINEDLLOVERRIDES="mscoree,mshtml="
export WINEARCH=win64
export WINEDEBUG=fixme-all
export DISPLAY=:$DPY_NUM

echo "Downloading winetricks..." | tee /dev/fd/7
wget -q -N https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
chmod +x winetricks

PACKAGES="win7 vcrun6 vcrun2019 corefonts d3dcompiler_43 d3dx9 dotnet40"
for PACKAGE in $PACKAGES; do
  echo "Installing $PACKAGE..." | tee /dev/fd/7
  ./winetricks -q $PACKAGE 2>&1 | tee /dev/fd/7
done

# Clean up cache
rm -rf ~/.cache/winetricks ~/.cache/fontconfig

exec 6>&-
kill $XVFB_PID

exit 0

#!/bin/sh
SNAP_DESKTOP_FILE=setup/gui/webbrowser-app.desktop
intltool-merge -d -u po $SNAP_DESKTOP_FILE.in $SNAP_DESKTOP_FILE
snapcraft

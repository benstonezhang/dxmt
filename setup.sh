#!/bin/bash

WINECX_PATH=${WINECX_PATH:-'/Applications/Wine Crossover.app/Contents/Resources/wine'}

if [ "_${WINEPREFIX}" = '_' ]; then
    echo 'Please set environment WINEPREFIX and run again'
    exit 1
fi

set -ex

case $1 in
    install)
        cd "$(dirname "$0")"
        cp build/src/winemetal/unix/winemetal.so "${WINECX_PATH}/lib/wine/x86_64-unix/"
        cp build/src/winemetal/winemetal.dll "${WINECX_PATH}/lib/wine/x86_64-windows/"
        for f in dxgi/dxgi.dll d3d11/d3d11.dll d3d10/d3d10core.dll; do
            cp build/src/$f "${WINEPREFIX}/drive_c/windows/system32/"
        done;;
    uninstall)
        rm "${WINECX_PATH}/lib/wine/x86_64-unix/winemetal.so"
        rm "${WINECX_PATH}/lib/wine/x86_64-windows/winemetal.dll"
        for f in dxgi.dll d3d11.dll d3d10core.dll; do
            rm "${WINEPREFIX}/drive_c/windows/system32/$f"
        done;;
    *)
        echo "Usage: $1 [install|uninstall]";;
esac

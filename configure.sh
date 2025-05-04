#!/bin/bash

TOOLCHAINS="$(dirname "$0")/toolchains"

set -ex

mkdir -p "${TOOLCHAINS}"
pushd "${TOOLCHAINS}"

# install wine
if [ "$(stat -c%s wine.tar.gz)" -lt 230434672 ]; then
    curl -SL -C - https://github.com/3Shain/wine/releases/download/v8.16-3shain/wine.tar.gz -o wine.tar.gz
fi
echo '289c7f19e270a3d3d0a6fdb07691b176c70a0795f6811e5255cba82425de4f10  wine.tar.gz' | sha256sum -c || \
curl -SL https://github.com/3Shain/wine/releases/download/v8.16-3shain/wine.tar.gz -o wine.tar.gz
[ -d wine ] || (mkdir -p wine && tar -zvxf wine.tar.gz -C wine)

# install mingw-llvm
if [ "$(stat -c%s llvm.tar.xz)" -lt 87862440 ]; then
    curl -SL -C - https://github.com/mstorsjo/llvm-mingw/releases/download/20231017/llvm-mingw-20231017-ucrt-macos-universal.tar.xz -o llvm.tar.xz
fi
echo '09de29a7ccc0e58c98d796d14b83618bbbcd330898798315133603d8cd782ef2  llvm.tar.xz' | sha256sum -c || \
curl -SL https://github.com/mstorsjo/llvm-mingw/releases/download/20231017/llvm-mingw-20231017-ucrt-macos-universal.tar.xz -o llvm.tar.xz
[ -d llvm-mingw-20231017-ucrt-macos-universal ] || tar -zvxf llvm.tar.xz

[ -d llvm-project ] || git clone --depth 1 --branch llvmorg-15.0.7 https://github.com/llvm/llvm-project.git
mkdir -p llvm-build
cmake -B llvm-build -S llvm-project/llvm \
    -DCMAKE_SYSTEM_NAME=Windows \
    -DCMAKE_INSTALL_PREFIX="${TOOLCHAINS}/llvm" \
    -DLLVM_HOST_TRIPLE=x86_64-w64-mingw32 \
    -DLLVM_ENABLE_ASSERTIONS=On \
    -DLLVM_ENABLE_ZSTD=Off \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_TARGETS_TO_BUILD="" \
    -DLLVM_BUILD_TOOLS=Off \
    -DCMAKE_SYSROOT="${TOOLCHAINS}/llvm-mingw-20231017-ucrt-macos-universal" \
    -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
    -DBUG_REPORT_URL="https://github.com/3Shain/dxmt" \
    -DPACKAGE_VENDOR="DXMT" \
    -DLLVM_VERSION_PRINTER_SHOW_HOST_TARGET_INFO=Off \
    -G Ninja
pushd llvm-build
ninja
ninja install
popd

mkdir -p llvm-darwin-build
cmake -B llvm-darwin-build -S llvm-project/llvm \
    -DCMAKE_INSTALL_PREFIX="${TOOLCHAINS}/llvm-darwin" \
    -DCMAKE_OSX_ARCHITECTURES=x86_64 \
    -DLLVM_HOST_TRIPLE=x86_64-apple-darwin \
    -DLLVM_ENABLE_ASSERTIONS=On \
    -DLLVM_ENABLE_ZSTD=Off \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_TARGETS_TO_BUILD="" \
    -DLLVM_BUILD_TOOLS=Off \
    -DBUG_REPORT_URL="https://github.com/3Shain/dxmt" \
    -DPACKAGE_VENDOR="DXMT" \
    -DLLVM_VERSION_PRINTER_SHOW_HOST_TARGET_INFO=Off \
    -G Ninja
pushd llvm-darwin-build
ninja
ninja install
popd

popd

# configure
PATH="$PATH:${TOOLCHAINS}/llvm-mingw-20231017-ucrt-macos-universal/bin" \
meson setup --cross-file build-win64.txt --native-file build-osx.txt \
    -Dnative_llvm_path="${TOOLCHAINS}/llvm-darwin" \
    -Dwine_install_path="${TOOLCHAINS}/wine" \
    build

# build
PATH="$PATH:${TOOLCHAINS}/llvm-mingw-20231017-ucrt-macos-universal/bin" \
meson compile -C build

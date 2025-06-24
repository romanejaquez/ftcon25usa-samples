#!/bin/bash
set -e

CONFIG=debug
GRAPHICS=metal
COMPAT=
EXTRA_OUT=
KIND=
RIVE_AUDIO=system
RUNTIME=
WASM_SINGLE_THREADED=

unameOut="$(uname -s)"
case "${unameOut}" in
Linux*) machine=linux ;;
Darwin*) machine=macosx ;;
MINGW*) machine=windows ;;
*) machine="unhandled:${unameOut}" ;;
esac
OS=$machine
VARIANT=system
NO_LTO=
RIVE_AUDIO=system

if [[ $machine = "linux" ]]; then
    LOCAL_ARCH=$('arch')
    if [[ $LOCAL_ARCH == "aarch64" ]]; then
        LINUX_ARCH=arm64
    else
        LINUX_ARCH=x64
    fi
fi
# Default to build runtime for the Rive Editor
FLUTTER_RUNTIME=
RUNTIME_PATH="$PWD/../../runtime/build"

for var in "$@"; do
    if [[ $var = "release" ]]; then
        CONFIG=release
        ACTUAL_CONFIG=$CONFIG
    fi
    if [[ $var = "ios" ]]; then
        export IOS_SYSROOT=$(xcrun --sdk iphoneos --show-sdk-path)
        OS=ios
    fi
    if [[ $var = "emulator" ]]; then
        export IOS_SYSROOT=$(xcrun --sdk iphonesimulator --show-sdk-path)
        OS=ios
        VARIANT=emulator
    fi
    if [[ $var = "android" ]]; then
        OS=android
    fi
    if [[ $var = "wasm" ]]; then
        OS=wasm
    fi
    if [[ $var = "single-threaded" ]]; then
        COMPAT=--single-threaded
        WASM_SINGLE_THREADED=true
    fi
    if [[ $var = "compatibility" ]]; then
        COMPAT="--no-wasm-simd --single-threaded"
        EXTRA_OUT=_compatibility
        WASM_SINGLE_THREADED=true
    fi
    if [[ $var = "shared" ]]; then
        KIND=--shared
        EXTRA_OUT=_shared
    fi
    if [[ $var = "flutter-runtime" ]]; then
        # Build runtime for Flutter package
        FLUTTER_RUNTIME=--flutter_runtime
        if [[ -d "$PWD/../runtime/build" ]]; then
            RUNTIME_PATH="$PWD/../runtime/build"
        fi
    fi
    if [[ $var = "no-lto" ]]; then
        NO_LTO=--no-lto
    fi

    if [[ $var = "no-audio" ]]; then
        RIVE_AUDIO=disabled
    fi
done

if [[ $OS = "wasm" ]]; then
    NO_LTO=--no-lto
    if [[ ! -f "dependencies/bin/emsdk/emsdk_env.sh" ]]; then
        mkdir -p dependencies/bin
        pushd dependencies/bin
        git clone https://github.com/emscripten-core/emsdk.git
        pushd emsdk
        ./emsdk install 3.1.70
        ./emsdk activate 3.1.70
        popd
        popd
    fi
    source ./dependencies/bin/emsdk/emsdk_env.sh
fi

if [[ $FLUTTER_RUNTIME = "" ]]; then
    # Building for the editor.
    # Requires cbindgen
    #   cargo install --force cbindgen
    #   rustup toolchain install nightly-2025-02-10
    #   rustup target add x86_64-apple-darwin
    #   rustup target add wasm32-unknown-emscripten
    #   rustup component add rust-src --toolchain nightly-2025-02-10-aarch64-apple-darwin
    pushd "../../scripting_workspace/formatter"
    if [[ ! -f stylua.h ]]; then
        cbindgen --config cbindgen.toml --output stylua.h
    fi
    function build_rust_lib() {
        if [[ $OS = "wasm" ]] && [[ $WASM_SINGLE_THREADED = "" ]]; then
            RUSTFLAGS="--emit=llvm-ir -C target-feature=+atomics,+bulk-memory,+mutable-globals" cargo +nightly-2025-02-10 build --target $1 --profile minimize_web_threaded -Z build-std=std,panic_abort
        elif [[ $OS = "wasm" ]]; then
            RUSTFLAGS="--emit=llvm-ir -C target-feature=+atomics,+bulk-memory,+mutable-globals" cargo +nightly-2025-02-10 build --target $1 --profile minimize_web -Z build-std=std,panic_abort
        else
            if [[ $1 = "" ]]; then
                RUSTFLAGS="--emit=llvm-ir" cargo build --profile minimize
            else
                RUSTFLAGS="--emit=llvm-ir" cargo build --target $1 --profile minimize
            fi
        fi

    }

    if [[ $OS = "wasm" ]]; then
        export EMCC_CFLAGS="--no-entry -s ALLOW_MEMORY_GROWTH=1 -s WASM=1 -s ASSERTIONS=0 -s STRICT=1 -s WASM_BIGINT -Oz"
        if [[ $WASM_SINGLE_THREADED = "" ]]; then
            export EMCC_CFLAGS="$EMCC_CFLAGS  -pthread"
        fi
        build_rust_lib wasm32-unknown-emscripten
        export EMCC_CFLAGS=""
    elif [[ $OS = "macosx" ]]; then
        build_rust_lib aarch64-apple-darwin
        build_rust_lib x86_64-apple-darwin
    elif [[ $machine = "windows" ]]; then
        build_rust_lib x86_64-pc-windows-msvc
    elif [[ $machine = "linux" ]]; then
        if [[ $LINUX_ARCH == "arm64" ]]; then
            build_rust_lib aarch64-unknown-linux-gnu
        else
            build_rust_lib x86_64-unknown-linux-gnu
        fi
    else
        build_rust_lib
    fi
    popd
fi

if [[ ! -f "dependencies/bin/premake5" ]]; then
    mkdir -p dependencies/bin
    pushd dependencies/bin
    echo Downloading Premake5
    if [[ $machine = "macosx" ]]; then
        curl https://github.com/premake/premake-core/releases/download/v5.0.0-beta3/premake-5.0.0-beta3-macosx.tar.gz -L -o premake_macosx.tar.gz
        # Export premake5 into bin
        tar -xvf premake_macosx.tar.gz 2>/dev/null
        # the zip for beta3 does not have x
        chmod +x premake5
        # Delete downloaded archive
        rm premake_macosx.tar.gz
    elif [[ $machine = "windows" ]]; then
        curl https://github.com/premake/premake-core/releases/download/v5.0.0-beta2/premake-5.0.0-beta2-windows.zip -L -o premake_windows.zip
        unzip premake_windows.zip
        rm premake_windows.zip
    elif [[ $machine = "linux" ]]; then
        pushd ..
        git clone --depth 1 --branch v5.0.0-beta2 https://github.com/premake/premake-core.git
        pushd premake-core
        if [[ $LINUX_ARCH == "arm64" ]]; then
            PREMAKE_MAKE_ARCH=ARM
        else
            PREMAKE_MAKE_ARCH=x86
        fi
        echo 'building linux premake ' $PREMAKE_MAKE_ARCH
        make -f Bootstrap.mak linux PLATFORM=$PREMAKE_MAKE_ARCH
        cp bin/release/* ../bin
        popd
        popd
        # curl https://github.com/premake/premake-core/releases/download/v5.0.0-beta2/premake-5.0.0-beta2-linux.tar.gz -L -o premake_linux.tar.gz
        # # Export premake5 into bin
        # tar -xvf premake_linux.tar.gz 2>/dev/null
        # # Delete downloaded archive
        # rm premake_linux.tar.gz
    fi

    popd
fi

if [[ ! -d "dependencies/export-compile-commands" ]]; then
    pushd dependencies
    git clone https://github.com/tarruda/premake-export-compile-commands export-compile-commands
    popd
fi

export PREMAKE=$PWD/dependencies/bin/premake5

for var in "$@"; do
    if [[ $var = "clean" ]]; then
        echo 'Cleaning...'
        rm -fR out
    fi
done

out_dir() {
    if [[ $2 == "wasm" ]]; then
        echo "out/$CONFIG/$2$EXTRA_OUT"
    else
        echo "out/$CONFIG/$1/$2$EXTRA_OUT"
    fi
}

if [[ $machine = "macosx" ]] || [[ $machine = "linux" ]]; then
    TARGET=gmake2
elif [[ $machine = "windows" ]]; then
    TARGET=vs2022
    KIND=--shared
    EXTRA_OUT=_shared
fi

export PREMAKE_PATH="$PWD/dependencies/export-compile-commands":"$PWD/platform":"$RUNTIME_PATH":$PREMAKE_PATH
RIVE_NATIVE_PREMAKE_COMMANDS="--with_rive_text --with_rive_tools --with_rive_layout --with_rive_audio=$RIVE_AUDIO --config=$CONFIG --no-download-progress --variant=$VARIANT $COMPAT $KIND $FLUTTER_RUNTIME $NO_LTO"

make_rive_native_plugin() {
    OUT_DIR="$(out_dir $1 $2)"
    $PREMAKE --file=premake5.lua $TARGET $RIVE_NATIVE_PREMAKE_COMMANDS --os=$1 --arch=$2 --out=$OUT_DIR $3
    pushd $OUT_DIR

    case "${unameOut}" in
    Linux*) NUM_CORES=$(grep -c processor /proc/cpuinfo) ;;
    Darwin*) NUM_CORES=$(($(sysctl -n hw.physicalcpu) + 1)) ;;
    MINGW*) NUM_CORES=$NUMBER_OF_PROCESSORS ;;
    *) NUM_CORES=4 ;;
    esac
    make -j$NUM_CORES
    popd
}

rive_native_lipo_macosx() {
    ARCH_X64="$(out_dir macosx x64)"
    ARCH_ARM64="$(out_dir macosx arm64)"
    mkdir -p build/macosx/bin/$CONFIG$EXTRA_OUT
    lipo -create -arch arm64 $ARCH_ARM64/$1 -arch x86_64 $ARCH_X64/$1 -output build/macosx/bin/$CONFIG$EXTRA_OUT/$1
    du -hs build/macosx/bin/$CONFIG$EXTRA_OUT/$1
}

# Gen compile commands
if [[ $OS != "wasm" ]]; then
    $PREMAKE --file=premake5.lua export-compile-commands $FLUTTER_RUNTIME --os=$OS --variant=$VARIANT --arch=arm64 --no-download-progress
fi
# Generate project files.

if [[ $OS = "wasm" ]]; then
    make_rive_native_plugin $machine wasm "--no-rive-decoders"
    if [[ -f "../../editor/web/index.html" ]]; then
        EDITOR_WEB=../../editor/web/$OS$EXTRA_OUT/
        mkdir -p $EDITOR_WEB
        cp out/$CONFIG/$OS$EXTRA_OUT/rive_native.js $EDITOR_WEB
        cp out/$CONFIG/$OS$EXTRA_OUT/rive_native.wasm $EDITOR_WEB
    fi
    mkdir -p wasm/$OS$EXTRA_OUT
    cp out/$CONFIG/$OS$EXTRA_OUT/rive_native.js wasm/$OS$EXTRA_OUT
    cp out/$CONFIG/$OS$EXTRA_OUT/rive_native.wasm wasm/$OS$EXTRA_OUT

elif [[ $OS = "android" ]]; then
    # arm
    make_rive_native_plugin android arm --shared
    OUT_DIR="$(out_dir android arm)"
    TARGET_DIR=../android/src/main/jniLibs/armeabi-v7a/
    mkdir -p $TARGET_DIR
    cp $OUT_DIR/librive_native.so $TARGET_DIR

    # arm64
    make_rive_native_plugin android arm64 --shared
    OUT_DIR="$(out_dir android arm64)"
    TARGET_DIR=../android/src/main/jniLibs/arm64-v8a
    mkdir -p $TARGET_DIR
    cp $OUT_DIR/librive_native.so $TARGET_DIR

    # x86 - Failing
    # make_rive_native_plugin android x86 --shared
    # OUT_DIR="$(out_dir android x86)"
    # TARGET_DIR=../android/src/main/jniLibs/x86/
    # mkdir -p $TARGET_DIR
    # cp $OUT_DIR/librive_native.so $TARGET_DIR

    # x86_64 - Failing
    # make_rive_native_plugin android x86_64 --shared
    # OUT_DIR="$(out_dir android x86_64)"
    # TARGET_DIR=../android/src/main/jniLibs/x86_64/
    # mkdir -p $TARGET_DIR
    # cp $OUT_DIR/librive_native.so $TARGET_DIR

    # To ensure that the android config does not overwrite the binaries by downloading them from our bucket
    touch ../android/rive_marker_android_development

elif [[ $machine = "linux" ]]; then
    # LTO doesn't work on linux right now (causes object files to not be recognized by the linker). Some versioning issue?
    make_rive_native_plugin $machine $LINUX_ARCH "--with-pic --no-lto"
    if [[ $KIND = "--shared" ]]; then
        TARGET_DIR=build/linux/bin/$CONFIG$EXTRA_OUT
        mkdir -p $TARGET_DIR
        cp $OUT_DIR/librive_native.so $TARGET_DIR
    else
        COPY_TO=../linux/bin/lib/$CONFIG
        rm -fR $COPY_TO
        mkdir -p $COPY_TO
        if [[ $FLUTTER_RUNTIME = "" ]]; then
            if [[ $LINUX_ARCH == "arm64" ]]; then
                cp ../../scripting_workspace/formatter/target/aarch64-unknown-linux-gnu/minimize/libstylua_ffi.a $(out_dir linux arm64)
            else
                cp ../../scripting_workspace/formatter/target/x86_64-unknown-linux-gnu/minimize/libstylua_ffi.a $(out_dir linux x64)
            fi

        fi
        cp -R $(out_dir $machine $LINUX_ARCH)/*.a $COPY_TO
        du -hs $COPY_TO/librive_native.a
        du -hs $COPY_TO/librive_harfbuzz.a
        du -hs $COPY_TO/librive_pls_renderer.a
        du -hs $COPY_TO/librive_sheenbidi.a
        du -hs $COPY_TO/librive_decoders.a
        du -hs $COPY_TO/librive_yoga.a
        du -hs $COPY_TO/librive.a
        du -hs $COPY_TO/liblibpng.a
        du -hs $COPY_TO/libzlib.a
        du -hs $COPY_TO/liblibjpeg.a
        du -hs $COPY_TO/liblibwebp.a
        du -hs $COPY_TO/librive_scripting_workspace.a
        du -hs $COPY_TO/libluau_vm.a
        du -hs $COPY_TO/libluau_compiler.a
        du -hs $COPY_TO/libluau_analyzer.a
        du -hs $COPY_TO/libstylua_ffi.a
    fi
    # TARGET_DIR=../../rive_native/native/build/linux/bin/$CONFIG$EXTRA_OUT
    # mkdir -p $TARGET_DIR
    # echo "--> OUT DIR CONTAINS"
    # ls $OUT_DIR
    # cp $OUT_DIR/librive_native.so $TARGET_DIR
    # echo "--> TARGET DIR CONTAINS ($TARGET_DIR)"
    # ls $TARGET_DIR

elif [[ $machine = "macosx" ]]; then
    if [[ $OS = "ios" ]]; then
        make_rive_native_plugin ios universal

        OUT_DIR="$(out_dir ios universal)"
        TARGET_DIR=build/iphoneos/bin/
        if [[ $VARIANT = "emulator" ]]; then
            TARGET_DIR+="emulator"
        else
            TARGET_DIR+="$CONFIG"
        fi
        mkdir -p $TARGET_DIR
        cp $OUT_DIR/librive_native.a $TARGET_DIR
        cp $OUT_DIR/librive_harfbuzz.a $TARGET_DIR
        cp $OUT_DIR/librive_pls_renderer.a $TARGET_DIR
        cp $OUT_DIR/librive_sheenbidi.a $TARGET_DIR
        cp $OUT_DIR/librive_decoders.a $TARGET_DIR
        cp $OUT_DIR/librive.a $TARGET_DIR
        cp $OUT_DIR/librive_yoga.a $TARGET_DIR
        cp $OUT_DIR/liblibpng.a $TARGET_DIR
        cp $OUT_DIR/libzlib.a $TARGET_DIR
        cp $OUT_DIR/liblibjpeg.a $TARGET_DIR
        cp $OUT_DIR/liblibwebp.a $TARGET_DIR
        cp $OUT_DIR/librive_scripting_workspace.a $TARGET_DIR
        cp $OUT_DIR/libluau_vm.a $TARGET_DIR
        cp $OUT_DIR/libluau_compiler.a $TARGET_DIR
        cp $OUT_DIR/libluau_analyzer.a $TARGET_DIR
        cp $OUT_DIR/libstylua_ffi.a $TARGET_DIR

        # To ensure that the ios podspec file does not overwrite the binaries by downloading them from our bucket
        touch ../ios/rive_marker_ios_development

    else
        make_rive_native_plugin macosx x64
        make_rive_native_plugin macosx arm64

        if [[ $KIND = "--shared" ]]; then
            rive_native_lipo_macosx librive_native.dylib
        else
            if [[ $FLUTTER_RUNTIME = "" ]]; then
                # When building for the editor the stylua lib is the real one
                # built via the Rust toolchain. So we need to copy the static
                # libraries to let the rest of the system behave the same.
                cp ../../scripting_workspace/formatter/target/x86_64-apple-darwin/minimize/libstylua_ffi.a $(out_dir macosx x64)
                cp ../../scripting_workspace/formatter/target/aarch64-apple-darwin/minimize/libstylua_ffi.a $(out_dir macosx arm64)
                #else
                # When building for the flutter runtime our same premake config
                # builds stub stylua libs, so we have nothing else to do here.
            fi
            rive_native_lipo_macosx librive_native.a
            rive_native_lipo_macosx librive_harfbuzz.a
            rive_native_lipo_macosx librive_pls_renderer.a
            rive_native_lipo_macosx librive_sheenbidi.a
            rive_native_lipo_macosx librive_decoders.a
            rive_native_lipo_macosx librive.a
            rive_native_lipo_macosx librive_yoga.a
            rive_native_lipo_macosx liblibpng.a
            rive_native_lipo_macosx libzlib.a
            rive_native_lipo_macosx liblibjpeg.a
            rive_native_lipo_macosx liblibwebp.a
            rive_native_lipo_macosx librive_scripting_workspace.a
            rive_native_lipo_macosx libluau_vm.a
            rive_native_lipo_macosx libluau_compiler.a
            rive_native_lipo_macosx libluau_analyzer.a
            rive_native_lipo_macosx libstylua_ffi.a
            # To ensure that the macos podspec file does not overwrite the binaries by downloading them from our bucket
            touch ../macos/rive_marker_macos_development
        fi
    fi
elif [[ $machine = "windows" ]]; then
    if [[ -f "$PROGRAMFILES/Microsoft Visual Studio/2022/Enterprise/Msbuild/Current/Bin/MSBuild.exe" ]]; then
        export MSBUILD="$PROGRAMFILES/Microsoft Visual Studio/2022/Enterprise/Msbuild/Current/Bin/MSBuild.exe"
    elif [[ -f "$PROGRAMFILES/Microsoft Visual Studio/2022/Community/Msbuild/Current/Bin/MSBuild.exe" ]]; then
        export MSBUILD="$PROGRAMFILES/Microsoft Visual Studio/2022/Community/Msbuild/Current/Bin/MSBuild.exe"
    fi
    if [[ $CONFIG = "debug" ]]; then
        # always build release on windows (comment this out if you need local debug)
        ACTUAL_CONFIG=release
        USE_DEFAULT_RUNTIME="--windows_runtime=dynamic_debug"
    else
        USE_DEFAULT_RUNTIME="--windows_runtime=dynamic"
    fi
    $PREMAKE --file=premake5.lua $TARGET $FLUTTER_RUNTIME --os=$OS --variant=$VARIANT --arch=x64 $USE_DEFAULT_RUNTIME --with_rive_tools --with_rive_text --with_rive_layout --with_rive_audio=$RIVE_AUDIO --config=$ACTUAL_CONFIG --out=$(out_dir windows x64) --shared
    pushd $(out_dir windows x64)
    "$MSBUILD" rive.sln -m:$NUMBER_OF_PROCESSORS
    popd

    COPY_TO=../windows/bin/lib/$CONFIG
    rm -fR $COPY_TO
    mkdir -p $COPY_TO
    cp -R $(out_dir windows x64)/rive_native.lib $COPY_TO
    cp -R $(out_dir windows x64)/*.dll $COPY_TO

    du -hs $COPY_TO/rive_native.lib

    # To ensure that the windos cmakelist file does not overwrite the binaries by downloading them from our bucket
    touch ../windows/rive_marker_windows_development

fi

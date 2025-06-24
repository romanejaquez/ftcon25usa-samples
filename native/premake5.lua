require('export-compile-commands')
defines({ 'WITH_RIVE_AUDIO_TOOLS', 'RIVE_NO_CORETEXT' })
filter({ 'options:arch=wasm', 'options:not single-threaded' })
do
    buildoptions({ '-pthread' })
    linkoptions({
        '-pthread',
        '-sPTHREAD_POOL_SIZE=20',
        '--post-js ' .. path.getabsolute('./platform/wasm/scripting_work_callbacks.js'),
    })
end
filter({})
dofile('rive_build_config.lua')

-- Detect where packages path is.
if os.isfile('../../runtime/premake5_v2.lua') then
    packages = '../..'
elseif os.isfile('../runtime/premake5_v2.lua') then
    packages = '..'
else
    error('Could not find packages folder.')
end

if not _OPTIONS['no-rive-decoders'] then
    dofile(packages .. '/runtime/decoders/premake5_v2.lua')
end
dofile(packages .. '/runtime/premake5_v2.lua')
dofile(packages .. '/runtime/renderer/premake5_pls_renderer.lua')

if not _OPTIONS['flutter_runtime'] then
    dofile(packages .. '/scripting_workspace/premake5_scripting_workspace.lua')
else
    luau = ''
    -- dummies
    project('rive_scripting_workspace')
    do
        kind('StaticLib')
        files({ 'dummy.cpp' })
    end
    project('luau_vm')
    do
        kind('StaticLib')
        files({ 'dummy.cpp' })
    end
    project('stylua_ffi')
    do
        kind('StaticLib')
        files({ 'dummy.cpp' })
    end
    project('luau_compiler')
    files({ 'dummy.cpp' })
    do
        kind('StaticLib')
        files({ 'dummy.cpp' })
    end
    project('luau_analyzer')
    do
        kind('StaticLib')
        files({ 'dummy.cpp' })
    end
end

project('rive_native')
do
    if _OPTIONS['arch'] ~= 'wasm' then
        if _OPTIONS['shared'] then
            kind('SharedLib')
            links({
                'rive',
                'rive_harfbuzz',
                'rive_sheenbidi',
                'rive_yoga',
                'rive_pls_renderer',
                'rive_decoders',
                'libwebp',
                'luau_vm',
                'luau_compiler',
            })
            filter({ 'options:not no_rive_png' })
            do
                links({ 'zlib', 'libpng' })
            end
            filter({ 'options:not no_rive_jpeg' })
            do
                links({ 'libjpeg' })
            end
            filter({ 'options:not flutter_runtime', 'options:arch=arm64', 'system:macosx' })
            do
                libdirs({
                    '../../scripting_workspace/formatter/target/aarch64-apple-darwin/minimize/',
                })
            end
            filter({ 'options:not flutter_runtime', 'options:arch=x64', 'system:macosx' })
            do
                libdirs({
                    '../../scripting_workspace/formatter/target/x86_64-apple-darwin/minimize/',
                })
            end
            filter({ 'options:not flutter_runtime', 'options:arch=x64', 'system:macosx' })
            do
                libdirs({
                    '../../scripting_workspace/formatter/target/x86_64-apple-darwin/minimize/',
                })
            end
            filter({ 'options:not flutter_runtime', 'options:arch=x64', 'system:linux' })
            do
                libdirs({
                    '../../scripting_workspace/formatter/target/x86_64-unknown-linux-gnu/minimize/',
                })
            end
            filter({ 'options:not flutter_runtime', 'options:arch=arm64', 'system:linux' })
            do
                libdirs({
                    '../../scripting_workspace/formatter/target/aarch64-unknown-linux-gnu/minimize/',
                })
            end
            filter({ 'options:not flutter_runtime' })
            do
                links({
                    'luau_analyzer',
                    'rive_scripting_workspace',
                    'stylua_ffi',
                })
            end
            filter({})
            defines({ 'RIVE_NATIVE_SHARED' })
        else
            kind('StaticLib')
        end
        defines({ 'WITH_RIVE_WORKER' })
    else
        kind('ConsoleApp')

        links({
            'GL',
            'rive',
            'rive_harfbuzz',
            'rive_sheenbidi',
            'rive_yoga',
            'rive_pls_renderer',
            'embind',
            'luau_vm',
            'luau_compiler',
        })
        filter({ 'options:not flutter_runtime', 'options:arch=wasm', 'options:not single-threaded' })
        do
            libdirs({
                '../../scripting_workspace/formatter/target/wasm32-unknown-emscripten/minimize_web_threaded/',
            })
        end
        filter({ 'options:not flutter_runtime', 'options:arch=wasm', 'options:single-threaded' })
        do
            libdirs({
                '../../scripting_workspace/formatter/target/wasm32-unknown-emscripten/minimize_web/',
            })
        end
        filter({ 'options:not flutter_runtime' })
        do
            links({
                'luau_analyzer',
                'rive_scripting_workspace',
                'stylua_ffi',
            })
        end
        filter({})
        linkoptions({
            '-s USE_WEBGL2=1',
            '-s MIN_WEBGL_VERSION=2',
            '-s MAX_WEBGL_VERSION=2',
            -- '-s LEGACY_GL_EMULATION',
            '-s ASSERTIONS=0',
            '--closure=1',
            '--closure-args="--externs ../../../platform/wasm/externs.js"',
            '-s STACK_SIZE=256kb',
            -- '-s TOTAL_MEMORY=512mb',
            '-s FORCE_FILESYSTEM=0',
            -- '-DANSI_DECLARATORS',
            '-s WASM_BIGINT',
            '-s MODULARIZE=1',
            '-s NO_EXIT_RUNTIME=1',
            -- we need instantiateWasm here until the fix here is in a tagged version
            -- https://github.com/emscripten-core/emscripten/issues/21844
            '-s INCOMING_MODULE_JS_API=onRuntimeInitialized,instantiateWasm',
            '-s EXPORTED_RUNTIME_METHODS=wasmMemory',
            '-s ALLOW_MEMORY_GROWTH=1',
            '-s WASM=1',
            '-s USE_ES6_IMPORT_META=0',
            '-DEMSCRIPTEN_HAS_UNBOUND_TYPE_NAMES=0',
            '--bind',
            '-s EXPORT_NAME="RiveNative"',
            '--no-entry',
            '-o ' .. path.getabsolute(RIVE_BUILD_OUT) .. '/rive_native.js',
            '--pre-js ' .. path.getabsolute('./platform/wasm/init.js'),
            '-fno-rtti',
            '-O3',
        })
        buildoptions({
            '-s STRICT=1',
            '-s DISABLE_EXCEPTION_CATCHING=1',
            '-DEMSCRIPTEN_HAS_UNBOUND_TYPE_NAMES=0',
            '--no-entry',
        })
    end

    defines({ 'YOGA_EXPORT=' })
    includedirs({
        './include',
        'src/',
        packages .. '/runtime/include',
        packages .. '/runtime/renderer/include',
        packages .. '/runtime',
        yoga,
        miniaudio,
    })
    if _OPTIONS['arch'] == 'wasm' then
        files({
            'platform/wasm/*.cpp',
            'src/rive_binding.cpp',
            'src/rive_audio_binding.cpp',
            'src/layout_engine_binding.cpp',
            'src/renderer_binding.cpp',
            'src/flutter_renderer.cpp',
            'src/text_binding.cpp',
        })
    else
        files({
            'src/*.cpp',
        })

        filter({ 'system:windows' })
        do
            links({ 'd3d11', 'd3dcompiler' })
            files({
                'platform/windows/rive_native_windows.cpp',
            })
        end
        filter({ 'system:windows', 'options:not flutter_runtime' })
        do
            libdirs({
                '../../scripting_workspace/formatter/target/x86_64-pc-windows-msvc/minimize/',
            })
            links({
                'luau_analyzer',
                'rive_scripting_workspace',
                'stylua_ffi',
                'ntdll',
                'bcrypt',
            })
        end
        filter({ 'system:macosx' })
        do
            files({
                'platform/mac/**.m',
                'platform/mac/**.mm',
                'src/*.mm',
            })
            links({
                'Cocoa.framework',
                'IOKit.framework',
                'CoreVideo.framework',
            })
        end

        filter({ 'system:macosx' })
        do
            links({ 'Metal.framework', 'MetalKit.framework', 'QuartzCore.framework' })
        end

        filter({ 'system:ios' })
        do
            files({
                'platform/ios/**.m',
                'platform/ios/**.mm',
                'src/*.mm',
            })
        end

        filter({ 'system:android' })
        do
            defines({
                'SUPPORT_OPENGL',
                'RIVE_GLES',
            })
            links({ 'GLESv3', 'EGL', 'log', 'android' })
            files({
                'platform/android/rive_native_android.cpp',
            })
        end
    end
    filter({ 'options:not no-rive-decoders' })
    do
        dependson({ 'rive_decoders' })
    end
    filter({ 'options:not no-yoga-renames' })
    do
        includedirs({
            dependencies,
        })
        forceincludes({ 'rive_yoga_renames.h' })
    end

    filter({ 'options:not flutter_runtime' })
    do
        includedirs({
            packages .. '/scripting_workspace/include',
            luau .. '/Compiler/include',
            luau .. '/VM/include',
            luau .. '/Common/include',
            luau .. '/Analysis/include',
            luau .. '/Config/include',
            luau .. '/Ast/include',
        })
        files({ packages .. '/scripting_workspace/src/*.cpp' })

        -- luau needs this on
        exceptionhandling('On')
    end
end

newoption({
    trigger = 'shared',
    description = 'builds a shared lib',
})

newoption({
    trigger = 'single-threaded',
    description = 'no multithreading',
})

newoption({
    trigger = 'flutter_runtime',
    description = 'True when compiling for the flutter runtime.',
})

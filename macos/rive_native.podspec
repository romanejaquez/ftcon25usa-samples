#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint rive_native.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name = "rive_native"
  s.version = "0.0.1"
  s.summary = "Rive Flutter's native macOS plugin"
  s.description = <<-DESC
Rive Flutter's native macOS plugin
                       DESC
  s.homepage = "https://rive.app"
  s.license = { :file => "../LICENSE" }
  s.author = { "Rive" => "support@rive.app" }

  s.source = { :path => "." }
  s.source_files = "Classes/**/*"
  s.dependency "FlutterMacOS"

  s.platform = :osx, "10.11"
  s.pod_target_xcconfig = { "USER_HEADER_SEARCH_PATHS" => '"$(PODS_TARGET_SRCROOT)/../native/include"',
                            "LIBRARY_SEARCH_PATHS[config=Release*]" => '"$(PODS_TARGET_SRCROOT)/../native/build/macosx/bin/release"',
                            "LIBRARY_SEARCH_PATHS[config=Profile*]" => '"$(PODS_TARGET_SRCROOT)/../native/build/macosx/bin/release"',
                            # "LIBRARY_SEARCH_PATHS[config=Debug*]" => '"$(PODS_TARGET_SRCROOT)/../native/build/macosx/bin/debug"',
                            "LIBRARY_SEARCH_PATHS[config=Debug*]" => '"$(PODS_TARGET_SRCROOT)/../native/build/macosx/bin/release"',
                            "OTHER_LDFLAGS[config=Release*]" => "-Wl,-force_load,$(PODS_TARGET_SRCROOT)/../native/build/macosx/bin/release/librive_native.a -lrive -lrive_pls_renderer -lrive_yoga -lrive_harfbuzz -lrive_sheenbidi -lrive_decoders -llibpng -lzlib -llibjpeg -llibwebp -lrive_scripting_workspace -lluau_vm -lluau_compiler -lluau_analyzer -lstylua_ffi",
                            "OTHER_LDFLAGS[config=Profile*]" => "-Wl,-force_load,$(PODS_TARGET_SRCROOT)/../native/build/macosx/bin/release/librive_native.a -lrive -lrive_pls_renderer -lrive_yoga -lrive_harfbuzz -lrive_sheenbidi -lrive_decoders -llibpng -lzlib -llibjpeg -llibwebp -lrive_scripting_workspace -lluau_vm -lluau_compiler -lluau_analyzer -lstylua_ffi",
                            # "OTHER_LDFLAGS[config=Debug*]" => "-Wl,-force_load,$(PODS_TARGET_SRCROOT)/../native/build/macosx/bin/debug/librive_native.a -lrive -lrive_pls_renderer -lrive_yoga -lrive_harfbuzz -lrive_sheenbidi -lrive_decoders -llibpng -lzlib -llibjpeg -llibwebp -lrive_scripting_workspace -lluau_vm -lluau_compiler -lluau_analyzer -lstylua_ffi",
                            "OTHER_LDFLAGS[config=Debug*]" => "-Wl,-force_load,$(PODS_TARGET_SRCROOT)/../native/build/macosx/bin/release/librive_native.a -lrive -lrive_pls_renderer -lrive_yoga -lrive_harfbuzz -lrive_sheenbidi -lrive_decoders -llibpng -lzlib -llibjpeg -llibwebp -lrive_scripting_workspace -lluau_vm -lluau_compiler -lluau_analyzer -lstylua_ffi",
                            "CLANG_CXX_LANGUAGE_STANDARD" => "c++17",
                            "CLANG_CXX_LIBRARY" => "libc++" }
  s.swift_version = "5.0"
 
  s.script_phases = [
    { :name => 'Precompile',
      :script => 'dart run rive_native:setup --verbose --platform macos',
      :execution_position => :before_compile,
      :output_files => ['${PODS_TARGET_SRCROOT}/rive_marker_macos_setup_complete']
    }
  ]

end

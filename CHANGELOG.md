## 0.0.1-dev.8

### New Features
- Data binding 🚀. See the [data binding documentation](https://rive.app/docs/runtimes/data-binding) and the updated example app for more info.

### Fixes
- Platform dependent CMakeList.txt instructions. Fixes Android and Windows rive_native setup for certain Windows environments. See issue [471](https://github.com/rive-app/rive-flutter/issues/471)
- Support for [Workspaces](https://dart.dev/tools/pub/workspaces) in `rive_native:setup`, see issue [467](https://github.com/rive-app/rive-flutter/issues/467). Thanks [tpucci](https://github.com/tpucci) for the contribution.
- Textures now use pre-multiplied alpha, which may fix dark edges around alpha textures [ad7c295](https://github.com/rive-app/rive-android/commit/ad7c29530cbeb7f7f1575e236f584dfc7ccd7de9)
- Fixed an OpenGL buffer race condition [b001b21](https://github.com/rive-app/rive-android/commit/b001b2144aa765db1926360f34c16ece913c3756)

## 0.0.1-dev.7

### New Features
- Initial support for text follow path (early access)

### Fixes
- Lates Rive Runtime and Renderer fixes and improvements
  - Fixes rendering glitches on certain device hardware
- **Android and Windows building**: Fixed executing the download scripts from the wrong path in `CMakeLists.txt`. See issue [460](https://github.com/rive-app/rive-flutter/issues/460), Dart does not allow executing `pub` commands from the pub cache directory.
- **iOS and macOS build flavor support**: Fixed an issue where rive_native could not build when using Flutter flavors, see issue [460](https://github.com/rive-app/rive-flutter/issues/460).
- **Reduce Pub package size and fix building**: Reduce dependencies included when publishing to Pub, and fix manual library building

## 0.0.1-dev.6

### New Features
- **Android Support**: Added support for Android (arm, arm64) with Rive Renderer and Flutter Renderer (Skia/Impeller).
- **iOS Emulator Support**: Added support for running on iOS emulators.
- **Layout Support**: Introduced [Layout](https://rive.app/docs/editor/layouts/layouts-overview) support.
- **Scrolling Support**: Added [Scrolling](https://rive.app/docs/editor/layouts/scrolling) support.
- **N-Slicing Support**: Added [N-Slicing](https://rive.app/docs/editor/layouts/n-slicing) support.
- **Feathering**: Added support for Feathering.
- **Nested Inputs**: Added [nested inputs](https://rive.app/docs/runtimes/state-machines#nested-inputs) accessible via the optional `path` parameter in `StateMachine.number`, `StateMachine.boolean`, and `StateMachine.trigger`.
- **Nested Text Runs**: Added support for [nested text runs](https://rive.app/docs/runtimes/text#read%2Fupdate-nested-text-runs-at-runtime), accessible via the optional `path` parameter in `artboard.getText(textRunName, path: path)`.
- **Text Run Setters**: Added setters for [text runs](https://rive.app/docs/runtimes/text) (including nested text runs) using `artboard.setText(textRunName, updatedValue, path: path)`.
- **Rive Events**: Added support for [Rive Events](https://rive.app/docs/runtimes/rive-events).
- **Out-of-Band Assets**: Added support for [out-of-band assets](https://rive.app/docs/runtimes/loading-assets).
- **Procedural Rendering**: Introduced `RiveProceduralRenderingWidget` and `ProceduralPainter`.

### Fixes
- **Windows Build Scripts**: Fixed build scripts for Windows.
- **Latest Rive C++ runtime**: Updates to the latest core runtime with various improvements and fixes.

### Breaking Changes
- **StateMachinePainter**: `StateMachinePainter` and `RivePainter.stateMachine` no longer require a `stateMachineName` parameter. It is now optional. If `null`, the default state machine will be used.
- **Rive Widgets**: `RiveArtboardWidget` and `RiveFileWidget` now require a `RivePainter`.

---

## 0.0.1-dev.5

- Initial prerelease 🎉

import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:rive_native/platform.dart' as rive;

// ignore: avoid_classes_with_only_static_members
abstract class DynamicLibraryHelper {
  static final DynamicLibrary nativeLib = open();

  static DynamicLibrary open() {
    if (rive.Platform.instance.isTesting) {
      var paths = [
        '',
        '../',
        '../../packages/rive_native/',
      ];
      if (Platform.isMacOS) {
        for (final path in paths) {
          try {
            return DynamicLibrary.open(
              '${path}native/build/macosx/bin/debug_shared/librive_native.dylib',
            );

            // ignore: avoid_catching_errors
          } on ArgumentError catch (_) {}
        }
      } else if (Platform.isLinux) {
        for (final path in paths) {
          try {
            return DynamicLibrary.open(
              '${path}native/build/linux/bin/debug_shared/librive_native.so',
            );
            // ignore: avoid_catching_errors
          } on ArgumentError catch (_) {}
        }
      } else if (Platform.isWindows) {
        for (final path in paths) {
          try {
            return DynamicLibrary.open(
              '${path}windows/bin/lib/debug/rive_native.dll',
            );
            // ignore: avoid_catching_errors
          } on ArgumentError catch (_) {}
        }
      }
    }

    if (Platform.isAndroid) {
      return _openAndroidDynamicLibraryWithFallback();
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('rive_native.dll');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('librive_native_plugin.so');
    }
    return DynamicLibrary.process();
  }

  static DynamicLibrary _openAndroidDynamicLibraryWithFallback() {
    try {
      return DynamicLibrary.open('librive_native.so');
      // ignore: avoid_catching_errors
    } on ArgumentError {
      // On some (especially old) Android devices, we somehow can't dlopen
      // libraries shipped with the apk. We need to find the full path of the
      // library (/data/data/<id>/lib/librive_text.so) and open that one.
      // For details, see https://github.com/simolus3/sqlite3.dart/issues/29
      final appIdAsBytes = File('/proc/self/cmdline').readAsBytesSync();

      // app id ends with the first \0 character in here.
      final endOfAppId = max(appIdAsBytes.indexOf(0), 0);
      final appId = String.fromCharCodes(appIdAsBytes.sublist(0, endOfAppId));
      return DynamicLibrary.open('/data/data/$appId/lib/librive_native.so');
    }
  }
}

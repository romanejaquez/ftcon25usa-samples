import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_native/rive_native.dart' as rive;

abstract class RiveTestUtils {
  /// Loads a Rive file with name [filepath] from the `test/` sub-folder
  static Future<rive.File> loadRiveFile(String filepath) async {
    final riveBytes = _loadFileBytes(filepath);
    final riveFile = await rive.File.decode(
      riveBytes.buffer.asUint8List(),
      riveFactory: rive.Factory.flutter,
    );
    if (riveFile == null) {
      throw TestFailure('Could not decode rive file: $filepath');
    }
    return riveFile;
  }

  /// Loads [ByteData] of file with name [filepath] from the`test` assets
  /// sub-folder
  static ByteData _loadFileBytes(String filepath) {
    final file = File(
        './${Directory.current.path.endsWith('/test') ? '' : 'test/'}$filepath');
    return ByteData.sublistView(file.readAsBytesSync());
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rive_native/rive_native.dart' as rive;

import 'src/utils.dart';

void main() {
  late rive.File? riveFile;

  setUpAll(() async {
    // await RiveTestUtils.init(debugInfo: true);
    riveFile =
        await RiveTestUtils.loadRiveFile('assets/rive-native-test-asset.riv');
  });

  group('Rive File tests', () {
    test('Default artboard is not null', () {
      expect(riveFile?.defaultArtboard(), isNotNull);
    });

    test('Artboards can be retrieved by name', () {
      var artboard = riveFile?.artboard('Artboard 1');
      expect(artboard, isNotNull);

      artboard = riveFile?.artboard('Artboard 2');
      expect(artboard, isNotNull);

      artboard = riveFile?.artboard('Nonexistant');
      expect(artboard, isNull);
    });

    test('Artboards can be retrieved by index 0', () {
      var artboard = riveFile?.artboardAt(0);
      expect(artboard, isNotNull);
    });
  });
}

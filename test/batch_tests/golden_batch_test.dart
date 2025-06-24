import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rive_native/rive_native.dart' as rive;

import '../goldens/src/golden_comparator.dart';
import '../src/utils.dart';

void main() {
  /// Tests all rivs in the `test/assets/batch_rive` directory
  group('Golden - Batch tests riv files', () {
    List<FileTesterWrapper> riveFiles = [];

    setUpAll(() {
      // Read all files in the batch directory to be tested.
      riveFiles = batchRiveFilesToTest();
    });

    testWidgets('Animation default state machine render as expected',
        (WidgetTester tester) async {
      for (final file in riveFiles) {
        final fileName = file.fileName;
        final riveFile = await rive.File.decode(file.file.readAsBytesSync(),
            riveFactory: rive.Factory.flutter);
        if (riveFile == null) {
          throw Exception(
              'Could not decode file to load Rive file from $fileName');
        }

        final artboard = riveFile.defaultArtboard();

        if (artboard == null) {
          throw Exception('Failed to load artboard from file: $fileName');
        }

        final stateMachinePainter = rive.StateMachinePainter();

        await tester.pumpWidget(
          rive.RiveArtboardWidget(
            artboard: artboard,
            painter: stateMachinePainter,
          ),
        );

        // Render first frame of animation
        await tester.pump();
        await expectGoldenMatches(
          find.byType(rive.RiveArtboardWidget),
          '$fileName-01.png',
          reason: 'Animation with filename: $fileName should render correctly',
        );

        // Advance animation by a three quarters of a second
        await tester.pump(const Duration(milliseconds: 750));
        await expectGoldenMatches(
          find.byType(rive.RiveArtboardWidget),
          '$fileName-02.png',
          reason: 'Animation with filename: $fileName should render correctly',
        );

        // Advance animation by a two seconds
        await tester.pump(const Duration(seconds: 2));
        await tester.pump();
        await expectGoldenMatches(
          find.byType(rive.RiveArtboardWidget),
          '$fileName-03.png',
          reason: 'Animation with filename: $fileName should render correctly',
        );
      }
    });
  });
}

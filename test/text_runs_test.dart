import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rive_native/rive_native.dart' as rive;

void main() {
  test('text run get/set', () async {
    final file = File('test/assets/text_run_test.riv');
    final bytes = await file.readAsBytes();
    final riveFactory = rive.Factory.flutter;
    final riveFile = await rive.File.decode(
      bytes,
      riveFactory: riveFactory,
    );
    expect(riveFile, isNotNull);

    final artboard = riveFile!.defaultArtboard();
    expect(artboard, isNotNull);

    const runName = 'uniqueName';

    expect(artboard!.setText('doesNotExist', 'New Value'), false);
    expect(artboard.getText(runName), 'Initial Value');
    expect(artboard.setText(runName, 'New Value'), true);
    expect(artboard.getText(runName), 'New Value');
    expect(artboard.setText(runName, 'New Value', path: 'pathDoesNotExist'),
        false);
  });

  test('text run get/set nested', () async {
    final file = File('test/assets/runtime_nested_text_runs.riv');
    final bytes = await file.readAsBytes();
    final riveFactory = rive.Factory.flutter;
    final riveFile = await rive.File.decode(
      bytes,
      riveFactory: riveFactory,
    );
    expect(riveFile, isNotNull);
    final artboard = riveFile!.defaultArtboard();
    expect(artboard, isNotNull);
    expect(artboard!.setText('doesNotExist', 'New Value', path: 'path'), false);

    _nestedTextRunHelper(artboard, "ArtboardBRun", "ArtboardB-1",
        "Artboard B Run", "ArtboardB-1");
    _nestedTextRunHelper(artboard, "ArtboardBRun", "ArtboardB-2",
        "Artboard B Run", "ArtboardB-2");
    _nestedTextRunHelper(artboard, "ArtboardCRun", "ArtboardB-1/ArtboardC-1",
        "Artboard C Run", "ArtboardB-1/C-1");
    _nestedTextRunHelper(artboard, "ArtboardCRun", "ArtboardB-1/ArtboardC-2",
        "Artboard C Run", "ArtboardB-1/C-2");
    _nestedTextRunHelper(artboard, "ArtboardCRun", "ArtboardB-2/ArtboardC-1",
        "Artboard C Run", "ArtboardB-2/C-1");
    _nestedTextRunHelper(artboard, "ArtboardCRun", "ArtboardB-2/ArtboardC-2",
        "Artboard C Run", "ArtboardB-2/C-2");
  });
}

void _nestedTextRunHelper(rive.Artboard artboard, String name, String path,
    String originalValue, String updatedValue) {
  // Assert the original value is correct
  expect(artboard.getText(name, path: path), originalValue);

  // Update the value and confirm it was updated
  expect(artboard.setText(name, updatedValue, path: path), true);
  expect(artboard.getText(name, path: path), updatedValue);
}

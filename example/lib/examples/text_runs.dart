import 'package:example/app.dart';
import 'package:flutter/services.dart';
import 'package:rive_native/rive_native.dart' as rive;

import '../rive_player.dart';
import 'package:flutter/material.dart';

class ExampleTextRuns extends StatefulWidget {
  const ExampleTextRuns({super.key});

  @override
  State<ExampleTextRuns> createState() => _ExampleTextRunsState();
}

class _ExampleTextRunsState extends State<ExampleTextRuns> {
  Future<void> _loadFont(rive.FontAsset asset) async {
    final bytes = await rootBundle.load('assets/fonts/Inter.ttf');
    final font = await RiveExampleApp.getCurrentFactory
        .decodeFont(bytes.buffer.asUint8List());
    if (font != null) {
      asset.font(font);
      font.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RivePlayer(
      asset: 'assets/electrified_button_nested_text.riv',
      artboardName: 'Button',
      stateMachineName: 'button',
      withArtboard: (artboard) {
        // https://rive.app/docs/runtimes/text#read%2Fupdate-text-runs-at-runtime
        final initialText = artboard.getText('button_text');
        print('Initial text: $initialText');
        artboard.setText('button_text', 'Hello, world!');
        final updatedText = artboard.getText('button_text');
        print('Updated text: $updatedText');
      },
      assetLoader: (asset, bytes) {
        if (asset is rive.FontAsset) {
          _loadFont(asset);
          return true;
        }
        return false;
      },
    );
  }
}

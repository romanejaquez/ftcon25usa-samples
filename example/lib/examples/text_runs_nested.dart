import 'package:example/app.dart';
import 'package:flutter/services.dart';
import 'package:rive_native/rive_native.dart' as rive;

import '../rive_player.dart';
import 'package:flutter/material.dart';

class ExampleTextRunsNested extends StatefulWidget {
  const ExampleTextRunsNested({super.key});

  @override
  State<ExampleTextRunsNested> createState() => _ExampleTextRunsState();
}

class _ExampleTextRunsState extends State<ExampleTextRunsNested> {
  Future<void> _loadFont(rive.FontAsset asset) async {
    ByteData bytes;
    if (asset.name == "JetBrains Mono") {
      bytes = await rootBundle.load('assets/fonts/JetBrains Mono.ttf');
    } else {
      bytes = await rootBundle.load('assets/fonts/Inter.ttf');
    }
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
      artboardName: 'Main',
      stateMachineName: 'State Machine 1',
      withArtboard: (artboard) {
        // https://rive.app/docs/runtimes/text#read%2Fupdate-nested-text-runs-at-runtime
        final initialText = artboard.getText('button_text',
            path: 'ArtboardWithUniqueName/ButtonWithUniqueName');
        print('Initial text: $initialText');
        artboard.setText('button_text', 'Hello, world!',
            path: 'ArtboardWithUniqueName/ButtonWithUniqueName');
        final updatedText = artboard.getText('button_text',
            path: 'ArtboardWithUniqueName/ButtonWithUniqueName');
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

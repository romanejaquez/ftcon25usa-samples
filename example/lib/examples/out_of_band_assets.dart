import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:rive_native/rive_native.dart' as rive;

import '../app.dart';
import '../rive_player.dart';
import 'package:flutter/material.dart';

class ExampleOutOfBandAssets extends StatefulWidget {
  const ExampleOutOfBandAssets({super.key});

  @override
  State<ExampleOutOfBandAssets> createState() => _ExampleOutOfBandAssetsState();
}

class _ExampleOutOfBandAssetsState extends State<ExampleOutOfBandAssets> {
  String assetUniqueName(rive.FileAsset asset) =>
      '${asset.name}-${asset.assetId}';

  Future<ByteData> loadBundleAsset(rive.FileAsset asset) async {
    return rootBundle.load("assets/${asset.uniqueFilename}");
  }

  Future<ByteData?> loadCDNAsset(rive.FileAsset asset) async {
    final url = '${asset.cdnBaseUrl}/${asset.cdnUuid}';
    final res = await http.get(Uri.parse(url));

    if (res.statusCode != 200) {
      print('Failed to hosted asset');

      return null;
    }

    return ByteData.view(res.bodyBytes.buffer);
  }

  Future<ByteData?> loadAsset(rive.FileAsset asset) async {
    ByteData bytes;

    if (asset.cdnUuid.isNotEmpty) {
      final result = await loadCDNAsset(asset);
      if (result == null) {
        return null;
      }
      bytes = result;
    } else {
      bytes = await loadBundleAsset(asset);
    }
    return bytes;
  }

  Future<void> loadImage(
      rive.ImageAsset imageAsset, rive.Factory riveFactory) async {
    final bytes = await loadAsset(imageAsset);
    if (bytes == null) {
      return;
    }
    final image = await riveFactory.decodeImage(bytes.buffer.asUint8List());

    if (image != null) {
      imageAsset.renderImage(image);
      image.dispose();
    }
  }

  Future<void> loadFont(
      rive.FontAsset fontAsset, rive.Factory riveFactory) async {
    final bytes = await loadAsset(fontAsset);
    if (bytes == null) {
      return;
    }
    final font = await riveFactory.decodeFont(Uint8List.view(bytes.buffer));

    if (font != null) {
      fontAsset.font(font);
      font.dispose();
    }
  }

  Future<void> loadAudio(
      rive.AudioAsset audioAsset, rive.Factory riveFactory) async {
    final bytes = await loadAsset(audioAsset);
    if (bytes == null) {
      return;
    }
    final audioSource =
        await riveFactory.decodeAudio(Uint8List.view(bytes.buffer));
    if (audioSource != null) {
      audioAsset.audio(audioSource);
      audioSource.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RivePlayer(
      asset: "assets/out_of_band.riv",
      artboardName: "Artboard",
      stateMachineName: "State Machine 1",
      assetLoader: (rive.FileAsset asset, Uint8List? bytes) {
        print("asset ID: ${asset.assetId}");
        print("asset Name: ${asset.name}");
        print("asset FileExtension: ${asset.fileExtension} ");
        print("asset cdnBaseUrl: ${asset.cdnBaseUrl}");
        print("asset cdnUuid: ${asset.cdnUuid}");
        print("asset runtime-type: ${asset.runtimeType}");

        if (bytes != null && bytes.isNotEmpty) {
          print("asset bytes length: ${bytes.length}");
          return false; // Asset is embedded in the .riv file, let Rive load it
        }

        switch (asset) {
          case rive.ImageAsset imageAsset:
            loadImage(imageAsset, RiveExampleApp.getCurrentFactory);
          case rive.FontAsset fontAsset:
            loadFont(fontAsset, RiveExampleApp.getCurrentFactory);
          case rive.AudioAsset audioAsset:
            loadAudio(audioAsset, RiveExampleApp.getCurrentFactory);
          case rive.UnknownAsset asset:
            print("Unknown asset, asset name: ${asset.name}");
        }

        return true; // Tell Rive not to load the asset, we will handle it.
      },
    );
  }
}

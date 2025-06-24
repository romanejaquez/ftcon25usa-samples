import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rive_native/rive_native.dart' as rive;
import 'package:rive_native/src/ffi/dynamic_library_helper.dart';

final DynamicLibrary nativeLib = DynamicLibraryHelper.nativeLib;

final int Function() _debugFileCount = nativeLib
    .lookup<NativeFunction<Uint32 Function()>>('debugFileCount')
    .asFunction();

void main() {
  test('out of band asset count test', () async {
    expect(_debugFileCount(), 0);
    final file = File('test/assets/out_of_band.riv');
    final bytes = await file.readAsBytes();

    var totalAssetCount = 0;
    var hostedAssetCount = 0;
    var embededAssetCount = 0;
    var referencedAssetCount = 0;
    var imageAssetCount = 0;
    var fontAssetCount = 0;
    var audioAssetCount = 0;
    var unknownAssetCount = 0;

    final riveFactory = rive.Factory.flutter;

    var riveFile = await rive.File.decode(
      bytes,
      riveFactory: riveFactory,
      assetLoader: (fileAsset, bytes) {
        totalAssetCount++;

        switch (fileAsset) {
          case rive.ImageAsset _:
            imageAssetCount++;
            break;
          case rive.FontAsset _:
            fontAssetCount++;
            break;
          case rive.AudioAsset _:
            audioAssetCount++;
            break;
          case rive.UnknownAsset _:
            unknownAssetCount++;
            break;
          default:
        }
        if (fileAsset.cdnUuid.isNotEmpty) {
          hostedAssetCount++;
        } else if (bytes == null || bytes.isEmpty) {
          referencedAssetCount++;
        } else {
          embededAssetCount++;
        }

        return true;
      },
    );

    expect(_debugFileCount(), 1);

    expect(totalAssetCount, 9, reason: 'Total asset count should be 6');
    expect(hostedAssetCount, 3, reason: 'Hosted asset count should be 3');
    expect(embededAssetCount, 3, reason: 'Embeded asset count should be 3');
    expect(referencedAssetCount, 3,
        reason: 'Referenced asset count should be 3');
    expect(imageAssetCount, 3, reason: 'Image asset count should be 2');
    expect(fontAssetCount, 3, reason: 'Font asset count should be 2');
    expect(audioAssetCount, 3, reason: 'Audio asset count should be 2');
    expect(unknownAssetCount, 0, reason: 'Unknown asset count should be 0');

    riveFile?.dispose();
    expect(_debugFileCount(), 0);
  });

  test('out of band property test', () async {
    expect(_debugFileCount(), 0);
    final file = File('test/assets/out_of_band.riv');
    final bytes = await file.readAsBytes();

    final riveFactory = rive.Factory.flutter;

    List<rive.ImageAsset> imageAssets = [];
    List<rive.FontAsset> fontAssets = [];
    List<rive.AudioAsset> audioAssets = [];

    var riveFile = await rive.File.decode(
      bytes,
      riveFactory: riveFactory,
      assetLoader: (fileAsset, bytes) {
        switch (fileAsset) {
          case rive.ImageAsset imageAsset:
            imageAssets.add(imageAsset);
            break;
          case rive.FontAsset fontAsset:
            fontAssets.add(fontAsset);
            break;
          case rive.AudioAsset audioAsset:
            audioAssets.add(audioAsset);
            break;
          case rive.UnknownAsset _:
            break;
          default:
        }
        return true;
      },
    );

    // asset id
    expect(imageAssets[0].assetId, 2929282);
    expect(imageAssets[1].assetId, 2929283);
    expect(imageAssets[2].assetId, 2989123);
    expect(fontAssets[0].assetId, 594377);
    expect(fontAssets[1].assetId, 593562);
    expect(fontAssets[2].assetId, 593587);
    expect(audioAssets[0].assetId, 2929275);
    expect(audioAssets[1].assetId, 2929340);
    expect(audioAssets[2].assetId, 2989208);
    // name
    expect(imageAssets[0].name, 'referenced-image');
    expect(imageAssets[1].name, 'embedded-image');
    expect(imageAssets[2].name, 'cdn-image');
    expect(fontAssets[0].name, 'Inter');
    expect(fontAssets[1].name, 'Courier Prime');
    expect(fontAssets[2].name, 'Damion');
    expect(audioAssets[0].name, 'embedded_audio');
    expect(audioAssets[1].name, 'referenced_audio');
    expect(audioAssets[2].name, 'hosted_audio');
    // cdnUuid
    expect(imageAssets[0].cdnUuid, '');
    expect(imageAssets[1].cdnUuid, '');
    expect(imageAssets[2].cdnUuid, '2a304786-a9b0-4e86-9a5c-b4e9d268dc69');
    expect(fontAssets[0].cdnUuid, '');
    expect(fontAssets[1].cdnUuid, '');
    expect(fontAssets[2].cdnUuid, '2fa30758-646a-4033-84c4-3128e39bf343');
    expect(audioAssets[0].cdnUuid, '');
    expect(audioAssets[1].cdnUuid, '');
    expect(audioAssets[2].cdnUuid, '7d051978-f0f4-4602-8e91-ac9ea198f14b');
    // fileExtension
    expect(imageAssets[0].fileExtension, 'png');
    expect(imageAssets[1].fileExtension, 'png');
    expect(imageAssets[2].fileExtension, 'png');
    expect(fontAssets[0].fileExtension, 'ttf');
    expect(fontAssets[1].fileExtension, 'ttf');
    expect(fontAssets[2].fileExtension, 'ttf');
    expect(audioAssets[0].fileExtension, 'wav');
    expect(audioAssets[1].fileExtension, 'wav');
    expect(audioAssets[2].fileExtension, 'wav');

    expect(_debugFileCount(), 1);
    riveFile?.dispose();
    expect(_debugFileCount(), 0);
  });

  test('out of band file dispose test', () async {
    expect(_debugFileCount(), 0);
    final riveFactory = rive.Factory.flutter;

    final file = File('test/assets/out_of_band.riv');
    final bytes = await file.readAsBytes();

    // Font
    final fontFile = File('test/assets/fonts/Inter-594377.ttf');
    final fontBytes = await fontFile.readAsBytes();
    final font = await riveFactory.decodeFont(fontBytes);
    expect(font, isNotNull);
    expect(font!.features.length, greaterThan(1));

    // Audio
    final audioFile = File('test/assets/audio/referenced_audio-2929340.wav');
    final audioBytes = await audioFile.readAsBytes();
    final audio = await riveFactory.decodeAudio(audioBytes);
    expect(audio, isNotNull);
    expect(audio!.channels, greaterThan(1));

    // Image
    final imageFile = File('test/assets/images/referenced-image-2929282.png');
    final imageBytes = await imageFile.readAsBytes();
    final image = await riveFactory.decodeImage(imageBytes);
    expect(image, isNotNull);
    expect(image!.width, greaterThan(100));

    late rive.ImageAsset imageAssetRef;
    late rive.FontAsset fontAssetRef;
    late rive.AudioAsset audioAssetRef;

    var riveFile = await rive.File.decode(
      bytes,
      riveFactory: riveFactory,
      assetLoader: (fileAsset, bytes) {
        if (bytes == null || bytes.isEmpty) {
          return false;
        }

        switch (fileAsset) {
          case rive.ImageAsset imageAsset:
            imageAssetRef = imageAsset;
            break;
          case rive.FontAsset fontAsset:
            fontAssetRef = fontAsset;
            break;
          case rive.AudioAsset audioAsset:
            audioAssetRef = audioAsset;
            break;
          default:
            break;
        }
        return true;
      },
    );

    expect(_debugFileCount(), 1);
    expect(imageAssetRef.assetId, 2929283);
    expect(fontAssetRef.assetId, 593562);
    expect(audioAssetRef.assetId, 2929275);
    var resultImage = imageAssetRef.renderImage(image);
    expect(resultImage, true);
    var resultFont = fontAssetRef.font(font);
    expect(resultFont, true);
    var resultAudio = audioAssetRef.audio(audio);
    expect(resultAudio, true);

    // After disposing the file the `assetId` should be 0
    riveFile?.dispose();
    expect(imageAssetRef.assetId, 0);
    expect(fontAssetRef.assetId, 0);
    expect(audioAssetRef.assetId, 0);
    expect(_debugFileCount(), 0);
  });
}

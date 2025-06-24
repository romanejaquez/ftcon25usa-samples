import 'dart:io' as io show Platform;

import 'package:rive_native/platform.dart';

Platform makePlatform() => PlatformNative();

class PlatformNative extends Platform {
  @override
  bool get isTesting => io.Platform.environment.containsKey('FLUTTER_TEST');

  @override
  double now() {
    return DateTime.now().microsecondsSinceEpoch /
        Duration.microsecondsPerSecond;
  }
}

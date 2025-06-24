import 'package:rive_native/platform.dart';
import 'package:web/web.dart';

Platform makePlatform() => PlatformWeb();

class PlatformWeb extends Platform {
  @override
  bool get isTesting => false;

  @override
  double now() {
    return window.performance.now() / 1000;
  }
}

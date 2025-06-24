import 'src/platform_native.dart'
    if (dart.library.js_interop) 'src/platform_web.dart';

abstract class Platform {
  bool get isTesting;
  static final Platform instance = makePlatform();
  // Returns the current timestamp in seconds
  // This may return different values on different platforms but is needed
  // because DateTime.now() is limited by browser security allowing
  // precision to only 1 millisecond.
  double now();
}

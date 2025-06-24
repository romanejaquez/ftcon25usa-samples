import 'package:rive_native/rive_native.dart' as rive;

class RiveExampleApp {
  static bool isRiveRender = true;

  static rive.Factory get getCurrentFactory =>
      isRiveRender ? rive.Factory.rive : rive.Factory.flutter;
}

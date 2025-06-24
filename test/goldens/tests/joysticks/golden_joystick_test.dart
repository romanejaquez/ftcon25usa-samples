import 'package:flutter_test/flutter_test.dart';
import 'package:rive_native/rive_native.dart' as rive;

import '../../src/rive_golden.dart';

void main() {
  group('Golden - Joystick tests', () {
    // See: https://github.com/rive-app/rive/pull/5589
    testWidgets('Joystick handle source', (WidgetTester tester) async {
      final golden = RiveGolden(
        name: 'joystick_handle_source',
        filePath: 'assets/joystick_handle_source.riv',
        artboardName: 'New Artboard',
        stateMachineName: 'State Machine 1',
        widgetTester: tester,
      )
        ..tick()
        ..golden()
        ..pointerMove(rive.Vec2D.fromValues(85, 60))
        ..tick()
        ..golden()
        ..pointerMove(rive.Vec2D.fromValues(370, 65))
        ..tick()
        ..golden()
        ..tick(milliseconds: 500)
        ..golden();

      await golden.run();
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rive_native/rive_native.dart' as rive;

import '../../src/rive_golden.dart';

void main() {
  group('Golden - Text tests', () {
    testWidgets('Text runs update with bone constraints',
        (WidgetTester tester) async {
      final golden = RiveGolden(
        name: 'text_bones_constraint',
        filePath: 'assets/electrified_button_simple.riv',
        stateMachineName: 'button',
        widgetTester: tester,
      )
        ..tick()
        ..golden()
        ..pointerMove(rive.Vec2D.fromValues(250, 250))
        ..tick()
        ..golden(
          reason:
              'Hovering should trigger a different animation for text and button',
        )
        ..setText('name', 'short')
        ..tick()
        ..golden(reason: 'Short text runs should update with bone constraints')
        ..setText('name', 'Extremely long text. The longest.')
        ..tick()
        ..golden(reason: 'Long text runs should update with bone constraints')
        ..tick();

      await golden.run();
    });
  });
}

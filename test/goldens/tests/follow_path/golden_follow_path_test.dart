import 'package:flutter_test/flutter_test.dart';

import '../../src/rive_golden.dart';

void main() {
  group('Golden - follow path tests', () {
    testWidgets('Follow path - shape over time', (WidgetTester tester) async {
      final golden = RiveGolden(
        name: 'follow_path_over_time',
        filePath: 'assets/follow_path_shapes.riv',
        stateMachineName: 'State Machine 1',
        widgetTester: tester,
      )
        ..tick()
        ..golden()
        ..tick(milliseconds: 100)
        ..golden()
        ..tick(milliseconds: 100)
        ..golden()
        ..tick(milliseconds: 100)
        ..golden();
      await golden.run();
    });
  });

  testWidgets('Follow path - path over time', (WidgetTester tester) async {
    final golden = RiveGolden(
      name: 'follow_path_path',
      filePath: 'assets/follow_path_path.riv',
      stateMachineName: 'State Machine 1',
      widgetTester: tester,
    )
      ..tick()
      ..golden()
      ..tick(milliseconds: 500)
      ..golden()
      ..tick(seconds: 2, milliseconds: 500)
      ..golden();
    await golden.run();
  });
}

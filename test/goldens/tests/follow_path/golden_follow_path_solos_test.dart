import 'package:flutter_test/flutter_test.dart';

import '../../src/rive_golden.dart';

void main() {
  group('Golden - follow path solo tests', () {
    testWidgets('Follow path over time', (WidgetTester tester) async {
      final golden = RiveGolden(
        name: 'follow_path_solos',
        filePath: 'assets/follow_path_solos.riv',
        stateMachineName: 'State Machine 1',
        widgetTester: tester,
      )
        ..tick()
        ..golden()
        ..tick(seconds: 1)
        ..golden()
        ..tick(milliseconds: 1500)
        ..golden()
        ..tick(seconds: 1)
        ..golden();
      await golden.run();
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import '../../src/rive_golden.dart';

void main() {
  group('Golden - opacity skin', () {
    testWidgets('Swapping skins based on opacity', (WidgetTester tester) async {
      final golden = RiveGolden(
        name: 'skins_opacity',
        filePath: 'assets/skins_demo.riv',
        stateMachineName: 'Motion',
        widgetTester: tester,
      )
        ..tick(milliseconds: 500)
        ..golden()
        ..triggerInput('Skin')
        ..tick(milliseconds: 500)
        ..golden()
        ..triggerInput('Skin')
        ..tick(milliseconds: 500)
        ..golden()
        ..triggerInput('Skin')
        ..tick(milliseconds: 500)
        ..golden()
        ..triggerInput('Skin')
        ..tick(milliseconds: 500)
        ..golden();

      await golden.run();
    });
  });
}

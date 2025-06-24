import 'package:flutter_test/flutter_test.dart';

import '../../src/rive_golden.dart';

void main() {
  group('Golden - spilled time test', () {
    testWidgets('Test with Spilled time', (WidgetTester tester) async {
      final golden = RiveGolden(
        name: 'spilled_time',
        filePath: 'assets/spilled_time.riv',
        stateMachineName: 'State Machine 1',
        widgetTester: tester,
      )
        // first fire after fire just changes the state, this time gets lost
        // i suspect the "entry state" eats this time
        ..triggerInput('Trigger 1')
        ..tick(milliseconds: 500)
        ..golden(
          reason: 'one shot & loop lines line up at left hand side',
        )
        ..tick(milliseconds: 250)
        ..golden(
          reason: 'one shot & loop lines line up 25% across',
        )
        ..tick(milliseconds: 1250)
        ..golden(
          reason: 'one shot is finished at 100%, loop looped back to 50%',
        )
        // we advance an extra time before trigger
        ..tick(milliseconds: 100)
        ..golden(
          reason: 'one shot stays at 100%, loop advanced to 60%',
        )
        // once again advance after fire, the whole time gets lost
        // TODO: without the spilled time fix, the one shot animation
        // does advance, the loop does not. the fix might be the wrong
        // way around
        ..triggerInput('Trigger 1')
        ..tick(milliseconds: 300)
        ..golden(
          reason: 'one shot & loop lines line up at left hand side',
        )
        ..tick(milliseconds: 100)
        ..golden(
          reason: 'top and bottom lines line up 10% across width',
        );

      await golden.run();
    });

    testWidgets('Test with Spilled time overshoot',
        (WidgetTester tester) async {
      final golden = RiveGolden(
        name: 'spilled_time_overshoot',
        filePath: 'assets/spilled_time.riv',
        stateMachineName: 'State Machine 1',
        widgetTester: tester,
      )
        ..triggerInput('Trigger 1')
        ..tick()
        ..golden(
          reason: 'one shot & loop lines line up at left hand side',
        )
        ..tick(milliseconds: 1500)
        ..golden(
          reason: 'one shot gets stuck at 100% & loop advances to 50%',
        )
        ..triggerInput('Trigger 1')
        ..tick(milliseconds: 250)
        ..golden(
          reason: 'one shot & loop reset to 0%',
        );

      await golden.run();
    });

    testWidgets('Test with Spilled time exact', (WidgetTester tester) async {
      final golden = RiveGolden(
        name: 'spilled_time_exact',
        filePath: 'assets/spilled_time.riv',
        stateMachineName: 'State Machine 1',
        widgetTester: tester,
      )
        ..triggerInput('Trigger 1')
        ..tick()
        ..golden(
          reason: 'one shot & loop lines line up at left hand side',
        )
        ..tick(seconds: 1)
        ..golden(
          reason: 'one shot & loop get to 100%',
        )
        ..triggerInput('Trigger 1')
        ..tick(milliseconds: 250)
        ..golden(
          reason: 'one shot resets to 0% & loop reset to 0%',
        );

      await golden.run();
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../src/rive_golden.dart';

void main() {
  group('Golden - ticker mode tests', () {
    testWidgets('ticker mode initially false pauses animation',
        (WidgetTester tester) async {
      // TODO (Gordon): This test is failing

      // final golden = RiveGolden(
      //   name: 'ticker_mode_false',
      //   filePath: 'assets/off_road_car.riv',
      //   artboardName: 'New Artboard',
      //   stateMachineName: 'State Machine 1',
      //   widgetTester: tester,
      //   widgetWrapper: (child) => TickerMode(
      //     enabled: false,
      //     child: child,
      //   ),
      // )
      //   ..tick()
      //   ..golden(
      //     fileName: 'ticker_mode_false',
      //     reason: 'Animation frame should be paused with ticker mode false',
      //   )
      //   ..pumpFrames(milliseconds: 1500)
      //   ..golden(
      //     fileName: 'ticker_mode_false',
      //     reason: 'Animation should not have advanced with ticker mode false',
      //   );

      // await golden.run();
    });

    testWidgets('ticker mode initially true plays animation',
        (WidgetTester tester) async {
      final golden = RiveGolden(
        name: 'ticker_mode_true',
        filePath: 'assets/off_road_car.riv',
        artboardName: 'New Artboard',
        stateMachineName: 'State Machine 1',
        widgetTester: tester,
        widgetWrapper: (child) => TickerMode(
          enabled: true,
          child: child,
        ),
      )
        ..tickFrames(const Duration(
            milliseconds: 100 - 32)) // TODO (Gordon): Why 100 - 32?
        ..golden(
          reason: 'Animation frame should play with ticker mode true',
        )
        ..tickFrames(const Duration(milliseconds: 1500))
        ..golden(
          reason: 'Animation should advance with ticker mode true',
        );

      await golden.run();
    });

    testWidgets('ticker mode variable state', (WidgetTester tester) async {
      final key = GlobalKey<_VariableTickerModeState>();
      late Widget widget;

      final golden = RiveGolden(
        name: 'ticker_mode_variable_state',
        filePath: 'assets/off_road_car.riv',
        artboardName: 'New Artboard',
        stateMachineName: 'State Machine 1',
        widgetTester: tester,
        widgetWrapper: (child) {
          widget = _VariableTickerMode(
            stateKey: key,
            child: child,
          );
          return widget;
        },
      )
        ..tickFrames(const Duration(
            milliseconds: 100 - 32)) // TODO (Gordon): Why 100 - 32?
        ..golden(
          fileName: 'ticker_mode_true_01',
          reason: 'Animation frame should play with ticker mode true',
        )
        ..customAction((stateMachine) {
          key.currentState!.disableTickerMode();
        })
        ..tickFrames(const Duration(milliseconds: 1500))
        ..golden(
          fileName: 'ticker_mode_true_paused_state',
          reason: 'Animation should not have advanced with ticker mode false',
        )
        ..tick();

      await golden.run();
    });
  });
}

class _VariableTickerMode extends StatefulWidget {
  const _VariableTickerMode({
    required this.child,
    required this.stateKey,
  }) : super(key: stateKey);

  final Widget child;
  final GlobalKey<_VariableTickerModeState> stateKey;

  @override
  State<_VariableTickerMode> createState() => _VariableTickerModeState();
}

class _VariableTickerModeState extends State<_VariableTickerMode> {
  bool ticker = true;

  void disableTickerMode() {
    setState(() {
      ticker = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: ticker,
      child: widget.child,
    );
  }
}

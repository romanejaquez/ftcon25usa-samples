import 'package:flutter_test/flutter_test.dart';

import '../../src/rive_golden.dart';

void main() {
  group('Golden - Nested inputs tests', () {
    testWidgets('Can set nested inputs', (WidgetTester tester) async {
      const baseComparisonFileName = 'nested_inputs_original';
      final golden = RiveGolden(
        name: 'nested_inputs',
        filePath: 'assets/runtime_nested_inputs.riv',
        artboardName: 'MainArtboard',
        stateMachineName: 'MainStateMachine',
        widgetTester: tester,
      )
        ..tick()
        ..golden(fileName: baseComparisonFileName)
        ..setBooleanInput('CircleOuterState', true, path: 'CircleOuter')
        ..tick()
        ..golden()
        ..setBooleanInput(
          'CircleInnerState',
          true,
          path: 'CircleOuter/CircleInner',
        )
        ..tick()
        ..golden()
        ..setBooleanInput('CircleOuterState', false, path: 'CircleOuter')
        ..tick()
        ..golden()
        ..setBooleanInput(
          'CircleInnerState',
          false,
          path: 'CircleOuter/CircleInner',
        )
        ..tick()
        ..golden(
          fileName: baseComparisonFileName,
          reason: 'should match original',
        )
        ..tick();

      await golden.run();
    });
  });
}

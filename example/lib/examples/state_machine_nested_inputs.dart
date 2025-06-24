import 'package:rive_native/rive_native.dart' as rive;

import '../rive_player.dart';
import 'package:flutter/material.dart';

class StateMachineNestedInputsExample extends StatefulWidget {
  const StateMachineNestedInputsExample({super.key});

  @override
  State<StateMachineNestedInputsExample> createState() =>
      _StateMachineInputsExampleState();
}

class _StateMachineInputsExampleState
    extends State<StateMachineNestedInputsExample> {
  late rive.StateMachine stateMachine;
  bool innerOn = false;
  bool outerOn = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RivePlayer(
            asset: 'assets/runtime_nested_inputs.riv',
            artboardName: 'MainArtboard',
            stateMachineName: 'MainStateMachine',
            withStateMachine: (sm) {
              stateMachine = sm;
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Inner circle on/off:'),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Checkbox(
                value: innerOn,
                onChanged: (value) {
                  setState(() {
                    innerOn = value!;
                  });
                  stateMachine
                      .boolean(
                        'CircleOuterState',
                        path: 'CircleOuter',
                      )!
                      .value = innerOn;
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Outer circle on/off:'),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Checkbox(
                value: outerOn,
                onChanged: (value) {
                  setState(() {
                    outerOn = value!;
                  });
                  stateMachine
                      .boolean(
                        'CircleInnerState',
                        path: 'CircleOuter/CircleInner',
                      )!
                      .value = outerOn;
                },
              ),
            ),
          ],
        )
      ],
    );
  }
}

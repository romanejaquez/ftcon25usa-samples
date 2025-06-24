import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../rive_player.dart';

class ExampleTimeDilation extends StatefulWidget {
  const ExampleTimeDilation({super.key});

  @override
  State<ExampleTimeDilation> createState() => _ExampleTimeDilationState();
}

class _ExampleTimeDilationState extends State<ExampleTimeDilation> {
  @override
  void dispose() {
    timeDilation = 1;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    timeDilation = 5;
    return const RivePlayer(
      asset: "assets/little_machine.riv",
      stateMachineName: "State Machine 1",
    );
  }
}

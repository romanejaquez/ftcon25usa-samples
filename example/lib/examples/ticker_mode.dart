import 'package:flutter/material.dart';

import '../rive_player.dart';

class ExampleTickerMode extends StatefulWidget {
  const ExampleTickerMode({super.key});

  @override
  State<ExampleTickerMode> createState() => _ExampleTickerModeState();
}

class _ExampleTickerModeState extends State<ExampleTickerMode> {
  var tickerMode = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: TickerMode(
            enabled: tickerMode,
            child: const RivePlayer(
              asset: "assets/little_machine.riv",
              stateMachineName: "State Machine 1",
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: tickerMode ? Text("Ticker mode enabled") : Text("Ticker mode disabled")
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              tickerMode = !tickerMode;
            });
          },
          child: const Text("Toggle ticker mode"),
        )
      ],
    );
  }
}

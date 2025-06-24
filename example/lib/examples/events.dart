// ignore_for_file: avoid_print

import 'package:rive_native/rive_native.dart';

import '../rive_player.dart';
import 'package:flutter/material.dart';

class ExampleEvents extends StatefulWidget {
  const ExampleEvents({super.key});

  @override
  State<ExampleEvents> createState() => _ExampleEventsState();
}

class _ExampleEventsState extends State<ExampleEvents> {
  late StateMachine stateMachine;
  double ratingValue = 0;

  void eventListener(Event event) {
    print('\n$event\n');

    switch (event) {
      case GeneralEvent():
        setState(() {
          ratingValue = event.numberProperty('rating')?.value ?? 0;
        });
      case OpenUrlEvent():
        // Add your custom logic to open a URL here
        print(
            '\nURL to open: "${event.url}", with target: "${event.target}"\n');
    }
  }

  @override
  void dispose() {
    stateMachine.removeEventListener(eventListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text('Rating: $ratingValue', style: TextStyle(fontSize: 24)),
        ),
        Expanded(
          child: RivePlayer(
            asset: 'assets/rating.riv',
            stateMachineName: 'State Machine 1',
            withStateMachine: (sm) {
              stateMachine = sm;
              stateMachine.addEventListener(eventListener);
            },
          ),
        ),
      ],
    );
  }
}

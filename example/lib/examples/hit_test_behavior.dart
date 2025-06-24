import 'package:flutter/material.dart';
import 'package:rive_native/rive_native.dart' as rive;

import '../rive_player.dart';

class ExampleHitTestBehaviour extends StatefulWidget {
  const ExampleHitTestBehaviour({super.key});

  @override
  State<ExampleHitTestBehaviour> createState() =>
      _ExampleHitTestBehaviourState();
}

class _ExampleHitTestBehaviourState extends State<ExampleHitTestBehaviour> {
  int count = 0;
  rive.RiveHitTestBehavior hitTestBehavior = rive.RiveHitTestBehavior.opaque;
  MouseCursor cursor = MouseCursor.defer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.copy,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        count++;
                      });
                    },
                    child: Container(
                      width: 300,
                      height: 300,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
              Center(
                child: MouseRegion(
                  opaque: true,
                  cursor: SystemMouseCursors.click,
                  hitTestBehavior: HitTestBehavior.deferToChild,
                  child: RivePlayer(
                    asset: "assets/button.riv",
                    stateMachineName: "State Machine 1",
                    hitTestBehavior: hitTestBehavior,
                    cursor: cursor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text("Underlying Flutter container tapped: $count"),
        const SizedBox(
          height: 16,
        ),
        Text("Current hit test behaviour: $hitTestBehavior"),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    hitTestBehavior = rive.RiveHitTestBehavior.none;
                  });
                },
                child: const Text("none"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    hitTestBehavior = rive.RiveHitTestBehavior.opaque;
                  });
                },
                child: const Text("opaque"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    hitTestBehavior = rive.RiveHitTestBehavior.translucent;
                  });
                },
                child: const Text("translucent"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    hitTestBehavior = rive.RiveHitTestBehavior.transparent;
                  });
                },
                child: const Text("transparent"),
              )
            ],
          ),
        ),
        Text("Current mouse cursor: $cursor"),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    cursor = MouseCursor.defer;
                  });
                },
                child: const Text("defer"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    cursor = MouseCursor.uncontrolled;
                  });
                },
                child: const Text("unconrolled"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    cursor = SystemMouseCursors.contextMenu;
                  });
                },
                child: const Text("context menu"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    cursor = SystemMouseCursors.text;
                  });
                },
                child: const Text("text"),
              ),
            ],
          ),
        )
      ],
    );
  }
}

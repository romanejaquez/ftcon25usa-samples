import 'package:example/rive_player.dart';
import 'package:flutter/material.dart';
import 'package:rive_native/rive_native.dart' as rive;

class RiveMascot extends StatefulWidget {
  const RiveMascot({super.key});

  @override
  State<RiveMascot> createState() => _RiveMascotState();
}

class _RiveMascotState extends State<RiveMascot> {

  late rive.StateMachine sm;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      sm.trigger('jump')!.fire();
                    });
                  },
                  child: SizedBox(
                    height: 600,
                    width: 400,
                    child: RivePlayer(
                    asset: "assets/rivemascot.riv",
                    artboardName: "mascot",
                    stateMachineName: "mascot",
                    fit: rive.Fit.contain,
                    autoBind: true,
                    withStateMachine: (stateMachine) {
                      sm = stateMachine;
                    }),
                  ),
                ),
            
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          sm.boolean('fun')!.value = true;
                          sm.boolean('cap')!.value = false;
                          sm.boolean('bday')!.value = false;
                        });
                      },
                      child: SizedBox(
                        width: 80, height: 80,
                        child: RivePlayer(
                          asset: "assets/rivemascot.riv",
                          artboardName: "funhat",
                          stateMachineName: "funhat",
                          fit: rive.Fit.contain,
                        ),
                      ),
                    ),
            
                    GestureDetector(
                      onTap: () {
                        sm.boolean('fun')!.value = false;
                        sm.boolean('cap')!.value = false;
                        sm.boolean('bday')!.value = true;
                      },
                      child: SizedBox(
                        width: 80, height: 80,
                        child: RivePlayer(
                          asset: "assets/rivemascot.riv",
                          artboardName: "bdayhat",
                          stateMachineName: "bdayhat",
                          fit: rive.Fit.contain,
                        ),
                      ),
                    ),
            
                    GestureDetector(
                      onTap: () {
                        sm.boolean('fun')!.value = false;
                        sm.boolean('cap')!.value = true;
                        sm.boolean('bday')!.value = false;
                      },
                      child: SizedBox(
                        width: 80, height: 80,
                        child: RivePlayer(
                          asset: "assets/rivemascot.riv",
                          artboardName: "caphat",
                          stateMachineName: "caphat",
                          fit: rive.Fit.contain,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            
              
            ),
          ),
        ),
      ),
    );
  }
}
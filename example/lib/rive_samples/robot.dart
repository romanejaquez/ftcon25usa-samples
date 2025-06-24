import 'package:example/rive_player.dart';
import 'package:flutter/material.dart';
import 'package:rive_native/rive_native.dart' as rive;

class Robot extends StatefulWidget {
  const Robot({super.key});

  @override
  State<Robot> createState() => _RobotState();
}

class _RobotState extends State<Robot> {

  late rive.ViewModelInstance instance;
  late rive.ViewModelInstanceColor mainColor;
  late rive.ViewModelInstanceColor secondaryColor;
  late rive.ViewModelInstanceString name;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RivePlayer(
                  asset: 'assets/c3p0.riv',
                  artboardName: 'robot',
                  stateMachineName: 'robot',
                  withViewModelInstance: (viewModelInstance) {
                    instance = viewModelInstance;

                    mainColor = instance.color('mainColor')!;
                    secondaryColor = instance.color('secondaryColor')!;
                    name = instance.string('name')!;
                  },
                )
              ),

              TextButton(
                onPressed: () {
                  name.value = 'C3P0';
                  mainColor.value = Colors.amber;
                  secondaryColor.value = Colors.black;
                },
                child: Text('C3P0'),
              ),

              TextButton(
                onPressed: () {
                  name.value = 'R2D2';
                  mainColor.value = const Color.fromARGB(255, 168, 216, 255);
                  secondaryColor.value = Colors.blue;
                },
                child: Text('R2D2'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

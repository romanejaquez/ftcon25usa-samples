import '../rive_player.dart';
import 'package:flutter/material.dart';
import 'package:rive_native/rive_native.dart' as rive;

class HunterXDemo extends StatefulWidget {
  const HunterXDemo({super.key});

  @override
  State<HunterXDemo> createState() => _HunterXDemoState();
}

class _HunterXDemoState extends State<HunterXDemo> {
  @override
  Widget build(BuildContext context) {
    return RivePlayer(
      asset: "assets/hunter_x_v2.riv",
      artboardName: "Main Menu",
      fit: rive.Fit.layout,
      layoutScaleFactor: 1 / 3.0,
      stateMachineName: "State Machine 1",
      autoBind: true,
    );
  }
}

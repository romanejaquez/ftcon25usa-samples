import 'package:example/rive_player.dart';
import 'package:flutter/material.dart';

class CustomIsland extends StatelessWidget {
  const CustomIsland({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          margin: EdgeInsets.only(top: 10),
          child: RivePlayer(asset: './assets/uitoolkit-layouts.riv',
            stateMachineName: 'island',
            artboardName: 'island',
          ),
        ),
      ),
    );
  }
}
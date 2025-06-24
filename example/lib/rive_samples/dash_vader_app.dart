
import 'package:example/rive_player.dart';
import 'package:flutter/material.dart';
import 'package:rive_native/rive_native.dart' as rive;

class DashVader extends StatelessWidget {
  const DashVader({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DashVaderImage()
    );
  }
}

class DashVaderImage extends StatefulWidget {
  const DashVaderImage({super.key});

  @override
  State<DashVaderImage> createState() => _DashVaderImageState();
}

class _DashVaderImageState extends State<DashVaderImage> {

  bool isDashVader = true;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: GestureDetector(
          onTap: () {
            setState(() {
              isDashVader = !isDashVader;
            });
          },
          child: Center(
            child: Stack(
              children: [
                Visibility(
                  key: ValueKey(isDashVader),
                  visible: isDashVader,
                  replacement: RivePlayer(
                    asset: './assets/dashvader.riv',
                    stateMachineName: 'lasereyes',
                    artboardName: 'dashvader',
                    fit: rive.Fit.fitHeight,
                  ),
                  child: RivePlayer(
                    asset: './assets/dashvader.riv',
                    stateMachineName: 'dashvader',
                    artboardName: 'dashvader',
                    fit: rive.Fit.fitHeight,
                  ),
                  
                ),
              ]
            ),
          ),
        )
      );
  }
}
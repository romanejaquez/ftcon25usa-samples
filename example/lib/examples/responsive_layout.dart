import 'package:flutter/material.dart';
import 'package:rive_native/rive_native.dart' as rive;

import '../rive_player.dart';

class ExampleResponsiveLayout extends StatelessWidget {
  const ExampleResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const RivePlayer(
      asset: "assets/layout_test.riv",
      stateMachineName: "State Machine 1",
      fit: rive.Fit.layout,
      // layoutScaleFactor: 2, // 2x the scale of the artboard
    );
  }
}

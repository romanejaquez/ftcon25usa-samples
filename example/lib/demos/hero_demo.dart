import 'package:flutter/services.dart';

import '../rive_player.dart';
import 'package:flutter/material.dart';
import 'package:rive_native/rive_native.dart' as rive;

class HeroDemo extends StatefulWidget {
  const HeroDemo({super.key});

  @override
  State<HeroDemo> createState() => _HeroDemoState();
}

class _HeroDemoState extends State<HeroDemo> {
  final FocusNode _focusNode = FocusNode();
  rive.ViewModelInstanceNumber? volume;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  void onVolumeChanged(double value) {
    print('volume changed to $value');
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        print('up');

        volume?.value += 1;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        print('down');
        volume?.value -= 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: RivePlayer(
        asset: "assets/hero.riv",
        artboardName: "Main menu",
        fit: rive.Fit.layout,
        layoutScaleFactor: 1 / 2.0,
        stateMachineName: "State Machine 1",
        autoBind: true,
        withViewModelInstance: (viewModelInstance) {
          // access by view model path
          // final volume = viewModelInstance
          //     .viewModel('Navigation')
          //     ?.viewModel('Options')
          //     ?.viewModel('SubButton-Options')
          //     ?.viewModel('Music')
          //     ?.number('Slider');

          // access by string path
          volume = viewModelInstance
              .number('Navigation/Options/SubButton-Options/Music/Slider');

          volume?.addListener(onVolumeChanged);

          volume?.value = 100;

          // volume?.removeListener(onVolumeChanged);
          // volume?.clearListeners();

          // viewModelInstance.dispose();
        },
      ),
    );
  }
}

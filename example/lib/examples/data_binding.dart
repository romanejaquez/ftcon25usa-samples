import 'dart:math';

import 'package:example/rive_player.dart';
import 'package:flutter/material.dart';
import 'package:rive_native/rive_native.dart' as rive;

class ExampleDataBinding extends StatefulWidget {
  const ExampleDataBinding({super.key});

  @override
  State<ExampleDataBinding> createState() => _ExampleBasicState();
}

class _ExampleBasicState extends State<ExampleDataBinding> {
  late rive.ViewModelInstance viewModelInstance;
  late rive.ViewModelInstance coinItemVM;
  late rive.ViewModelInstance gemItemVM;
  late rive.ViewModelInstanceNumber coinValue;
  late rive.ViewModelInstanceNumber gemValue;

  void _selectRandomToken() {
    final random = Random.secure().nextBool() ? 'Coin' : 'Gem';
    // We randomly select to reward either coins or gems
    viewModelInstance
        .viewModel('Item_Selection')!
        .enumerator('Item_Selection')!
        .value = random;
  }

  void _onCoinValueChange(double value) {
    print('New coin value: $value');
  }

  void _onGemValueChange(double value) {
    print('New gem value: $value');
  }

  @override
  void dispose() {
    coinValue.removeListener(_onCoinValueChange);
    gemValue.removeListener(_onGemValueChange);
    coinValue.dispose();
    gemValue.dispose();
    coinItemVM.dispose();
    gemItemVM.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RivePlayer(
      asset: "assets/rewards.riv",
      autoBind: true,
      fit: rive.Fit.layout, // for responsive layouts
      layoutScaleFactor: 1 / 2.0,
      withViewModelInstance: (viewModelInstance) {
        this.viewModelInstance = viewModelInstance;
        _selectRandomToken();

        // Print the view model instance properties
        print(viewModelInstance.properties);
        // Get the rewards view model
        coinItemVM = viewModelInstance.viewModel("Coin")!;
        gemItemVM = viewModelInstance.viewModel("Gem")!;
        print(coinItemVM); // Print the view model instance properties

        coinValue = coinItemVM.number("Item_Value")!;
        gemValue = gemItemVM.number("Item_Value")!;
        // Listen to the changes on the Item_Value input
        coinValue.addListener(_onCoinValueChange);
        coinValue.value = 1000; // set the initial coin value to 1000

        gemValue.addListener(_onGemValueChange);
        gemValue.value = 4000; // set the initial gem value to 4000
      },
    );
  }
}

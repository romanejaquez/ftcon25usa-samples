import 'dart:async';

import 'package:example/rive_player.dart';
import 'package:example/rive_samples/custom_island.dart';
import 'package:example/rive_samples/dash_vader_app.dart';
import 'package:example/rive_samples/flutterconusa_app.dart';
import 'package:example/rive_samples/rive_mascot_app.dart';
import 'package:example/rive_samples/robot.dart';
import 'package:example/rive_samples/theme_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';
import 'package:rive_native/rive_native.dart' as rive;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await rive.RiveNative.init();
  
  // mascot
  // runApp(const RiveMascot());

  // vector feathering
  // runApp(const DashVader());

  // vector feathering 2
  // runApp(const CustomIsland());

  // data binding
  runApp(const ProviderScope(child: MyThemedApp()));

  // flutterconusa
  //runApp(const FlutterConUSAApp());

  // data binding
  //runApp(const Robot());
}


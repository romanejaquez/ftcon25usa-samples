import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_native/rive_native.dart' as rive;

import '../app.dart';

class ExampleArtboardDoesNotExists extends StatefulWidget {
  const ExampleArtboardDoesNotExists({super.key});

  @override
  State<ExampleArtboardDoesNotExists> createState() =>
      _ExampleArtboardDoesNotExistsState();
}

class _ExampleArtboardDoesNotExistsState
    extends State<ExampleArtboardDoesNotExists> {
  @override
  void initState() {
    loadFile();
    super.initState();
  }

  rive.File? riveFile;

  Future<void> loadFile() async {
    final bytes = await rootBundle.load("assets/rating.riv");
    riveFile = await rive.File.decode(
      bytes.buffer.asUint8List(),
      riveFactory: RiveExampleApp.isRiveRender
          ? rive.Factory.rive
          : rive.Factory.flutter,
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (riveFile == null) return const SizedBox();
    return rive.RiveFileWidget(
      file: riveFile!,
      painter: rive.StateMachinePainter(),
      artboardName: 'wrong-name',
    );
  }
}

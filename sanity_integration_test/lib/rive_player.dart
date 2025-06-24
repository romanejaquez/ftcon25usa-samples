import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_native/rive_native.dart' as rive;

bool isRiveRender = false;

/// This is an example high-level implementation widget using the Rive Native Painters.
class RivePlayer extends StatefulWidget {
  const RivePlayer({
    super.key,
    required this.asset,
    required this.stateMachineName,
    this.artboardName,
    this.hitTestBehavior = rive.RiveHitTestBehavior.opaque,
    this.cursor = MouseCursor.defer,
    this.fit = rive.Fit.contain,
    this.alignment = Alignment.center,
    this.layoutScaleFactor = 1.0,
    this.withStateMachine,
  });
  final String asset;
  final String? stateMachineName;
  final String? artboardName;
  final rive.RiveHitTestBehavior hitTestBehavior;
  final MouseCursor cursor;
  final rive.Fit fit;
  final Alignment alignment;
  final double layoutScaleFactor;

  final void Function(rive.StateMachine)? withStateMachine;

  @override
  State<RivePlayer> createState() => _RivePlayerState();
}

class _RivePlayerState extends State<RivePlayer> {
  rive.File? riveFile;

  late rive.Artboard artboard;
  late rive.StateMachinePainter stateMachinePainter;

  @override
  void initState() {
    super.initState();

    init();
  }

  Future<rive.File?> _loadFile() async {
    final bytes = await rootBundle.load(widget.asset);
    return rive.File.decode(bytes.buffer.asUint8List(),
        riveFactory: isRiveRender ? rive.Factory.rive : rive.Factory.flutter);
  }

  Future<void> init() async {
    riveFile = await _loadFile();

    if (widget.artboardName != null) {
      artboard = riveFile!.artboard(widget.artboardName!)!;
    } else {
      artboard = riveFile!.artboardAt(0)!;
    }

    stateMachinePainter = rive.RivePainter.stateMachine(
      stateMachineName: widget.stateMachineName,
      withStateMachine: widget.withStateMachine,
    )
      ..hitTestBehavior = widget.hitTestBehavior
      ..cursor = widget.cursor
      ..fit = widget.fit
      ..alignment = widget.alignment
      ..layoutScaleFactor = widget.layoutScaleFactor;

    setState(() {});
  }

  @override
  void didUpdateWidget(covariant RivePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hitTestBehavior != oldWidget.hitTestBehavior) {
      stateMachinePainter.hitTestBehavior = widget.hitTestBehavior;
    }
    if (widget.cursor != oldWidget.cursor) {
      stateMachinePainter.cursor = widget.cursor;
    }
    if (widget.fit != oldWidget.fit) {
      stateMachinePainter.fit = widget.fit;
    }
    if (widget.alignment != oldWidget.alignment) {
      stateMachinePainter.alignment = widget.alignment;
    }
    if (widget.layoutScaleFactor != oldWidget.layoutScaleFactor) {
      stateMachinePainter.layoutScaleFactor = widget.layoutScaleFactor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return riveFile != null
        ? rive.RiveArtboardWidget(
            artboard: artboard,
            painter: stateMachinePainter,
          )
        : const SizedBox();
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:rive_native/rive_native.dart' as rive;

abstract base class ProceduralPainter extends rive.RivePainter {
  /// Called each frame to advance the animation.
  @protected
  bool advance(double elapsedSeconds);

  /// Called each frame to paint the artboard.
  @protected
  void paint(rive.Renderer renderer, Size size, double paintPixelRatio);
}

abstract base class ArtboardPainter extends ProceduralPainter {
  /// Called when the underlying artboard changes.
  @protected
  void artboardChanged(rive.Artboard artboard);
}

base class BasicArtboardPainter extends ArtboardPainter {
  BasicArtboardPainter({
    rive.Fit fit = rive.RiveDefaults.fit,
    Alignment alignment = rive.RiveDefaults.alignment,
  })  : _fit = fit,
        _alignment = alignment;

  rive.Fit get fit => _fit;
  rive.Fit _fit;
  set fit(rive.Fit value) {
    if (_fit == value) return;

    if (value == rive.Fit.layout) {
      _requireResize = true;
    } else if (_fit == rive.Fit.layout) {
      // Previous fit was Layout, we need to reset the artboard size to default
      artboard?.resetArtboardSize();
    }

    _fit = value;
    notifyListeners();
  }

  Alignment get alignment => _alignment;
  Alignment _alignment;
  set alignment(Alignment value) {
    if (_alignment == value) return;

    _alignment = value;
    notifyListeners();
  }

  /// The scale factor to use for a fit of type `Fit.layout`.
  double get layoutScaleFactor => _layoutScaleFactor;
  double _layoutScaleFactor = rive.RiveDefaults.layoutScaleFactor;
  set layoutScaleFactor(double value) {
    if (_layoutScaleFactor == value) return;
    _layoutScaleFactor = value;

    if (fit == rive.Fit.layout) {
      _requireResize = true;
    }

    notifyListeners();
  }

  double get _layoutScaleFactorToUse =>
      layoutScaleFactor * _lastPaintPixelRatio;

  rive.Artboard? _artboard;
  rive.Artboard? get artboard => _artboard;

  @mustCallSuper
  @override
  void artboardChanged(rive.Artboard artboard) {
    _artboard = artboard;
  }

  @override
  bool advance(double elapsedSeconds) =>
      _artboard?.advance(elapsedSeconds) ?? false;

  /// The last size of the paint area.
  Size get lastSize => _lastSize;
  Size _lastSize = Size.zero;

  double get lastPaintPixelRatio => _lastPaintPixelRatio;
  double _lastPaintPixelRatio = 1.0;

  bool _requireResize = false;

  @mustCallSuper
  @override
  void paint(rive.Renderer renderer, Size size, double paintPixelRatio) {
    _requireResize = _requireResize ||
        (fit == rive.Fit.layout &&
            (_lastSize != size || _lastPaintPixelRatio != paintPixelRatio));

    _lastSize = size;
    _lastPaintPixelRatio = paintPixelRatio;

    if (_requireResize) {
      _resizeArtboard();
    }

    final artboard = _artboard;
    if (artboard == null) {
      return;
    }
    renderer.save();
    renderer.align(
      fit,
      alignment,
      rive.AABB.fromValues(0, 0, size.width, size.height),
      artboard.bounds,
      _layoutScaleFactorToUse,
    );
    artboard.draw(renderer);
    renderer.restore();
  }

  void _resizeArtboard() {
    final artboard = _artboard;
    if (artboard == null) return;

    final factor = _layoutScaleFactorToUse;
    artboard.width = lastSize.width / factor;
    artboard.height = lastSize.height / factor;

    _requireResize = false;
  }
}

base class SingleAnimationPainter extends BasicArtboardPainter {
  final String animationName;
  rive.Animation? _animation;
  SingleAnimationPainter(this.animationName, {super.fit, super.alignment});

  @override
  void artboardChanged(rive.Artboard artboard) {
    super.artboardChanged(artboard);
    _animation = artboard.animationNamed(animationName);
    notifyListeners();
  }

  @override
  bool advance(double elapsedSeconds) {
    return _animation?.advanceAndApply(elapsedSeconds) ?? false;
  }
}

base class StateMachinePainter extends BasicArtboardPainter
    with rive.RivePointerEventMixin {
  final String? stateMachineName;
  rive.StateMachine? _stateMachine;
  rive.StateMachine? get stateMachine => _stateMachine;
  rive.CallbackHandler? _inputCallbackHandler;

  StateMachinePainter({
    this.stateMachineName,
    this.withStateMachine,
    super.fit,
    super.alignment,
    rive.RiveHitTestBehavior hitTestBehavior = rive.defaultRiveHitTestBehavior,
    MouseCursor cursor = rive.defaultRiveCursor,
  }) {
    this.cursor = cursor;
    this.hitTestBehavior = hitTestBehavior;
  }

  final void Function(rive.StateMachine)? withStateMachine;

  @override
  void artboardChanged(rive.Artboard artboard) {
    super.artboardChanged(artboard);
    _stateMachine?.dispose();
    final machine = _stateMachine = stateMachineName != null
        ? artboard.stateMachine(stateMachineName!)
        : artboard.defaultStateMachine();
    if (machine != null) {
      _inputCallbackHandler = machine.onInputChanged(_onInputChanged);
      withStateMachine?.call(machine);
    }
    notifyListeners();
  }

  void _onInputChanged(int inputId) => notifyListeners();

  @override
  bool hitTest(Offset position) {
    final artboard = _artboard;
    if (artboard == null) {
      return false;
    }
    final value = stateMachine?.hitTest(
          localToArtboard(
            position: position,
            artboardBounds: artboard.bounds,
            fit: fit,
            alignment: alignment,
            size: _lastSize / _lastPaintPixelRatio,
            scaleFactor: layoutScaleFactor,
          ),
        ) ??
        false;
    return value;
  }

  @override
  pointerEvent(PointerEvent event, HitTestEntry<HitTestTarget> entry) {
    final stateMachine = _stateMachine;
    final artboard = _artboard;
    if (stateMachine == null || artboard == null) return;

    final position = localToArtboard(
      position: event.localPosition,
      artboardBounds: artboard.bounds,
      fit: fit,
      alignment: alignment,
      size: _lastSize / _lastPaintPixelRatio,
      scaleFactor: layoutScaleFactor,
    );

    if (event is PointerDownEvent) {
      stateMachine.pointerDown(position);
    } else if (event is PointerUpEvent) {
      stateMachine.pointerUp(position);
    } else if (event is PointerMoveEvent) {
      stateMachine.pointerMove(position);
    } else if (event is PointerHoverEvent) {
      stateMachine.pointerMove(position);
    }
  }

  @override
  bool advance(double elapsedSeconds) {
    return _stateMachine?.advanceAndApply(elapsedSeconds) ?? false;
  }

  @override
  void dispose() {
    _inputCallbackHandler?.dispose();
    _inputCallbackHandler = null;
    super.dispose();
  }
}

class RiveFileWidget extends StatefulWidget {
  final rive.File file;
  final ArtboardPainter painter;
  final String? artboardName;

  const RiveFileWidget({
    required this.file,
    required this.painter,
    this.artboardName,
    super.key,
  });

  @override
  State<RiveFileWidget> createState() => _RiveFileWidgetState();
}

class _RiveFileWidgetState extends State<RiveFileWidget> {
  rive.Artboard? _artboard;
  @override
  void initState() {
    _initArtboard();
    super.initState();
  }

  void _initArtboard() {
    var name = widget.artboardName;
    _artboard = name == null
        ? widget.file.defaultArtboard()
        : widget.file.artboard(name);
  }

  @override
  void dispose() {
    _artboard = null;

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RiveFileWidget oldWidget) {
    if (oldWidget.file != widget.file ||
        oldWidget.artboardName != widget.artboardName ||
        oldWidget.painter != widget.painter) {
      setState(() {
        _initArtboard();
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final artboard = _artboard;
    if (artboard == null) {
      return ErrorWidget.withDetails(
        message: 'Unable to load Rive artboard: "${widget.artboardName}"',
        error: FlutterError('Unable to load artboard: ${widget.artboardName}'),
      );
    }
    return RiveArtboardWidget(
      artboard: artboard,
      painter: widget.painter,
    );
  }
}

class RiveArtboardWidget extends StatefulWidget {
  final rive.Artboard artboard;
  final ArtboardPainter painter;
  const RiveArtboardWidget({
    required this.artboard,
    required this.painter,
    super.key,
  });

  @override
  State<RiveArtboardWidget> createState() => _RiveArtboardWidgetState();
}

class _RiveArtboardWidgetState extends State<RiveArtboardWidget> {
  @override
  void initState() {
    super.initState();
    widget.painter.artboardChanged(widget.artboard);
  }

  @override
  void didUpdateWidget(covariant RiveArtboardWidget oldWidget) {
    if (oldWidget.artboard != widget.artboard) {
      widget.painter.artboardChanged(widget.artboard);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.artboard.riveFactory == rive.Factory.flutter) {
      // Render the artboard with the Flutter renderer.
      return _FlutterRiveRendererWidget(
        painter: widget.painter,
      );
    } else {
      // Render the artboard with the Rive Renderer.
      return _ArtboardWidgetRiveRenderer(
        painter: widget.painter,
        key: widget.key,
      );
    }
  }
}

class RiveProceduralRenderingWidget extends StatefulWidget {
  final rive.Factory riveFactory;
  final ProceduralPainter painter;
  const RiveProceduralRenderingWidget({
    required this.riveFactory,
    required this.painter,
    super.key,
  });

  @override
  State<RiveProceduralRenderingWidget> createState() =>
      _RiveRiveProceduralRenderingWidgetState();
}

class _RiveRiveProceduralRenderingWidgetState
    extends State<RiveProceduralRenderingWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.riveFactory == rive.Factory.flutter) {
      // Render the artboard with the Flutter renderer.
      return _FlutterRiveRendererWidget(
        painter: widget.painter,
      );
    } else {
      // Render the artboard with the Rive Renderer.
      return _ArtboardWidgetRiveRenderer(
        painter: widget.painter,
        key: widget.key,
      );
    }
  }
}

class _ArtboardWidgetRiveRenderer extends StatefulWidget {
  final ProceduralPainter? painter;

  const _ArtboardWidgetRiveRenderer({
    this.painter,
    // ignore: unused_element
    super.key,
  });

  @override
  State<_ArtboardWidgetRiveRenderer> createState() =>
      _ArtboardWidgetRiveRendererState();
}

base class _ArtboardWidgetPainter extends rive.RenderTexturePainter
    with rive.RivePointerEventMixin {
  final ProceduralPainter? _painter;
  final rive.RivePointerEventMixin? _pointerEvent;
  _ArtboardWidgetPainter(this._painter)
      : _pointerEvent = _painter is rive.RivePointerEventMixin
            ? _painter as rive.RivePointerEventMixin
            : null {
    _painter?.addListener(notifyListeners);
  }

  @override
  void dispose() {
    super.dispose();
    _painter?.removeListener(notifyListeners);
  }

  @override
  Color get background => const Color(
      0x00000000); // TODO (GORDON): make this an override and add to canvas imppl

  @override
  bool paint(rive.RenderTexture texture, double devicePixelRatio, Size size,
      double elapsedSeconds) {
    final painter = _painter;
    if (painter == null) {
      return false;
    }

    final shouldContinue = painter.advance(elapsedSeconds);
    painter.paint(texture.renderer, size, devicePixelRatio);
    return shouldContinue;
  }

  @override
  MouseCursor get cursor => _pointerEvent?.cursor ?? rive.defaultRiveCursor;

  @override
  bool hitTest(Offset position) => _pointerEvent?.hitTest(position) ?? false;

  @override
  void pointerEvent(PointerEvent event, HitTestEntry<HitTestTarget> entry) =>
      _pointerEvent?.pointerEvent(event, entry);

  @override
  rive.RiveHitTestBehavior get hitTestBehavior =>
      _pointerEvent?.hitTestBehavior ?? rive.defaultRiveHitTestBehavior;
}

class _ArtboardWidgetRiveRendererState
    extends State<_ArtboardWidgetRiveRenderer> {
  final rive.RenderTexture renderTexture =
      rive.RiveNative.instance.makeRenderTexture();

  _ArtboardWidgetPainter? _painter;
  @override
  void initState() {
    _painter = _ArtboardWidgetPainter(widget.painter);
    super.initState();
  }

  @override
  void dispose() {
    renderTexture.dispose();
    super.dispose();
    _painter?.dispose();
    _painter = null;
  }

  @override
  void didUpdateWidget(covariant _ArtboardWidgetRiveRenderer oldWidget) {
    if (oldWidget.painter != widget.painter) {
      setState(() {
        _painter = _ArtboardWidgetPainter(widget.painter);
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return renderTexture.widget(painter: _painter);
  }
}

class _FlutterRiveRendererWidget extends LeafRenderObjectWidget {
  final ProceduralPainter? painter;

  const _FlutterRiveRendererWidget({
    required this.painter,
    // ignore: unused_element
    super.key,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    final tickerModeValue = TickerMode.of(context);

    return _FlutterRiveRenderBox()
      ..painter = painter
      ..tickerModeEnabled = tickerModeValue;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _FlutterRiveRenderBox renderObject) {
    final tickerModeValue = TickerMode.of(context);

    renderObject
      ..painter = painter
      ..tickerModeEnabled = tickerModeValue;
  }
}

abstract class RiveRenderBox<T extends rive.RivePainter> extends RenderBox
    implements MouseTrackerAnnotation {
  Ticker? _ticker;

  rive.RivePointerEventMixin? _rivePointerEvent;

  T? _rivePainter;
  T? get rivePainter => _rivePainter;

  @mustCallSuper
  set painter(T? value) {
    if (_rivePainter == value) {
      return;
    }
    _rivePainter?.removeListener(restartTickerIfStopped);
    _rivePainter = value;
    _rivePainter?.addListener(restartTickerIfStopped);
    _rivePointerEvent = _rivePainter is rive.RivePointerEventMixin
        ? _rivePainter as rive.RivePointerEventMixin
        : null;
    restartTickerIfStopped();
  }

  bool get tickerModeEnabled => _tickerModeEnabled;
  bool _tickerModeEnabled = true;
  set tickerModeEnabled(bool value) {
    if (value != _tickerModeEnabled) {
      _tickerModeEnabled = value;

      if (_tickerModeEnabled) {
        _startTicker();
      } else {
        _stopTicker();
      }
    }
  }

  // TODO (Gordon): Re-explore this from the old runtime.
  // This is currently not set or used.
  bool get useArtboardSize => _useArtboardSize;
  bool _useArtboardSize = false;
  set useArtboardSize(bool value) {
    if (_useArtboardSize == value) {
      return;
    }
    _useArtboardSize = value;
    if (parent != null) {
      markNeedsLayoutForSizedByParentChange();
    }
  }

  // TODO (Gordon): Re-explore this from the old runtime.
  // This is currently not set or used.
  // Need to consider resizable artboards in the future.
  Size get artboardSize => _artboardSize;
  Size _artboardSize = Size.zero;
  set artboardSize(Size value) {
    if (_artboardSize == value) {
      return;
    }
    _artboardSize = value;
    if (parent != null) {
      markNeedsLayoutForSizedByParentChange();
    }
  }

  rive.RiveHitTestBehavior get hitTestBehavior =>
      _rivePointerEvent?.hitTestBehavior ?? rive.defaultRiveHitTestBehavior;

  void rivePointerEvent(
          PointerEvent event, HitTestEntry<HitTestTarget> entry) =>
      _rivePointerEvent?.pointerEvent(event, entry);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // If hit testing is disabled, we don't need to perform any hit testing.
    if (hitTestBehavior == rive.RiveHitTestBehavior.none) {
      return false;
    }

    bool hitTarget = false;
    if (size.contains(position)) {
      hitTarget = hitTestSelf(position);
      if (hitTarget) {
        // if hit add to results
        result.add(BoxHitTestEntry(this, position));
      }
    }

    // Let the hit continue to targets behind the animation.
    if (hitTestBehavior == rive.RiveHitTestBehavior.transparent) {
      return false;
    }

    // Opaque will always return true, translucent will return true if we
    // hit a Rive listener target.
    return hitTarget;
  }

  @override
  bool hitTestSelf(Offset position) {
    switch (hitTestBehavior) {
      case rive.RiveHitTestBehavior.none:
        return false;
      case rive.RiveHitTestBehavior.opaque:
        return true; // Always hit
      case rive.RiveHitTestBehavior.translucent:
      case rive.RiveHitTestBehavior.transparent:
        {
          final value = _rivePointerEvent?.hitTest(position) ?? false;
          return value;
        }
    }
  }

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (!attached) return;

    rivePointerEvent(event, entry);
  }

  @override
  MouseCursor get cursor => _rivePointerEvent?.cursor ?? rive.defaultRiveCursor;

  @override
  PointerEnterEventListener? get onEnter => (event) {
        rivePointerEvent(event, HitTestEntry(this));
      };

  @override
  PointerExitEventListener? get onExit => (event) {
        rivePointerEvent(event, HitTestEntry(this));
      };

  bool _validForMouseTracker = true;
  @override
  bool get validForMouseTracker => _validForMouseTracker;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    _validForMouseTracker = true;
    _ticker = Ticker(frameCallback);
    if (tickerModeEnabled) {
      _startTicker();
    }
  }

  @override
  void detach() {
    _validForMouseTracker = false;
    _stopTicker();

    super.detach();
  }

  @override
  void dispose() {
    _rivePainter?.removeListener(restartTickerIfStopped);
    _ticker?.dispose();
    _ticker = null;

    super.dispose();
  }

  void _stopTicker() {
    _elapsedSeconds = 0;
    _prevTickerElapsedInSeconds = 0;

    _ticker?.stop();
  }

  void _startTicker() {
    _elapsedSeconds = 0;
    _prevTickerElapsedInSeconds = 0;

    // Always ensure ticker is stopped before starting
    if (_ticker?.isActive ?? false) {
      _ticker?.stop();
    }
    _ticker?.start();
  }

  @protected
  @nonVirtual
  void restartTickerIfStopped() {
    if (_ticker != null && !_ticker!.isActive && tickerModeEnabled) {
      _startTicker();
    }
  }

  /// Time between frame callbacks
  double _elapsedSeconds = 0;
  double get elapsedSeconds => _elapsedSeconds;

  /// The total time [_ticker] has been active in seconds
  double _prevTickerElapsedInSeconds = 0;

  void _calculateElapsedSeconds(Duration duration) {
    final double tickerElapsedInSeconds =
        duration.inMicroseconds.toDouble() / Duration.microsecondsPerSecond;
    assert(tickerElapsedInSeconds >= 0.0);

    _elapsedSeconds = tickerElapsedInSeconds - _prevTickerElapsedInSeconds;
    _prevTickerElapsedInSeconds = tickerElapsedInSeconds;
  }

  /// Whether the animation ticker should advance.
  bool get shouldAdvance;

  /// The frame callback for the ticker.
  ///
  /// Implementations of this method should start with a call to
  /// `super.frameCallback(duration)` to ensure the ticker is properly managed.
  @protected
  @mustCallSuper
  void frameCallback(Duration duration) {
    // TODO (Gordon): We also need to consider standard default behaviour for
    // what Rive should do when not visible on the screen:
    // - Advance and not draw
    // - Draw and advance
    // - Neither advance nor draw
    // - (Optional enum for users to choose)
    _calculateElapsedSeconds(duration);

    if (shouldAdvance == false) {
      _stopTicker();
    }
  }

  @override
  bool get sizedByParent => !useArtboardSize;

  /// Finds the intrinsic size for the rive render box given the [constraints]
  /// and [sizedByParent].
  ///
  /// The difference between the intrinsic size returned here and the size we
  /// use for [performResize] is that the intrinsics contract does not allow
  /// infinite sizes, i.e. we cannot return biggest constraints.
  /// Consequently, the smallest constraint is returned in case we are
  /// [sizedByParent].
  Size _intrinsicSizeForConstraints(BoxConstraints constraints) {
    if (sizedByParent) {
      return constraints.smallest;
    }

    return constraints
        .constrainSizeAndAttemptToPreserveAspectRatio(artboardSize);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(height >= 0.0);
    // If not sized by parent, this returns the constrained (trying to preserve
    // aspect ratio) artboard size.
    // If sized by parent, this returns 0 (because an infinite width does not
    // make sense as an intrinsic width and is therefore not allowed).
    return _intrinsicSizeForConstraints(
            BoxConstraints.tightForFinite(height: height))
        .width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(height >= 0.0);
    // This is equivalent to the min intrinsic width because we cannot provide
    // any greater intrinsic width beyond which increasing the width never
    // decreases the preferred height.
    // When we have an artboard size, the intrinsic min and max width are
    // obviously equivalent and if sized by parent, we can also only return the
    // smallest width constraint (which is 0 in the case of intrinsic width).
    return _intrinsicSizeForConstraints(
            BoxConstraints.tightForFinite(height: height))
        .width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(width >= 0.0);
    // If not sized by parent, this returns the constrained (trying to preserve
    // aspect ratio) artboard size.
    // If sized by parent, this returns 0 (because an infinite height does not
    // make sense as an intrinsic height and is therefore not allowed).
    return _intrinsicSizeForConstraints(
            BoxConstraints.tightForFinite(width: width))
        .height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    assert(width >= 0.0);
    // This is equivalent to the min intrinsic height because we cannot provide
    // any greater intrinsic height beyond which increasing the height never
    // decreases the preferred width.
    // When we have an artboard size, the intrinsic min and max height are
    // obviously equivalent and if sized by parent, we can also only return the
    // smallest height constraint (which is 0 in the case of intrinsic height).
    return _intrinsicSizeForConstraints(
            BoxConstraints.tightForFinite(width: width))
        .height;
  }

  // This replaces the old performResize method.
  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void performLayout() {
    if (!sizedByParent) {
      // We can use the intrinsic size here because the intrinsic size matches
      // the constrained artboard size when not sized by parent.
      size = _intrinsicSizeForConstraints(constraints);
    }
  }
}

class _FlutterRiveRenderBox extends RiveRenderBox<ProceduralPainter> {
  @override
  set painter(ProceduralPainter? value) {
    super.painter = value;

    markNeedsPaint();
  }

  @override
  bool get shouldAdvance => rivePainter?.advance(elapsedSeconds) ?? false;

  @override
  @mustCallSuper
  void frameCallback(Duration duration) {
    super.frameCallback(duration);

    markNeedsPaint();
  }

  @protected
  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    var renderer = rive.Renderer.make(canvas);
    rivePainter?.paint(renderer, size, 1.0);
    renderer.dispose();
    canvas.restore();
  }
}

abstract class RiveNativeRenderBox<T extends rive.RivePainter>
    extends RiveRenderBox<T> {
  double _devicePixelRatio = 1.0;

  /// The device pixel ratio used to determine the size of the paint area.
  double get devicePixelRatio => _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == devicePixelRatio) {
      return;
    }
    _devicePixelRatio = value;
    markNeedsLayout();
  }

  @override
  void performResize() {
    size = constraints.biggest;
  }
}

import 'dart:async';
import 'dart:ffi';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_native/rive_native.dart';
import 'package:rive_native/src/ffi/dynamic_library_helper.dart';
import 'package:rive_native/src/ffi/rive_renderer_ffi.dart';
import 'package:rive_native/src/rive.dart' as rive;

final DynamicLibrary nativeLib = DynamicLibraryHelper.nativeLib;

Set<int> _allTextures = {};
final void Function(int, bool, int) _nativeClear = nativeLib
    .lookup<NativeFunction<Void Function(Uint64, Bool, Uint32)>>('clear')
    .asFunction();
final void Function(double) _nativeFlush = nativeLib
    .lookup<NativeFunction<Void Function(Float)>>('flush')
    .asFunction();
final Pointer<Void> Function() _currentNativeTexture = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function()>>('currentNativeTexture')
    .asFunction();

base class _NativeRenderTexture extends RenderTexture {
  @override
  Pointer<Void> get nativeTexture => _currentNativeTexture();

  final MethodChannel methodChannel;
  int _textureId = -1;

  _NativeRenderTexture(this.methodChannel);

  @override
  bool get isReady => _textureId != -1;

  @override
  void dispose() {
    if (_textureId != -1) {
      _disposeTexture(_textureId);
      _textureId = -1;
    }
  }

  int _width = 0;
  int _height = 0;
  bool needsResize(int width, int height) =>
      width != _width || height != _height;

  final List<int> _deadTextures = [];

  void _disposeTextures() {
    _disposeTimer = null;
    var textures = _deadTextures.toList();
    _deadTextures.clear();
    for (final texture in textures) {
      methodChannel.invokeMethod('removeTexture', {'id': texture});
    }
  }

  Timer? _disposeTimer;
  void _disposeTexture(int id) {
    _deadTextures.add(id);
    if (_disposeTimer != null) {
      return;
    }

    _disposeTimer = Timer(const Duration(seconds: 1), _disposeTextures);
  }

  Future<void> makeRenderTexture(int width, int height) async {
    // Immediately update cached values in-case we redraw during udpate.
    _width = width;
    _height = height;
    final result = await methodChannel
        .invokeMethod('createTexture', {'width': width, 'height': height});
    int? textureId = result['textureId'] as int?;

    if (textureId != null) {
      _allTextures.add(textureId);
    }
    if (_textureId != -1) {
      _allTextures.remove(_textureId);
      _disposeTexture(_textureId);
    }

    if (textureId == null) {
      _textureId = -1;
    } else {
      _textureId = textureId;
    }
  }

  @override
  Widget widget({RenderTexturePainter? painter, Key? key}) =>
      _RiveNativeView(this, painter, key: key);

  @override
  void clear(Color color, [bool write = true]) =>
      _nativeClear(_textureId, write, color.value);

  @override
  void flush(double devicePixelRatio) {
    _nativeFlush(devicePixelRatio);
  }

  @override
  Renderer get renderer => FFIRiveRenderer(rive.Factory.rive);

  @override
  Future<ui.Image> toImage() {
    final scene = SceneBuilder();
    scene.addTexture(
      _textureId,
      // offset: Offset(-offset.dx, -offset.dy - 40),
      width: _width.toDouble(),
      height: _height.toDouble(),
      freeze: true,
    );

    final build = scene.build();
    return build.toImage(_width, _height);
    // final imageData =
    //     await imagemCapturada.toByteData(format: ImageByteFormat.png);
    // final imageBytes = imageData!.buffer
    //     .asUint8List(imageData.offsetInBytes, imageData.buffer.lengthInBytes);
    // return imageBytes;
  }
}

class _RiveNativeFFI extends RiveNative {
  final methodChannel = const MethodChannel('rive_native');
  @override
  RenderTexture makeRenderTexture() => _NativeRenderTexture(methodChannel);
}

Future<RiveNative?> makeRiveNative() async => _RiveNativeFFI();

class _RiveNativeView extends LeafRenderObjectWidget {
  final _NativeRenderTexture renderTexture;
  final RenderTexturePainter? painter;
  const _RiveNativeView(
    this.renderTexture,
    this.painter, {
    super.key,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RiveNativeViewRenderObject(
      renderTexture,
      painter,
    )
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context)
      ..tickerModeEnabled = TickerMode.of(context);
  }

  @override
  void updateRenderObject(BuildContext context,
      covariant _RiveNativeViewRenderObject renderObject) {
    renderObject
      ..renderTexture = renderTexture
      ..painter = painter
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context)
      ..tickerModeEnabled = TickerMode.of(context);
  }

  @override
  void didUnmountRenderObject(
      covariant _RiveNativeViewRenderObject renderObject) {
    renderObject.painter = null;
  }
}

class _RiveNativeViewRenderObject
    extends RiveNativeRenderBox<RenderTexturePainter> {
  _NativeRenderTexture _renderTexture;

  _RiveNativeViewRenderObject(
      this._renderTexture, RenderTexturePainter? renderTexturePainter) {
    painter = renderTexturePainter;
  }

  @override
  bool get shouldAdvance => _shouldAdvance;
  bool _shouldAdvance = false;

  @override
  void frameCallback(Duration duration) {
    super.frameCallback(duration);
    _paintTexture(elapsedSeconds);
  }

  void _paintTexture(double elapsedSeconds) {
    final painter = rivePainter;
    if (painter == null || !renderTexture.isReady || !hasSize) {
      return;
    }
    final width = (size.width * devicePixelRatio).roundToDouble();
    final height = (size.height * devicePixelRatio).roundToDouble();
    _renderTexture.clear(painter.background, painter.clear);
    final shouldAdvance = painter.paint(_renderTexture, devicePixelRatio,
        ui.Size(width, height), elapsedSeconds);
    if (shouldAdvance && shouldAdvance != _shouldAdvance) {
      restartTickerIfStopped();
    }
    _shouldAdvance = shouldAdvance;
    _renderTexture.flush(devicePixelRatio);
    if (painter.paintsCanvas) {
      markNeedsPaint();
    }
  }

  _NativeRenderTexture get renderTexture => _renderTexture;
  set renderTexture(_NativeRenderTexture value) {
    if (_renderTexture == value) {
      return;
    }
    _renderTexture = value;
    markNeedsPaint();
  }

  // TODO (Gordon): This needs to be tested for Android once the Rive Renderer
  // is working there. The `freeze` option that is set for `context.addLayer`
  // I believe is only relevant for Android.
  var _isResizing = false;

  @override
  void performLayout() {
    final width = (size.width * devicePixelRatio).round();
    final height = (size.height * devicePixelRatio).round();
    if (_renderTexture.needsResize(width, height)) {
      _isResizing = true;
      // TODO (Gordon): Maybe this can be a cancelable future if we're
      // laying out continuously
      _renderTexture.makeRenderTexture(width, height).then(
        (_) {
          _isResizing = false;
          rivePainter?.textureCreated(width, height);
          _renderTexture.textureCreated(width, height);
          _paintTexture(0);
          // Texture id will have changed...
          markNeedsPaint();
        },
      );
      // TODO (Gordon): This may not be needed
      // Forces an extra call to markNeedsPaint to help when resizing
      // while the future is completing.
      markNeedsPaint();
    }
  }

  @override
  ui.Size computeDryLayout(BoxConstraints constraints) => constraints.smallest;

  // QUESTION (GORDON): Looks like this is needed when doing `context.addLayer`.
  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_renderTexture.isReady) {
      return;
    }
    context.addLayer(
      TextureLayer(
        rect: Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
        textureId: _renderTexture._textureId,
        freeze: _isResizing,
        filterQuality: FilterQuality.low,
      ),
    );
    final painter = rivePainter;
    if (painter != null && painter.paintsCanvas) {
      painter.paintCanvas(context.canvas, offset, size);
    }
  }
}

// ignore_for_file: invalid_export_of_internal_element

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:rive_native/rive_native.dart';
import 'package:rive_native/rive_text.dart';

import 'src/rive_native_ffi.dart'
    if (dart.library.js_interop) 'src/rive_native_web.dart';

export 'src/rive.dart';
export 'src/rive_renderer.dart';
export 'package:rive_native/math.dart';
export 'src/rive_widget.dart';
export 'src/rive_hit_test.dart';
export 'src/defaults.dart';

/// Base class for a Rive painter.
///
/// This is used to notify listeners when the painter changes.
///
/// Optional pointer event handling can be enabled with the
/// [PainterPointerEventMixin].
abstract base class RivePainter extends ChangeNotifier {
  RivePainter();

  /// Creates a new [SingleAnimationPainter] instance.
  ///
  /// - [animationName] is the name of the animation to play.
  /// - [fit] determines how the artboard is scaled to fit its container.
  /// - [alignment] determines how the artboard is positioned within its container.
  static SingleAnimationPainter animation(
    String animationName, {
    Fit fit = RiveDefaults.fit,
    Alignment alignment = RiveDefaults.alignment,
  }) =>
      SingleAnimationPainter(
        animationName,
        fit: fit,
        alignment: alignment,
      );

  /// Creates a new [StateMachinePainter] instance.
  ///
  /// - [stateMachineName] is the name of the state machine to use. If null, the
  /// default state machine will be used.
  /// - [fit] determines how the artboard is scaled to fit its container.
  /// - [alignment] determines how the artboard is positioned within its
  /// container.
  /// - [withStateMachine] is an optional callback that will be called with the.
  /// - [hitTestBehavior] determines how the state machine handles pointer events.
  /// - [cursor] determines the cursor to display when the pointer is over the
  /// state machine.
  static StateMachinePainter stateMachine({
    String? stateMachineName,
    Fit fit = RiveDefaults.fit,
    Alignment alignment = RiveDefaults.alignment,
    void Function(StateMachine)? withStateMachine,
    RiveHitTestBehavior hitTestBehavior = defaultRiveHitTestBehavior,
    MouseCursor cursor = defaultRiveCursor,
  }) =>
      StateMachinePainter(
        stateMachineName: stateMachineName,
        withStateMachine: withStateMachine,
        fit: fit,
        alignment: alignment,
        hitTestBehavior: hitTestBehavior,
        cursor: cursor,
      );
}

/// A painting context passed to a Rive RenderTexture widget which will invoke
/// the paint method as necessary to paint into the texture with a Rive
/// renderer.
///
/// The `paint` method will be invoked to paint the texture.
///
/// Override the `background` property to set the desired background color.
///
/// Override the `clear` property to `false` to skip clearing the texture before
/// painting.
///
/// Optionally override `paintCanvas` to use Flutter's native renderer
/// to draw into the widget's RenderBox on top of Rive's texture.
///
/// The `textureCreated` method will be invoked when the texture is created.
abstract base class RenderTexturePainter extends RivePainter {
  bool get clear => true;
  Color get background;
  bool paint(RenderTexture texture, double devicePixelRatio, Size size,
      double elapsedSeconds);
  bool get paintsCanvas => false;
  void paintCanvas(Canvas canvas, Offset offset, Size size) {}
  void textureCreated(int width, int height) {}
}

abstract base class RenderTexture {
  dynamic get nativeTexture;
  Widget widget({RenderTexturePainter? painter, Key? key});
  void dispose();

  void clear(Color color, [bool write = true]);
  void flush(double devicePixelRatio);
  bool get isReady;

  Renderer get renderer;

  Future<ui.Image> toImage();

  void Function(int width, int height)? _textureCreatedCallback;

  set onTextureCreated(void Function(int width, int height)? callback) {
    _textureCreatedCallback = callback;
  }

  void textureCreated(int width, int height) {
    _textureCreatedCallback?.call(width, height);
  }
}

abstract class RiveNative {
  static late RiveNative instance;
  static bool isInitialized = false;

  static Future<bool> init() async {
    if (isInitialized) {
      return true;
    }
    var riveNative = await makeRiveNative();
    if (riveNative != null) {
      instance = riveNative;
      Font.initialize();
      isInitialized = true;
      return true;
    }
    isInitialized = false;
    return false;
  }

  RenderTexture makeRenderTexture();
}

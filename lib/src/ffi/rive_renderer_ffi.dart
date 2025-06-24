import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:rive_native/rive_native.dart';
import 'package:rive_native/rive_text.dart';
import 'package:rive_native/src/buffered_render_paint.dart';
import 'package:rive_native/src/buffered_render_path.dart';
import 'package:rive_native/src/ffi/dynamic_library_helper.dart';
import 'package:rive_native/src/ffi/flutter_renderer_ffi.dart';
import 'package:rive_native/src/ffi/rive_ffi.dart';
import 'package:rive_native/src/ffi/rive_text_ffi.dart';
import 'package:rive_native/src/ffi/rive_ffi_reference.dart';
import 'package:rive_native/src/rive.dart' as rive;
import 'package:rive_native/src/utilities/utilities.dart';

final DynamicLibrary nativeLib = DynamicLibraryHelper.open();

final Pointer<Float> _floatQueryBuffer =
    calloc.allocate<Float>(sizeOf<Float>() * 5);

final void Function(Pointer<Uint8>, int) _appendCommands = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Uint8>, Uint32)>>(
        'appendCommands')
    .asFunction();

final Pointer<Void> Function() _boundRenderer = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function()>>('boundRenderer')
    .asFunction();
final Pointer<Void> Function(Pointer<Void>) _makeRenderPath = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
        'makeRenderPath')
    .asFunction();
final Pointer<Void> Function(Pointer<Void>) _makeEmptyRenderPath = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
        'makeEmptyRenderPath')
    .asFunction();
final Pointer<Void> Function(Pointer<Void>) _appendRenderPath = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
        'appendRenderPath')
    .asFunction();
final Pointer<Void> Function(Pointer<Void>) _rewindRenderPath = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
        'rewindRenderPath')
    .asFunction();
final Pointer<Void> Function(Pointer<Void>, int) _renderPathSetFillRule =
    nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>, Uint8)>>(
            'renderPathSetFillRule')
        .asFunction();
final Pointer<Void> Function(Pointer<Void>, Pointer<Uint8> bytes, int length)
    _decodeRenderImage = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(Pointer<Void>, Pointer<Uint8>,
                    Uint64)>>('decodeRenderImage')
        .asFunction();
final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deleteRenderImageNative =
    nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'deleteRenderImage');
final void Function(Pointer<Void>) _deleteRenderImage =
    _deleteRenderImageNative.asFunction();

final int Function(Pointer<Void>) _renderImageWidth = nativeLib
    .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>('renderImageWidth')
    .asFunction();
final int Function(Pointer<Void>) _renderImageHeight = nativeLib
    .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>('renderImageHeight')
    .asFunction();

final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deleteRenderPathNative =
    nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'deleteRenderPath');
final void Function(Pointer<Void>) _deleteRenderPath =
    _deleteRenderPathNative.asFunction();
final void Function(Pointer<Void>, Pointer<Void>, int, double) _drawImage =
    nativeLib
        .lookup<
            NativeFunction<
                Void Function(
                    Pointer<Void>, Pointer<Void>, Uint8, Float)>>('drawImage')
        .asFunction();
final void Function(Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>,
        Pointer<Void>, int, int, int, double) _drawImageMesh =
    nativeLib
        .lookup<
            NativeFunction<
                Void Function(
                    Pointer<Void>,
                    Pointer<Void>,
                    Pointer<Void>,
                    Pointer<Void>,
                    Pointer<Void>,
                    Uint32,
                    Uint32,
                    Uint8,
                    Float)>>('drawImageMesh')
        .asFunction();
final void Function(Pointer<Void>, Pointer<Void>, Pointer<Void>) _drawPath =
    nativeLib
        .lookup<
            NativeFunction<
                Void Function(
                    Pointer<Void>, Pointer<Void>, Pointer<Void>)>>('drawPath')
        .asFunction();
final void Function(Pointer<Void>, Pointer<Void>) _clipPath = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<Void>)>>(
        'clipPath')
    .asFunction();
final void Function(Pointer<Void>) _nativeSave = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>('save')
    .asFunction();
final void Function(Pointer<Void>) _nativeRestore = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>('restore')
    .asFunction();
final void Function(Pointer<Void>, Pointer<Void>, double, double, double,
        double, double, double) _nativeAddPath =
    nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Pointer<Void>, Float, Float, Float,
                    Float, Float, Float)>>('addPath')
        .asFunction();

final void Function(Pointer<Void>, Pointer<Void>, Pointer<Void>, double, double,
        double, double, double, double) _nativeAddPathBackwards =
    nativeLib
        .lookup<
            NativeFunction<
                Void Function(
                    Pointer<Void>,
                    Pointer<Void>,
                    Pointer<Void>,
                    Float,
                    Float,
                    Float,
                    Float,
                    Float,
                    Float)>>('addPathBackwards')
        .asFunction();
final void Function(
        Pointer<Void>, double, double, double, double, double, double)
    _nativeTransform = nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Float, Float, Float, Float, Float,
                    Float)>>('transform')
        .asFunction();
final Pointer<Void> Function(Pointer<Void>) _makeRenderPaint = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
        'makeRenderPaint')
    .asFunction();
final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deleteRenderPaintNative =
    nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'deleteRenderPaint');
final void Function(Pointer<Void>) _deleteRenderPaint =
    _deleteRenderPaintNative.asFunction();

final void Function(Pointer<Void>, Pointer<Void>, int, Pointer<Uint8>, int)
    _updatePaint = nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Pointer<Void>, Uint16,
                    Pointer<Uint8>, Uint16)>>('updatePaint')
        .asFunction();

final Pointer<Void> Function() _makeDashPathEffect = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function()>>('makeDashPathEffect')
    .asFunction();

final double Function(Pointer<Void>) _dashPathEffectGetOffset = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
        'dashPathEffectGetOffset')
    .asFunction();

final double Function(Pointer<Void>) _dashPathEffectGetPathLength = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
        'dashPathEffectGetPathLength')
    .asFunction();

final void Function(Pointer<Void>, double) _dashPathEffectSetOffset = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
        'dashPathEffectSetOffset')
    .asFunction();

final bool Function(Pointer<Void>) _dashPathEffectGetOffsetIsPercentage =
    nativeLib
        .lookup<NativeFunction<Bool Function(Pointer<Void>)>>(
            'dashPathEffectGetOffsetIsPercentage')
        .asFunction();

final void Function(Pointer<Void>, bool) _dashPathEffectSetOffsetIsPercentage =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Bool)>>(
            'dashPathEffectSetOffsetIsPercentage')
        .asFunction();

final void Function(Pointer<Void>) _dashPathClearDashes = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>('dashPathClearDashes')
    .asFunction();

final void Function(Pointer<Void>, double distance, bool percentage)
    _dashPathAddDash = nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Float, Bool)>>(
            'dashPathAddDash')
        .asFunction();

final void Function(Pointer<Void>) _dashPathInvalidate = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>('dashPathInvalidate')
    .asFunction();

final Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Pointer<Void>)
    _dashPathEffectPath = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(Pointer<Void>, Pointer<Void>,
                    Pointer<Void>)>>('dashPathEffectPath')
        .asFunction();

final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deleteDashPathEffectNative =
    nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'deleteDashPathEffect');

final void Function(Pointer<Void>) _deleteDashPathEffect =
    _deleteDashPathEffectNative.asFunction();

final Pointer<Void> Function() _makeTrimPathEffect = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function()>>('makeTrimPathEffect')
    .asFunction();

final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deleteTrimPathEffectNative =
    nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'deleteTrimPathEffect');

final void Function(Pointer<Void>) _deleteTrimPathEffect =
    _deleteTrimPathEffectNative.asFunction();

final double Function(Pointer<Void>) _trimPathEffectGetEnd = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
        'trimPathEffectGetEnd')
    .asFunction();

final void Function(Pointer<Void>, double) _trimPathEffectSetEnd = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
        'trimPathEffectSetEnd')
    .asFunction();

final double Function(Pointer<Void>) _trimPathEffectGetStart = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
        'trimPathEffectGetStart')
    .asFunction();

final void Function(Pointer<Void>, double) _trimPathEffectSetStart = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
        'trimPathEffectSetStart')
    .asFunction();

final double Function(Pointer<Void>) _trimPathEffectGetOffset = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
        'trimPathEffectGetOffset')
    .asFunction();

final void Function(Pointer<Void>, double) _trimPathEffectSetOffset = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
        'trimPathEffectSetOffset')
    .asFunction();

final int Function(Pointer<Void>) _trimPathEffectGetMode = nativeLib
    .lookup<NativeFunction<Uint8 Function(Pointer<Void>)>>(
        'trimPathEffectGetMode')
    .asFunction();

final void Function(Pointer<Void>, int) _trimPathEffectSetMode = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Uint8)>>(
        'trimPathEffectSetMode')
    .asFunction();

final void Function(Pointer<Void>) _trimPathEffectInvalidate = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'trimPathEffectInvalidate')
    .asFunction();

final Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Pointer<Void>)
    _trimPathEffectPath = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(Pointer<Void>, Pointer<Void>,
                    Pointer<Void>)>>('trimPathEffectPath')
        .asFunction();

final void Function(
        Pointer<Void> pathMeasure, double percentage, Pointer<Float> out)
    _pathMeasureAtPercentage = nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Float,
                    Pointer<Float>)>>('pathMeasureAtPercentage')
        .asFunction();

final void Function(
        Pointer<Void> pathMeasure, double distance, Pointer<Float> out)
    _pathMeasureAtDistance = nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Float,
                    Pointer<Float>)>>('pathMeasureAtDistance')
        .asFunction();

final double Function(Pointer<Void> pathMeasure) _pathMeasureLength = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>('pathMeasureLength')
    .asFunction();

final Pointer<Void> Function(Pointer<Void>, Pointer<Void>, double)
    _makePathMeasure = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(
                    Pointer<Void>, Pointer<Void>, Float)>>('makePathMeasure')
        .asFunction();

final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deletePathMeasureNative =
    nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'deletePathMeasure');

final void Function(Pointer<Void>) _deletePathMeasure =
    _deletePathMeasureNative.asFunction();

final Pointer<Void> Function() _getGPU = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function()>>('getGPU')
    .asFunction();

final Pointer<Void> Function() _getQueue = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function()>>('getQueue')
    .asFunction();

final bool Function(Pointer<Void>, Pointer<Void>, double)
    _renderPathIsClockwise = nativeLib
        .lookup<
            NativeFunction<
                Bool Function(
                  Pointer<Void>,
                  Pointer<Void>,
                  Float,
                )>>('renderPathIsClockwise')
        .asFunction();

final bool Function(
        Pointer<Void>,
        Pointer<Void>,
        double x,
        double y,
        double hitRadius,
        double x1,
        double y1,
        double x2,
        double y2,
        double tx,
        double ty) _renderPathHitTest =
    nativeLib
        .lookup<
            NativeFunction<
                Bool Function(
                    Pointer<Void>,
                    Pointer<Void>,
                    Float,
                    Float,
                    Float,
                    Float,
                    Float,
                    Float,
                    Float,
                    Float,
                    Float)>>('renderPathHitTest')
        .asFunction();

final void Function(Pointer<Void>, Pointer<Void>, double, double, double,
        double, double, double, Pointer<Float>) _renderPathPreciseBounds =
    nativeLib
        .lookup<
            NativeFunction<
                Void Function(
                    Pointer<Void>,
                    Pointer<Void>,
                    Float,
                    Float,
                    Float,
                    Float,
                    Float,
                    Float,
                    Pointer<Float>)>>('renderPathPreciseBounds')
        .asFunction();

final void Function(Pointer<Void>, Pointer<Void>, double, double, double,
        double, double, double, Pointer<Float>) _renderPathBounds =
    nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Pointer<Void>, Float, Float, Float,
                    Float, Float, Float, Pointer<Float>)>>('renderPathBounds')
        .asFunction();

final double Function(Pointer<Void>, Pointer<Void>, double, double, double,
        double, double, double) _renderPathPreciseLength =
    nativeLib
        .lookup<
            NativeFunction<
                Float Function(Pointer<Void>, Pointer<Void>, Float, Float,
                    Float, Float, Float, Float)>>('renderPathPreciseLength')
        .asFunction();

final bool Function(Pointer<Void>, Pointer<Void>, Pointer<Float>)
    _renderPathColinearCheck = nativeLib
        .lookup<
            NativeFunction<
                Bool Function(Pointer<Void>, Pointer<Void>,
                    Pointer<Float>)>>('renderPathColinearCheck')
        .asFunction();

final bool Function(Pointer<Void>, Pointer<Void>) _renderPathIsClosed =
    nativeLib
        .lookup<NativeFunction<Bool Function(Pointer<Void>, Pointer<Void>)>>(
            'renderPathIsClosed')
        .asFunction();

final bool Function(Pointer<Void>, Pointer<Void>) _renderPathHasBounds =
    nativeLib
        .lookup<NativeFunction<Bool Function(Pointer<Void>, Pointer<Void>)>>(
            'renderPathHasBounds')
        .asFunction();

final int Function(
        Pointer<Void>, Pointer<Void>, Pointer<Uint8>, int, Pointer<Float>, int)
    _renderPathCopyBuffers = nativeLib
        .lookup<
            NativeFunction<
                Int32 Function(Pointer<Void>, Pointer<Void>, Pointer<Uint8>,
                    Uint32, Pointer<Float>, Uint32)>>('renderPathCopyBuffers')
        .asFunction();

final void Function(Pointer<Void>, Pointer<Void>) _nativeAddRawPath = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<Void>)>>(
        'addRawPath')
    .asFunction();

final void Function(Pointer<Void>, Pointer<Void>, double, double, double,
        double, double, double) _nativeAddRawPathWithTransform =
    nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Pointer<Void>, Float, Float, Float,
                    Float, Float, Float)>>('addRawPathWithTransform')
        .asFunction();

final void Function(Pointer<Void>, Pointer<Void>, double, double, double,
        double, double, double) _nativeAddRawPathWithTransformClockwise =
    nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Pointer<Void>, Float, Float, Float,
                    Float, Float, Float)>>('addRawPathWithTransformClockwise')
        .asFunction();

final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deleteRawTextNative = nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>)>>('deleteRawText');
final void Function(Pointer<Void>) _deleteRawText =
    _deleteRawTextNative.asFunction();

final void Function(
        Pointer<Void> rawText,
        Pointer<Void> text,
        Pointer<Void> paint,
        Pointer<Void> font,
        double size,
        double lineHeight,
        double letterSpacing) _rawTextAppend =
    nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Pointer<Void>, Pointer<Void>,
                    Pointer<Void>, Float, Float, Float)>>('rawTextAppend')
        .asFunction();

final void Function(Pointer<Void> rawText) _rawTextClear = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>('rawTextClear')
    .asFunction();

final bool Function(Pointer<Void> rawText) _rawTextIsEmpty = nativeLib
    .lookup<NativeFunction<Bool Function(Pointer<Void>)>>('rawTextIsEmpty')
    .asFunction();

final int Function(Pointer<Void> rawText) _rawTextGetSizing = nativeLib
    .lookup<NativeFunction<Uint8 Function(Pointer<Void>)>>('rawTextGetSizing')
    .asFunction();

final int Function(Pointer<Void> rawText, int value) _rawTextSetSizing =
    nativeLib
        .lookup<NativeFunction<Uint8 Function(Pointer<Void>, Uint8)>>(
            'rawTextSetSizing')
        .asFunction();

final int Function(Pointer<Void> rawText) _rawTextGetOverflow = nativeLib
    .lookup<NativeFunction<Uint8 Function(Pointer<Void>)>>('rawTextGetOverflow')
    .asFunction();

final int Function(Pointer<Void> rawText, int value) _rawTextSetOverflow =
    nativeLib
        .lookup<NativeFunction<Uint8 Function(Pointer<Void>, Uint8)>>(
            'rawTextSetOverflow')
        .asFunction();

final int Function(Pointer<Void> rawText) _rawTextGetAlign = nativeLib
    .lookup<NativeFunction<Uint8 Function(Pointer<Void>)>>('rawTextGetAlign')
    .asFunction();

final int Function(Pointer<Void> rawText, int value) _rawTextSetAlign =
    nativeLib
        .lookup<NativeFunction<Uint8 Function(Pointer<Void>, Uint8)>>(
            'rawTextSetAlign')
        .asFunction();

final double Function(Pointer<Void> rawText) _rawTextGetMaxWidth = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>('rawTextGetMaxWidth')
    .asFunction();

final int Function(Pointer<Void> rawText, double value) _rawTextSetMaxWidth =
    nativeLib
        .lookup<NativeFunction<Uint8 Function(Pointer<Void>, Float)>>(
            'rawTextSetMaxWidth')
        .asFunction();

final double Function(Pointer<Void> rawText) _rawTextGetMaxHeight = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
        'rawTextGetMaxHeight')
    .asFunction();

final int Function(Pointer<Void> rawText, double value) _rawTextSetMaxHeight =
    nativeLib
        .lookup<NativeFunction<Uint8 Function(Pointer<Void>, Float)>>(
            'rawTextSetMaxHeight')
        .asFunction();

final double Function(Pointer<Void> rawText) _rawTextGetParagraphSpacing =
    nativeLib
        .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
            'rawTextGetParagraphSpacing')
        .asFunction();

final int Function(Pointer<Void> rawText, double value)
    _rawTextSetParagraphSpacing = nativeLib
        .lookup<NativeFunction<Uint8 Function(Pointer<Void>, Float)>>(
            'rawTextSetParagraphSpacing')
        .asFunction();

final void Function(Pointer<Void> rawText, Pointer<Float> out) _rawTextBounds =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<Float>)>>(
            'rawTextBounds')
        .asFunction();

final void Function(Pointer<Void> rawText, Pointer<Void> renderer,
        Pointer<Void> renderPaint) _rawTextRender =
    nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Pointer<Void>,
                    Pointer<Void>)>>('rawTextRender')
        .asFunction();

final class RenderTextFFI extends RenderText
    implements RiveFFIReference, Finalizable {
  static final _finalizer = NativeFinalizer(_deleteRawTextNative);

  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;

  RenderTextFFI(this._pointer) {
    _finalizer.attach(this, _pointer.cast(), detach: this);
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    _finalizer.detach(this);
    _deleteRawText(_pointer);
    _pointer = nullptr;
  }

  @override
  void append(
    String text, {
    required covariant FontFFI font,
    covariant FFIRenderPaint? paint,
    double size = 16,
    double lineHeight = -1,
    double letterSpacing = 0,
  }) {
    final nativeString = text.toNativeUtf8();
    _rawTextAppend(_pointer, nativeString.cast(), paint?.nativePaint ?? nullptr,
        font.fontPtr, size, lineHeight, letterSpacing);
    malloc.free(nativeString);
  }

  @override
  void clear() => _rawTextClear(_pointer);

  @override
  TextSizing get sizing =>
      TextSizing.values.elementAtOrFirst(_rawTextGetSizing(_pointer));

  @override
  set sizing(TextSizing value) => _rawTextSetSizing(_pointer, value.index);

  @override
  TextOverflow get overflow =>
      TextOverflow.values.elementAtOrFirst(_rawTextGetOverflow(_pointer));

  @override
  set overflow(TextOverflow value) =>
      _rawTextSetOverflow(_pointer, value.index);

  @override
  TextAlign get align =>
      TextAlign.values.elementAtOrFirst(_rawTextGetAlign(_pointer));

  @override
  set align(TextAlign value) => _rawTextSetAlign(_pointer, value.index);

  @override
  double get maxWidth => _rawTextGetMaxWidth(_pointer);

  @override
  set maxWidth(double value) => _rawTextSetMaxWidth(_pointer, value);

  @override
  double get maxHeight => _rawTextGetMaxHeight(_pointer);

  @override
  set maxHeight(double value) => _rawTextSetMaxHeight(_pointer, value);

  @override
  double get paragraphSpacing => _rawTextGetParagraphSpacing(_pointer);

  @override
  set paragraphSpacing(double value) =>
      _rawTextSetParagraphSpacing(_pointer, value);

  @override
  AABB get bounds {
    _rawTextBounds(pointer, _floatQueryBuffer);
    return AABB.fromValues(
      _floatQueryBuffer[0],
      _floatQueryBuffer[1],
      _floatQueryBuffer[2],
      _floatQueryBuffer[3],
    );
  }

  @override
  bool get isEmpty => _rawTextIsEmpty(pointer);
}

final class NativeVec2D extends Struct {
  @Float()
  external double x;
  @Float()
  external double y;

  ui.Offset asOffset() => ui.Offset(x, y);
}

class FFIDashPath extends DashPathEffect
    implements RiveFFIReference, Finalizable {
  static final _finalizer = NativeFinalizer(_deleteDashPathEffectNative);
  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;

  FFIDashPath() : _pointer = _makeDashPathEffect() {
    _finalizer.attach(this, _pointer.cast(), detach: this);
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    _finalizer.detach(this);
    _deleteDashPathEffect(_pointer);
    _pointer = nullptr;
  }

  @override
  double get pathLength => _dashPathEffectGetPathLength(pointer);

  @override
  double get offset => _dashPathEffectGetOffset(pointer);
  @override
  set offset(double value) => _dashPathEffectSetOffset(pointer, value);

  @override
  bool get offsetIsPercentage => _dashPathEffectGetOffsetIsPercentage(pointer);
  @override
  set offsetIsPercentage(bool value) =>
      _dashPathEffectSetOffsetIsPercentage(pointer, value);

  @override
  void clearDashArray() => _dashPathClearDashes(pointer);

  @override
  void addToDashArray(double value, bool percentage) =>
      _dashPathAddDash(pointer, value, percentage);

  @override
  void invalidate() => _dashPathInvalidate(pointer);

  @override
  RenderPath effectPath(covariant FFIRenderPath path) =>
      FFIRenderPath.fromPointer(
        path.riveFactory,
        _dashPathEffectPath(
          path.riveFactory.pointer,
          _pointer,
          path.pointer,
        ),
      );
}

class FFITrimPath extends TrimPathEffect
    implements RiveFFIReference, Finalizable {
  static final _finalizer = NativeFinalizer(_deleteTrimPathEffectNative);

  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;

  FFITrimPath() : _pointer = _makeTrimPathEffect() {
    _finalizer.attach(this, _pointer.cast(), detach: this);
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    _finalizer.detach(this);
    _deleteTrimPathEffect(_pointer);
    _pointer = nullptr;
  }

  @override
  double get end => _trimPathEffectGetEnd(_pointer);

  @override
  set end(double value) => _trimPathEffectSetEnd(_pointer, value);

  @override
  TrimPathMode get mode =>
      TrimPathMode.values[_trimPathEffectGetMode(_pointer)];

  @override
  set mode(TrimPathMode value) => _trimPathEffectSetMode(_pointer, value.index);

  @override
  double get offset => _trimPathEffectGetOffset(_pointer);

  @override
  set offset(double value) => _trimPathEffectSetOffset(_pointer, value);

  @override
  double get start => _trimPathEffectGetStart(_pointer);

  @override
  set start(double value) => _trimPathEffectSetStart(_pointer, value);

  @override
  RenderPath effectPath(covariant FFIRenderPath path) =>
      FFIRenderPath.fromPointer(
        path.riveFactory,
        _trimPathEffectPath(
          path.riveFactory.pointer,
          _pointer,
          path.pointer,
        ),
      );

  @override
  void invalidate() => _trimPathEffectInvalidate(_pointer);
}

TrimPathEffect makeTrimPathEffect() => FFITrimPath();
DashPathEffect makeDashPathEffect() => FFIDashPath();

const int _scratchSize = 1024;
final Pointer<Uint8> _scratchBuffer = calloc.allocate<Uint8>(_scratchSize);

class FFIRenderImage extends RenderImage
    implements RiveFFIReference, Finalizable {
  static final _finalizer = NativeFinalizer(_deleteRenderImageNative);
  Pointer<Void> _pointer;
  @override
  Pointer<Void> get pointer => _pointer;

  FFIRenderImage(this._pointer) {
    _finalizer.attach(this, _pointer.cast(), detach: this);
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    _finalizer.detach(this);
    _deleteRenderImage(_pointer);
    _pointer = nullptr;
  }

  static Future<FFIRenderImage?> decode(
      FFIFactory riveFactory, Uint8List bytes) async {
    var pointer = malloc.allocate<Uint8>(bytes.length);
    for (int i = 0; i < bytes.length; i++) {
      pointer[i] = bytes[i];
    }

    // Pass the pointer in to a native method.
    var result = _decodeRenderImage(riveFactory.pointer, pointer, bytes.length);
    malloc.free(pointer);
    if (result == nullptr) {
      return null;
    }

    return FFIRenderImage(result);
  }

  @override
  int get width => _renderImageWidth(_pointer);

  @override
  int get height => _renderImageHeight(_pointer);
}

class FFIRenderPath extends BufferedRenderPath
    implements RiveFFIReference, Finalizable {
  static final _finalizer = NativeFinalizer(_deleteRenderPathNative);
  Pointer<Void> _renderPath = nullptr;

  final FFIFactory riveFactory;

  FFIRenderPath(this.riveFactory, bool initEmpty)
      : _renderPath =
            initEmpty ? _makeEmptyRenderPath(riveFactory.pointer) : nullptr {
    if (_renderPath != nullptr) {
      _finalizer.attach(this, _renderPath.cast(), detach: this);
    }
  }

  FFIRenderPath.fromPointer(this.riveFactory, this._renderPath) {
    _finalizer.attach(this, _renderPath.cast(), detach: this);
  }

  Pointer<Void> get renderPath {
    update();
    return _renderPath;
  }

  @override
  void appendCommands(int commandCount) =>
      _appendCommands(_scratchBuffer, commandCount);

  @override
  void updateRenderPath() {
    if (_renderPath == nullptr) {
      _renderPath = _makeRenderPath(riveFactory.pointer);
      _renderPathSetFillRule(_renderPath, _fillType.index);
      _finalizer.attach(this, _renderPath.cast(), detach: this);
    } else {
      _appendRenderPath(_renderPath);
    }
  }

  @override
  void reset() {
    resetBuffer();
    _rewindRenderPath(_renderPath);
  }

  @override
  void addPath(covariant FFIRenderPath path, Mat2D transform) {
    _nativeAddPath(
      _renderPath,
      path.renderPath,
      transform[0],
      transform[1],
      transform[2],
      transform[3],
      transform[4],
      transform[5],
    );
  }

  @override
  void addPathBackwards(covariant FFIRenderPath path, Mat2D transform) {
    _nativeAddPathBackwards(
      riveFactory.pointer,
      _renderPath,
      path.renderPath,
      transform[0],
      transform[1],
      transform[2],
      transform[3],
      transform[4],
      transform[5],
    );
  }

  @override
  void addRawPath(
    covariant RawPathFFI rawPath, {
    Mat2D? transform,
    bool forceClockwise = false,
  }) {
    if (transform == null) {
      _nativeAddRawPath(renderPath, rawPath.pointer);
      return;
    }
    if (!forceClockwise) {
      _nativeAddRawPathWithTransform(
        renderPath,
        rawPath.pointer,
        transform[0],
        transform[1],
        transform[2],
        transform[3],
        transform[4],
        transform[5],
      );
    } else {
      _nativeAddRawPathWithTransformClockwise(
        renderPath,
        rawPath.pointer,
        transform[0],
        transform[1],
        transform[2],
        transform[3],
        transform[4],
        transform[5],
      );
    }
  }

  @override
  Uint8List get scratchBuffer => _scratchBuffer.asTypedList(_scratchSize);

  @override
  void dispose() {
    if (_renderPath == nullptr) {
      return;
    }
    _finalizer.detach(this);
    _deleteRenderPath(renderPath);
    _renderPath = nullptr;
  }

  PathFillType _fillType = PathFillType.nonZero;
  @override
  PathFillType get fillType => _fillType;

  @override
  set fillType(PathFillType type) {
    if (type == _fillType) {
      return;
    }
    _fillType = type;

    _renderPathSetFillRule(_renderPath, _fillType.index);
  }

  @override
  Pointer<Void> get pointer {
    update();
    return _renderPath;
  }

  @override
  bool hitTest(Vec2D point, {Mat2D? transform, double hitRadius = 3}) {
    var actualTransform = transform ?? Mat2D.identity;
    update();
    return _renderPathHitTest(
      riveFactory.pointer,
      pointer,
      point.x,
      point.y,
      hitRadius,
      actualTransform[0],
      actualTransform[1],
      actualTransform[2],
      actualTransform[3],
      actualTransform[4],
      actualTransform[5],
    );
  }

  @override
  Segment2D? get isColinear {
    final floatBuffer = _scratchBuffer.cast<Float>();
    if (_renderPathColinearCheck(riveFactory.pointer, pointer, floatBuffer)) {
      return Segment2D(Vec2D.fromValues(floatBuffer[0], floatBuffer[1]),
          Vec2D.fromValues(floatBuffer[2], floatBuffer[3]));
    }
    return null;
  }

  @override
  AABB computePreciseBounds(Mat2D transform) {
    final floatBuffer = _scratchBuffer.cast<Float>();
    _renderPathPreciseBounds(
        riveFactory.pointer,
        pointer,
        transform[0],
        transform[1],
        transform[2],
        transform[3],
        transform[4],
        transform[5],
        floatBuffer);
    return AABB.fromLTRB(
        floatBuffer[0], floatBuffer[1], floatBuffer[2], floatBuffer[3]);
  }

  @override
  AABB computeBounds(Mat2D transform) {
    final floatBuffer = _scratchBuffer.cast<Float>();
    _renderPathBounds(riveFactory.pointer, pointer, transform[0], transform[1],
        transform[2], transform[3], transform[4], transform[5], floatBuffer);
    return AABB.fromLTRB(
        floatBuffer[0], floatBuffer[1], floatBuffer[2], floatBuffer[3]);
  }

  @override
  double computePreciseLength(Mat2D transform) {
    return _renderPathPreciseLength(riveFactory.pointer, pointer, transform[0],
        transform[1], transform[2], transform[3], transform[4], transform[5]);
  }

  @override
  bool get isClosed => _renderPathIsClosed(riveFactory.pointer, pointer);

  @override
  bool get hasBounds => _renderPathHasBounds(riveFactory.pointer, pointer);

  static int _verbBufferSize = 10;
  static Pointer<Uint8> _verbBuffer = calloc.allocate<Uint8>(_verbBufferSize);
  static Pointer<Float> _pointBuffer =
      calloc.allocate<Float>(_verbBufferSize * 4 * 3 * 2);

  Iterable<PathCommand> _commands() sync* {
    int count = _renderPathCopyBuffers(riveFactory.pointer, pointer,
        _verbBuffer, _verbBufferSize, _pointBuffer, _verbBufferSize * 3);

    // Negative means the buffers were too small, grow them.
    if (count < 0) {
      assert(_verbBufferSize < -count);
      _verbBufferSize = -count;
      calloc.free(_verbBuffer);
      _verbBuffer = calloc.allocate<Uint8>(_verbBufferSize);
      calloc.free(_pointBuffer);
      _pointBuffer = calloc.allocate<Float>(_verbBufferSize * 4 * 3 * 2);
      count = _renderPathCopyBuffers(riveFactory.pointer, pointer, _verbBuffer,
          _verbBufferSize, _pointBuffer, _verbBufferSize * 3);
      assert(count >= 0);
    }

    int pointIndex = 0;
    for (int i = 0; i < count; i++) {
      int verb = _verbBuffer[i];
      switch (verb) {
        case 0:
          Vec2D to = Vec2D.fromValues(
            _pointBuffer[pointIndex],
            _pointBuffer[pointIndex + 1],
          );
          pointIndex += 2;
          yield PathCommand.move(to);
          break;
        case 1:
          Vec2D from = Vec2D.fromValues(
            _pointBuffer[pointIndex - 2],
            _pointBuffer[pointIndex - 1],
          );
          Vec2D to = Vec2D.fromValues(
            _pointBuffer[pointIndex],
            _pointBuffer[pointIndex + 1],
          );
          pointIndex += 2;
          yield PathCommand.line(from, to);
          break;
        case 2:
          Vec2D from = Vec2D.fromValues(
            _pointBuffer[pointIndex - 2],
            _pointBuffer[pointIndex - 1],
          );
          Vec2D control = Vec2D.fromValues(
            _pointBuffer[pointIndex],
            _pointBuffer[pointIndex + 1],
          );
          Vec2D to = Vec2D.fromValues(
            _pointBuffer[pointIndex + 2],
            _pointBuffer[pointIndex + 3],
          );
          pointIndex += 4;
          yield PathCommand.quad(from, control, to);
          break;
        case 4:
          Vec2D from = Vec2D.fromValues(
            _pointBuffer[pointIndex - 2],
            _pointBuffer[pointIndex - 1],
          );
          Vec2D controlOut = Vec2D.fromValues(
            _pointBuffer[pointIndex],
            _pointBuffer[pointIndex + 1],
          );
          Vec2D controlIn = Vec2D.fromValues(
            _pointBuffer[pointIndex + 2],
            _pointBuffer[pointIndex + 3],
          );
          Vec2D to = Vec2D.fromValues(
            _pointBuffer[pointIndex + 4],
            _pointBuffer[pointIndex + 5],
          );
          pointIndex += 6;
          yield PathCommand.cubic(from, controlOut, controlIn, to);
          break;
        case 5:
          yield PathCommand.close();
        default:
          throw UnimplementedError('Unknown path command $verb');
      }
    }
  }

  @override
  Iterable<PathCommand> get commands => _commands();

  @override
  bool isClockwise(Mat2D transform) => _renderPathIsClockwise(
        riveFactory.pointer,
        pointer,
        transform.determinant,
      );
}

final Pointer<Void> Function(Pointer<Void>, int vertexCount)
    _makeVertexRenderBuffer = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>, Uint32)>>(
            'makeVertexRenderBuffer')
        .asFunction();
final Pointer<Void> Function(Pointer<Void>, int vertexCount)
    _makeIndexRenderBuffer = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>, Uint32)>>(
            'makeIndexRenderBuffer')
        .asFunction();
final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deleteRenderBufferNative =
    nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'deleteRenderBuffer');

final Pointer<Void> Function(Pointer<Void>) _mapRenderBuffer = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
        'mapRenderBuffer')
    .asFunction();

final void Function(Pointer<Void>) _unmapRenderBuffer = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>('unmapRenderBuffer')
    .asFunction();
final void Function(Pointer<Void>) _deleteRenderBuffer =
    _deleteRenderBufferNative.asFunction();

class FFIRenderBuffer extends RenderBuffer
    implements RiveFFIReference, Finalizable {
  static final _finalizer = NativeFinalizer(_deleteRenderBufferNative);
  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;

  @override
  final int elementCount;

  FFIRenderBuffer(this.elementCount, this._pointer) {
    _finalizer.attach(this, _pointer.cast(), detach: this);
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    _finalizer.detach(this);
    _deleteRenderBuffer(_pointer);
    _pointer = nullptr;
  }
}

class FFIVertexRenderBuffer extends FFIRenderBuffer
    implements VertexRenderBuffer {
  FFIVertexRenderBuffer(FFIFactory riveFactory, int elementCount)
      : super(elementCount,
            _makeVertexRenderBuffer(riveFactory.pointer, elementCount));

  Float32List? _nextVertices;

  void update() {
    var vertices = _nextVertices;
    if (vertices != null) {
      var data = _mapRenderBuffer(pointer).cast<Float>();
      var list = data.asTypedList(vertices.length);
      list.setRange(0, list.length, vertices);
      _unmapRenderBuffer(pointer);
      _nextVertices = null;
    }
  }

  @override
  void setVertices(Float32List vertices) {
    assert(vertices.length == elementCount * 2);
    _nextVertices = Float32List.fromList(vertices);
  }
}

class FFIIndexRenderBuffer extends FFIRenderBuffer
    implements IndexRenderBuffer {
  FFIIndexRenderBuffer(FFIFactory riveFactory, int elementCount)
      : super(elementCount,
            _makeIndexRenderBuffer(riveFactory.pointer, elementCount));

  Uint16List? _nextIndices;
  void update() {
    var indices = _nextIndices;
    if (indices != null) {
      var data = _mapRenderBuffer(pointer).cast<Uint16>();
      var list = data.asTypedList(indices.length);
      list.setRange(0, list.length, indices);
      _unmapRenderBuffer(pointer);
      _nextIndices = null;
    }
  }

  @override
  void setIndices(Uint16List indices) {
    assert(indices.length == elementCount);
    _nextIndices = indices;
  }
}

class FFIRiveRenderer extends Renderer implements RiveFFIReference {
  @override
  final rive.Factory riveFactory;

  @override
  Pointer<Void> pointer;
  FFIRiveRenderer(this.riveFactory) : pointer = _boundRenderer();

  @protected
  FFIRiveRenderer.fromPointer(this.pointer, this.riveFactory);

  @override
  void clipPath(covariant FFIRenderPath path) =>
      _clipPath(pointer, path.renderPath);

  @override
  void drawImage(covariant FFIRenderImage image, ui.BlendMode blendMode,
          double opacity) =>
      _drawImage(pointer, image.pointer, blendMode.index, opacity);

  @override
  void drawImageMesh(
      covariant FFIRenderImage image,
      covariant FFIVertexRenderBuffer vertices,
      covariant FFIVertexRenderBuffer uvs,
      covariant FFIIndexRenderBuffer indices,
      ui.BlendMode blendMode,
      double opacity) {
    vertices.update();
    uvs.update();
    indices.update();
    assert(vertices.elementCount == uvs.elementCount);
    _drawImageMesh(
        pointer,
        image.pointer,
        vertices.pointer,
        uvs.pointer,
        indices.pointer,
        vertices.elementCount,
        indices.elementCount,
        blendMode.index,
        opacity);
  }

  @override
  void drawPath(covariant FFIRenderPath path, covariant FFIRenderPaint paint) =>
      _drawPath(pointer, path.renderPath, paint.nativePaint);

  @override
  void drawText(covariant RenderTextFFI text,
          [covariant FFIRenderPaint? paint]) =>
      _rawTextRender(text.pointer, pointer, paint?.nativePaint ?? nullptr);

  @override
  void save() => _nativeSave(pointer);

  @override
  void restore() => _nativeRestore(pointer);

  @override
  void transform(Mat2D matrix) => _nativeTransform(
        pointer,
        matrix[0],
        matrix[1],
        matrix[2],
        matrix[3],
        matrix[4],
        matrix[5],
      );
}

class FFIRiveFactory extends FFIFactory {
  FFIRiveFactory._() : super(nullptr);

  @override
  Future<void> completedDecodingFile(bool success) async {}
  static final FFIRiveFactory _instance = FFIRiveFactory._();

  static FFIRiveFactory get instance => _instance;

  @override
  bool isValidRenderer(Renderer renderer) =>
      renderer is FFIRiveRenderer && renderer is! FlutterRendererFFI;
}

class FFIRenderPaint extends BufferedRenderPaint implements Finalizable {
  static final _finalizer = NativeFinalizer(_deleteRenderPaintNative);

  Pointer<Void> _nativePaint;
  Pointer<Void> get nativePaint {
    update();
    return _nativePaint;
  }

  final FFIFactory riveFactory;
  FFIRenderPaint(this.riveFactory)
      : _nativePaint = _makeRenderPaint(riveFactory.pointer) {
    _finalizer.attach(this, _nativePaint.cast(), detach: this);
  }

  @override
  Uint8List get scratchBuffer => _scratchBuffer.asTypedList(_scratchSize);

  @override
  void updatePaint(int dirty, int wroteStops) {
    _updatePaint(
      riveFactory.pointer,
      _nativePaint,
      dirty,
      _scratchBuffer,
      wroteStops,
    );
  }

  @override
  void dispose() {
    if (_nativePaint == nullptr) {
      return;
    }
    _deleteRenderPaint(_nativePaint);
    _nativePaint = nullptr;
    _finalizer.detach(this);
  }
}

dynamic getGpu() => _getGPU();

dynamic getQueue() => _getQueue();

class FFIPathMeasure extends PathMeasure
    implements RiveFFIReference, Finalizable {
  static final _finalizer = NativeFinalizer(_deletePathMeasureNative);
  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;

  FFIPathMeasure(FFIRenderPath path, double tolerance)
      : _pointer = _makePathMeasure(
            path.riveFactory.pointer, path.pointer, tolerance) {
    _finalizer.attach(this, _pointer.cast(), detach: this);
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    _finalizer.detach(this);
    _deletePathMeasure(_pointer);
    _pointer = nullptr;
  }

  @override
  (Vec2D, Vec2D) atDistance(double distance) {
    _pathMeasureAtDistance(_pointer, distance, _floatQueryBuffer);
    final pos = Vec2D.fromValues(_floatQueryBuffer[0], _floatQueryBuffer[1]);
    final tan = Vec2D.fromValues(_floatQueryBuffer[2], _floatQueryBuffer[3]);
    return (pos, tan);
  }

  @override
  (Vec2D, Vec2D, double) atPercentage(double percentage) {
    _pathMeasureAtPercentage(_pointer, percentage, _floatQueryBuffer);
    final pos = Vec2D.fromValues(_floatQueryBuffer[0], _floatQueryBuffer[1]);
    final tan = Vec2D.fromValues(_floatQueryBuffer[2], _floatQueryBuffer[3]);
    final distance = _floatQueryBuffer[4];
    return (pos, tan, distance);
  }

  @override
  double get length => _pathMeasureLength(_pointer);
}

PathMeasure makePathMeasure(RenderPath renderPath, double tolerance) =>
    FFIPathMeasure(renderPath as FFIRenderPath, tolerance);

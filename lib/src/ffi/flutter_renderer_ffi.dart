import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:rive_native/platform.dart';
import 'package:rive_native/utilities.dart';
import 'package:rive_native/src/buffered_render_path.dart';
import 'package:rive_native/src/ffi/dynamic_library_helper.dart';
import 'package:rive_native/src/ffi/rive_ffi.dart';
import 'package:rive_native/src/ffi/rive_renderer_ffi.dart';
import 'package:rive_native/src/paint_dirt.dart';
import 'package:rive_native/src/rive_renderer.dart';
import 'package:rive_native/src/rive.dart' as rive;

/// This is the codebase for the Flutter (Impeller/Skia) rendering layer that
/// ties into the native Rive runtime.
final DynamicLibrary nativeLib = DynamicLibraryHelper.nativeLib;

// Pointers to functions from Dart that allow a wrapper C++ Renderer to call
// back to Dart for painting with Flutter.
typedef DrawPathPointer
    = Pointer<NativeFunction<Void Function(Pointer<Void>, Uint64, Uint64)>>;
typedef DrawImagePointer = Pointer<
    NativeFunction<
        Void Function(Pointer<Void>, Uint64, Uint8 blendMode, Float opacity)>>;
typedef DrawMeshPointer = Pointer<
    NativeFunction<
        Void Function(
            Pointer<Void> renderer,
            Uint64 image,
            Uint64 vertexBuffer,
            Uint64 uvBuffer,
            Uint64 indexBuffer,
            Uint32 vertexCount,
            Uint32 indexCount,
            Uint8 blendMode,
            Float opacity)>>;
typedef UpdatePathPointer = Pointer<
    NativeFunction<
        Void Function(
            Uint64, Pointer<NativeVec2D>, Pointer<Uint8>, Size, Uint8)>>;
typedef UpdatePaintPointer
    = Pointer<NativeFunction<Void Function(Uint64, Pointer<Uint8>, Size)>>;
typedef ClipPathPointer
    = Pointer<NativeFunction<Void Function(Pointer<Void>, Uint64)>>;
typedef SavePointer = Pointer<NativeFunction<Void Function(Pointer<Void>)>>;
typedef RestorePointer = Pointer<NativeFunction<Void Function(Pointer<Void>)>>;
typedef TransformPointer = Pointer<
    NativeFunction<
        Void Function(
            Pointer<Void>, Float, Float, Float, Float, Float, Float)>>;
typedef UpdateIndexBuffer = Pointer<
    NativeFunction<Void Function(Uint64 renderBuffer, Pointer<Uint16>, Size)>>;
typedef UpdateVertexBuffer = Pointer<
    NativeFunction<
        Void Function(Uint64 renderBuffer, Pointer<NativeVec2D>, Size)>>;

typedef MakeImagePointer = Pointer<
    NativeFunction<Void Function(Pointer<Void>, Uint64, Pointer<Uint8>, Size)>>;
typedef DeleteImagePointer = Pointer<NativeFunction<Void Function(Uint64)>>;
typedef DeleteRendererPointer
    = Pointer<NativeFunction<Void Function(Pointer<Void>)>>;
typedef DeletePathPointer = Pointer<NativeFunction<Void Function(Uint64)>>;
typedef DeletePaintPointer = Pointer<NativeFunction<Void Function(Uint64)>>;
typedef DeleteVertexBufferPointer
    = Pointer<NativeFunction<Void Function(Uint64)>>;
typedef DeleteIndexBufferPointer
    = Pointer<NativeFunction<Void Function(Uint64)>>;

final void Function(
  MakeImagePointer makeImage,
  DeleteImagePointer deleteImage,
  DrawPathPointer drawPath,
  DrawImagePointer drawImage,
  DrawMeshPointer drawMesh,
  UpdatePathPointer updatePath,
  ClipPathPointer clipPath,
  SavePointer save,
  RestorePointer restore,
  TransformPointer transform,
  UpdatePaintPointer updatePaint,
  UpdateIndexBuffer updateIndexBuffer,
  UpdateVertexBuffer updateVertexBuffer,
  DeletePathPointer deletePath,
  DeletePaintPointer deletePaint,
  DeleteVertexBufferPointer deleteVertexBuffer,
  DeleteIndexBufferPointer deleteIndexBuffer,
  DeleteRendererPointer deleteRenderer,
) _initFactoryCallbacks = nativeLib
    .lookup<
        NativeFunction<
            Void Function(
              MakeImagePointer,
              DeleteImagePointer,
              DrawPathPointer,
              DrawImagePointer,
              DrawMeshPointer,
              UpdatePathPointer,
              ClipPathPointer,
              SavePointer,
              RestorePointer,
              TransformPointer,
              UpdatePaintPointer,
              UpdateIndexBuffer,
              UpdateVertexBuffer,
              DeletePathPointer,
              DeletePaintPointer,
              DeleteVertexBufferPointer,
              DeleteIndexBufferPointer,
              DeleteRendererPointer,
            )>>('initFactoryCallbacks')
    .asFunction();

final Pointer<Void> Function() _processScheduledDeletions = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function()>>(
        'processScheduledDeletions')
    .asFunction();

final Pointer<Void> Function() _makeFlutterFactory = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function()>>('makeFlutterFactory')
    .asFunction();
final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deleteFlutterFactoryNative =
    nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'deleteFlutterFactory');
final void Function(Pointer<Void>, int, int) _renderImageSetSize = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Uint32, Uint32)>>(
        'renderImageSetSize')
    .asFunction();

final Pointer<Void> Function() _makeFlutterRenderImage = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function()>>('makeFlutterRenderImage')
    .asFunction();
final int Function(Pointer<Void>) _flutterRenderImageId = nativeLib
    .lookup<NativeFunction<Uint64 Function(Pointer<Void>)>>(
        'flutterRenderImageId')
    .asFunction();

class FFIFlutterFactoryImage {
  ui.Image? image;
  final Completer<RenderImage?>? completer;
  FFIFlutterFactoryImage() : completer = Completer();
}

/// The Factory For the Flutter Renderer.
class FFIFlutterFactory extends FFIFactory implements Finalizable {
  static final _finalizer = NativeFinalizer(_deleteFlutterFactoryNative);

  static final List<FFIFlutterFactoryImage> _loadingImages = [];
  static final images = HashMap<int, FFIFlutterFactoryImage>();

  static final _pathLookup = HashMap<int, ui.Path>();
  static final _paintLookup = HashMap<int, ui.Paint>();
  static final _canvasLookup = HashMap<int, WeakReference<ui.Canvas>>();
  static final _vertexBufferLookup = HashMap<int, List<ui.Offset>>();
  static final _indexBufferLookup = HashMap<int, Uint16List>();
  static get canvasLookup => _canvasLookup;

  static Timer? _deleteTimer;
  FFIFlutterFactory._() : super(_makeFlutterFactory()) {
    if (!Platform.instance.isTesting) {
      _deleteTimer?.cancel();
      _deleteTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        _processScheduledDeletions();
      });
    }
    _finalizer.attach(this, pointer.cast(), detach: this);

    _initFactoryCallbacks(
      Pointer.fromFunction(_decodeImageFromNative),
      Pointer.fromFunction(_deleteImage),
      Pointer.fromFunction(_drawNativePath),
      Pointer.fromFunction(_drawNativeImage),
      Pointer.fromFunction(_drawNativeMesh),
      Pointer.fromFunction(_updateNativePath),
      Pointer.fromFunction(_clipNativePath),
      Pointer.fromFunction(_saveNative),
      Pointer.fromFunction(_restoreNative),
      Pointer.fromFunction(_transformNative),
      Pointer.fromFunction(_updateNativePaint),
      Pointer.fromFunction(_updateIndexBuffer),
      Pointer.fromFunction(_updateVertexBuffer),
      Pointer.fromFunction(_deleteRenderPath),
      Pointer.fromFunction(_deleteRenderPaint),
      Pointer.fromFunction(_deleteVertexBuffer),
      Pointer.fromFunction(_deleteIndexBuffer),
      Pointer.fromFunction(_deleteRenderer),
    );
  }

  static void _deleteRenderer(Pointer<Void> renderer) {
    if (_canvasLookup[renderer.address]?.target == null) {
      _canvasLookup.remove(renderer.address);
    }
  }

  static void _deleteRenderPath(int path) {
    _pathLookup.remove(path);
  }

  static void _deleteRenderPaint(int paint) => _paintLookup.remove(paint);

  static void _deleteVertexBuffer(int buffer) =>
      _vertexBufferLookup.remove(buffer);

  static void _deleteIndexBuffer(int buffer) =>
      _indexBufferLookup.remove(buffer);

  static void _drawNativeMesh(
      Pointer<Void> renderer,
      int renderImage,
      int vertices,
      int uvs,
      int indices,
      int vertexCount,
      int indexCount,
      int blendModeValue,
      double opacity) {
    var image = FFIFlutterFactory.images[renderImage];
    var vertexBuffer = _vertexBufferLookup[vertices];
    var uvBuffer = _vertexBufferLookup[uvs];
    var indexBuffer = _indexBufferLookup[indices];

    if (vertexBuffer == null || uvBuffer == null || indexBuffer == null) {
      return;
    }
    var drawVertices = ui.Vertices(
      ui.VertexMode.triangles,
      vertexBuffer,
      textureCoordinates: uvBuffer,
      indices: indexBuffer,
    );
    var uiCanvas = _canvasLookup[renderer.address]?.target;
    var uiImage = image?.image;
    if (uiImage != null && uiCanvas != null) {
      uiCanvas.drawVertices(
        drawVertices,
        ui.BlendMode.srcOver,
        ui.Paint()
          ..blendMode = ui.BlendMode.values[blendModeValue]
          ..color = ui.Color.fromRGBO(255, 255, 255, opacity)
          ..filterQuality = ui.FilterQuality.high
          ..shader = ui.ImageShader(
            uiImage,
            ui.TileMode.clamp,
            ui.TileMode.clamp,
            Float64List.fromList(
              <double>[
                1 / uiImage.width,
                0.0,
                0.0,
                0.0,
                0.0,
                1 / uiImage.height,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0,
              ],
            ),
          ),
      );
    }
  }

  static void _updateVertexBuffer(
      int renderBuffer, Pointer<NativeVec2D> vertices, int size) {
    List<ui.Offset> uiVertexBuffer = List.filled(
      size,
      ui.Offset.zero,
    );
    for (int i = 0; i < size; i++) {
      var vec = vertices.ref;
      uiVertexBuffer[i] = vec.asOffset();
      vertices++;
    }
    _vertexBufferLookup[renderBuffer] = uiVertexBuffer;
  }

  static void _updateIndexBuffer(
      int renderBuffer, Pointer<Uint16> indices, int size) {
    Uint16List uiIndexBuffer = indices.asTypedList(size);
    _indexBufferLookup[renderBuffer] = uiIndexBuffer;
  }

  static void _drawNativeImage(Pointer<Void> renderer, int renderImage,
      int blendModeValue, double opacity) {
    var image = FFIFlutterFactory.images[renderImage];

    var uiCanvas = _canvasLookup[renderer.address]?.target;
    var uiImage = image?.image;

    if (uiImage != null && uiCanvas != null) {
      uiCanvas.drawImage(
        uiImage,
        ui.Offset.zero,
        ui.Paint()
          ..blendMode = ui.BlendMode.values[blendModeValue]
          ..filterQuality = ui.FilterQuality.high
          ..color = ui.Color.fromRGBO(255, 255, 255, opacity),
      );
    }
  }

  static void _drawNativePath(Pointer<Void> renderer, int path, int paint) {
    var uiPath = _pathLookup[path];
    var uiPaint = _paintLookup[paint];
    var uiCanvas = _canvasLookup[renderer.address]?.target;

    // Assert in debug mode so we can detect if this issue regresses:
    // https://github.com/rive-app/rive/pull/7637
    assert(uiPath != null && uiCanvas != null && uiPaint != null);

    if (uiPath != null && uiCanvas != null && uiPaint != null) {
      uiCanvas.drawPath(uiPath, uiPaint);
    }
  }

  static void _clipNativePath(Pointer<Void> renderer, int path) {
    var uiPath = _pathLookup[path];
    var uiCanvas = _canvasLookup[renderer.address]?.target;
    if (uiPath != null && uiCanvas != null) {
      uiCanvas.clipPath(uiPath);
    }
  }

  static void _saveNative(Pointer<Void> renderer) {
    var uiCanvas = _canvasLookup[renderer.address]?.target;
    uiCanvas?.save();
  }

  static void _restoreNative(Pointer<Void> renderer) {
    var uiCanvas = _canvasLookup[renderer.address]?.target;
    uiCanvas?.restore();
  }

  static void _transformNative(Pointer<Void> renderer, double xx, double xy,
      double yx, double yy, double tx, double ty) {
    var uiCanvas = _canvasLookup[renderer.address]?.target;
    uiCanvas?.transform(
      Float64List.fromList(
        [
          xx,
          xy,
          0.0,
          0.0,
          yx,
          yy,
          0.0,
          0.0,
          0.0,
          0.0,
          1.0,
          0.0,
          tx,
          ty,
          0.0,
          1.0,
        ],
      ),
    );
  }

  static void _updateNativePaint(int paint, Pointer<Uint8> data, int size) {
    var uiPaint = _paintLookup[paint];
    if (uiPaint == null) {
      _paintLookup[paint] = uiPaint = ui.Paint();
    }
    var reader = BinaryReader.fromList(data.asTypedList(size));
    var dirt = reader.readUint16();
    if ((dirt & PaintDirtFromNative.style) != 0) {
      uiPaint.style = reader.readUint8() == 0
          ? ui.PaintingStyle.stroke
          : ui.PaintingStyle.fill;
    }
    if ((dirt & PaintDirtFromNative.color) != 0) {
      uiPaint.color = ui.Color(reader.readUint32());
    }
    if ((dirt & PaintDirtFromNative.thickness) != 0) {
      uiPaint.strokeWidth = reader.readFloat32();
    }
    if ((dirt & PaintDirtFromNative.join) != 0) {
      uiPaint.strokeJoin = ui.StrokeJoin.values[reader.readUint8()];
    }
    if ((dirt & PaintDirtFromNative.cap) != 0) {
      uiPaint.strokeCap = ui.StrokeCap.values[reader.readUint8()];
    }
    if ((dirt & PaintDirtFromNative.blendMode) != 0) {
      uiPaint.blendMode = ui.BlendMode.values[reader.readUint8()];
    }

    if ((dirt & (PaintDirtFromNative.linear | PaintDirtFromNative.radial)) !=
        0) {
      var stopCount = reader.readUint32();
      List<double> stops = [];
      List<ui.Color> colors = [];
      for (int i = 0; i < stopCount; i++) {
        var stop = reader.readFloat32();
        var color = ui.Color(reader.readUint32());
        stops.add(stop);
        colors.add(color);
      }
      if ((dirt & PaintDirtFromNative.radial) != 0) {
        var centerX = reader.readFloat32();
        var centerY = reader.readFloat32();
        var radius = reader.readFloat32();
        uiPaint.shader = ui.Gradient.radial(
            ui.Offset(centerX, centerY), radius, colors, stops);
      } else {
        var sx = reader.readFloat32();
        var sy = reader.readFloat32();
        var ex = reader.readFloat32();
        var ey = reader.readFloat32();

        uiPaint.shader = ui.Gradient.linear(
          ui.Offset(sx, sy),
          ui.Offset(ex, ey),
          colors,
          stops,
        );
      }
    } else if ((dirt & PaintDirtFromNative.removeGradient) != 0) {
      uiPaint.shader = null;
    }
  }

  static void _updateNativePath(int path, Pointer<NativeVec2D> points,
      Pointer<Uint8> verbs, int count, int fillRule) {
    var uiPath = _pathLookup[path];
    if (uiPath == null) {
      _pathLookup[path] = uiPath = ui.Path();
    } else {
      uiPath.reset();
    }
    uiPath.fillType = fillRule < ui.PathFillType.values.length
        ? ui.PathFillType.values[fillRule]
        : ui.PathFillType.nonZero;
    for (int i = 0; i < count; i++) {
      var verb = (verbs + i).value;
      switch (verb) {
        case PrivatePathVerb.move:
          var pt0 = points.ref;
          uiPath.moveTo(pt0.x, pt0.y);
          break;
        case PrivatePathVerb.line:
          var pt1 = (points).ref;
          uiPath.lineTo(pt1.x, pt1.y);
          break;
        case PrivatePathVerb.quad:
          var pt1 = (points + 0).ref;
          var pt2 = (points + 1).ref;
          uiPath.quadraticBezierTo(pt1.x, pt1.y, pt2.x, pt2.y);
          break;
        case PrivatePathVerb.cubic:
          var pt1 = (points + 0).ref;
          var pt2 = (points + 1).ref;
          var pt3 = (points + 2).ref;
          uiPath.cubicTo(pt1.x, pt1.y, pt2.x, pt2.y, pt3.x, pt3.y);
          break;
        case PrivatePathVerb.close:
          uiPath.close();
          break;
      }
      points += PrivatePathVerb.pointCount(verb);
    }
  }

  @override
  Future<void> completedDecodingFile(bool success) async {
    if (success) {
      // these images belong to the RiveFile loaded, so wait for them to load before
      // completing the load.
      var loading = List<FFIFlutterFactoryImage>.from(_loadingImages);
      _loadingImages.clear();
      for (final image in loading) {
        var completer = image.completer;
        if (completer != null) {
          await completer.future;
        }
      }
    }
  }

  static void _deleteImage(int image) {
    images.remove(image);
  }

  @override
  Future<RenderImage?> decodeImage(Uint8List bytes) {
    final image = _makeFlutterRenderImage();
    var flutterImage = FFIFlutterFactoryImage();
    FFIFlutterFactory._loadingImages.add(flutterImage);
    images[_flutterRenderImageId(image)] = flutterImage;
    ui.decodeImageFromList(
      bytes,
      (uiImage) {
        flutterImage.image = uiImage;
        _renderImageSetSize(image, uiImage.width, uiImage.height);
        flutterImage.completer?.complete(FFIRenderImage(image));
      },
    );
    return flutterImage.completer!.future;
  }

  static void _decodeImageFromNative(
      Pointer<Void> image, int id, Pointer<Uint8> bytes, int size) {
    var flutterImage = FFIFlutterFactoryImage();
    FFIFlutterFactory._loadingImages.add(flutterImage);
    images[id] = flutterImage;

    // Copy it as the Flutter decoder is async.
    var bytesList = Uint8List.fromList(bytes.asTypedList(size));

    ui.decodeImageFromList(
      bytesList,
      (uiImage) {
        flutterImage.image = uiImage;
        _renderImageSetSize(image, uiImage.width, uiImage.height);
        flutterImage.completer?.complete(null);
      },
    );
  }

  static final FFIFlutterFactory _instance = FFIFlutterFactory._();

  static FFIFlutterFactory get instance => _instance;

  @override
  bool isValidRenderer(Renderer renderer) => renderer is FlutterRendererFFI;
}

final Pointer<Void> Function() _makeFlutterRenderer = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function()>>('makeFlutterRenderer')
    .asFunction();
final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deleteFlutterRendererNative =
    nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'deleteFlutterRenderer');
final void Function(Pointer<Void>) _deleteFlutterRenderer =
    _deleteFlutterRendererNative.asFunction();

class FlutterRendererFFI extends FFIRiveRenderer
    implements Finalizable, FlutterRenderer {
  @override
  final ui.Canvas canvas;
  static final _finalizer = NativeFinalizer(_deleteFlutterRendererNative);

  FlutterRendererFFI(this.canvas)
      : super.fromPointer(
          _makeFlutterRenderer(),
          rive.Factory.flutter,
        ) {
    FFIFlutterFactory.canvasLookup[pointer.address] = WeakReference(canvas);
    _finalizer.attach(this, pointer.cast(), detach: this);
  }

  @override
  void dispose() {
    if (pointer == nullptr) {
      return;
    }
    _finalizer.detach(this);
    _deleteFlutterRenderer(pointer);
    pointer = nullptr;
  }
}

Renderer makeFlutterRenderer(ui.Canvas canvas) => FlutterRendererFFI(canvas);

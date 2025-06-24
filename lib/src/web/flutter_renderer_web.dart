import 'dart:js_interop' as js;
import 'dart:async';
import 'dart:js_interop';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:collection';

import 'package:rive_native/utilities.dart';
import 'package:rive_native/src/buffered_render_path.dart';
import 'package:rive_native/src/rive_native_web.dart';
import 'package:rive_native/src/paint_dirt.dart';
import 'package:rive_native/src/rive_renderer.dart';
import 'package:rive_native/src/web/rive_renderer_web.dart';
import 'package:rive_native/src/web/rive_web.dart';
import 'package:rive_native/src/rive.dart' as rive;

class FlutterRendererWeb extends WebRiveRenderer implements FlutterRenderer {
  @override
  final ui.Canvas canvas;

  FlutterRendererWeb(this.canvas)
      : super(RiveWasm.makeFlutterRenderer.callAsFunction(),
            rive.Factory.flutter) {
    if (jsRendererPtr is js.JSNumber) {
      WebFlutterFactory.canvasLookup[(jsRendererPtr as js.JSNumber).toDartInt] =
          WeakReference(canvas);
    }
  }

  @override
  void dispose() {
    RiveWasm.deleteFlutterRenderer.callAsFunction(null, jsRendererPtr);
    jsRendererPtr = null;
  }
}

class WebFlutterFactoryImage {
  ui.Image? image;
  final Completer<RenderImage?>? completer;
  WebFlutterFactoryImage() : completer = Completer();
}

class WebFlutterFactory extends WebFactory {
  static final _finalizer = Finalizer<js.JSAny>(
    (ptr) => RiveWasm.deleteFlutterFactory.callAsFunction(
      null,
      ptr,
    ),
  );

  WebFlutterFactory._()
      : super(RiveWasm.makeFlutterFactory.callAsFunction() as js.JSAny) {
    RiveWasm.initFactoryCallbacks.callAsFunctionEx(
      null,
      _decodeRenderImageFromNative.toJS,
      _deleteRenderImage.toJS,
      _drawRenderPath.toJS,
      _drawRenderImage.toJS,
      _drawMesh.toJS,
      _updateRenderPath.toJS,
      _clipRenderPath.toJS,
      _save.toJS,
      _restore.toJS,
      _transform.toJS,
      _updateRenderPaint.toJS,
      _updateIndexBuffer.toJS,
      _updateVertexBuffer.toJS,
      _deleteRenderPath.toJS,
      _deleteRenderPaint.toJS,
      _deleteVertexBuffer.toJS,
      _deleteIndexBuffer.toJS,
      _deleteRenderer.toJS,
    );
    _finalizer.attach(this, pointer, detach: this);
  }

  static final _pathLookup = HashMap<js.JSBigInt, ui.Path>();
  static final _paintLookup = HashMap<js.JSBigInt, ui.Paint>();
  static final _canvasLookup = HashMap<int, WeakReference<ui.Canvas>>();
  static final _vertexBufferLookup = HashMap<js.JSBigInt, List<ui.Offset>>();
  static final _indexBufferLookup = HashMap<js.JSBigInt, Uint16List>();
  static get canvasLookup => _canvasLookup;

  static final List<WebFlutterFactoryImage> _loadingImages = [];
  static final images = HashMap<js.JSBigInt, WebFlutterFactoryImage>();

  @override
  Future<RenderImage?> decodeImage(Uint8List bytes) {
    final image = RiveWasm.makeFlutterRenderImage.callAsFunction(null);
    final imagePtr = (image as js.JSNumber).toDartInt;
    var flutterImage = WebFlutterFactoryImage();
    WebFlutterFactory._loadingImages.add(flutterImage);
    var id = RiveWasm.flutterRenderImageId.callAsFunction(null, image)
        as js.JSBigInt;
    images[id] = flutterImage;
    ui.decodeImageFromList(
      bytes,
      (uiImage) {
        flutterImage.image = uiImage;
        RiveWasm.renderImageSetSize.callAsFunction(
          null,
          imagePtr.toJS,
          uiImage.width.toJS,
          uiImage.height.toJS,
        );
        flutterImage.completer?.complete(WebRenderImage(image));
      },
    );
    return flutterImage.completer!.future;
  }

  static void _decodeRenderImageFromNative(
      int imagePtr, js.JSBigInt id, int dataPtr, int dataSize) {
    var flutterImage = WebFlutterFactoryImage();
    WebFlutterFactory._loadingImages.add(flutterImage);
    images[id] = flutterImage;
    var bytesList = Uint8List.fromList(RiveWasm.heap(dataPtr, dataSize));
    ui.decodeImageFromList(
      bytesList,
      (image) {
        RiveWasm.renderImageSetSize.callAsFunction(
          null,
          imagePtr.toJS,
          image.width.toJS,
          image.height.toJS,
        );
        flutterImage.image = image;
        flutterImage.completer?.complete();
      },
    );
  }

  static void _deleteRenderImage(js.JSBigInt imageId) {
    images.remove(imageId);
  }

  static void _drawRenderPath(
      int rendererPtr, js.JSBigInt pathId, js.JSBigInt paintId) {
    var uiPath = _pathLookup[pathId];
    var uiPaint = _paintLookup[paintId];
    var uiCanvas = _canvasLookup[rendererPtr]?.target;
    if (uiPath != null && uiCanvas != null && uiPaint != null) {
      uiCanvas.drawPath(uiPath, uiPaint);
    }
  }

  static void _drawRenderImage(int rendererPtr, js.JSBigInt imageId,
      int blendModeValue, double opacity) {
    var image = WebFlutterFactory.images[imageId];

    var uiCanvas = _canvasLookup[rendererPtr]?.target;
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

  static void _drawMesh(
      int rendererPtr,
      js.JSBigInt imagePtr,
      js.JSBigInt vertexBufferPtr,
      js.JSBigInt uvBufferPtr,
      js.JSBigInt indexBufferPtr,
      int vertexCount,
      int indexCount,
      int blendModeValue,
      double opacity) {
    var image = WebFlutterFactory.images[imagePtr];
    var vertexBuffer = _vertexBufferLookup[vertexBufferPtr];
    var uvBuffer = _vertexBufferLookup[uvBufferPtr];
    var indexBuffer = _indexBufferLookup[indexBufferPtr];

    if (vertexBuffer == null || uvBuffer == null || indexBuffer == null) {
      return;
    }
    var drawVertices = ui.Vertices(
      ui.VertexMode.triangles,
      vertexBuffer,
      textureCoordinates: uvBuffer,
      indices: indexBuffer,
    );
    var uiCanvas = _canvasLookup[rendererPtr]?.target;
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

  static void _updateRenderPath(js.JSBigInt pathId, int pointsPtr, int verbsPtr,
      int count, int fillRule) {
    var heapView = RiveWasm.heapView();
    var verbs = RiveWasm.heap(verbsPtr, count);
    var uiPath = _pathLookup[pathId];
    if (uiPath == null) {
      _pathLookup[pathId] = uiPath = ui.Path();
    } else {
      uiPath.reset();
    }
    uiPath.fillType = fillRule < ui.PathFillType.values.length
        ? ui.PathFillType.values[fillRule]
        : ui.PathFillType.nonZero;
    (double x, double y) pointAt(int ptr) {
      var x = heapView.getFloat32(ptr, Endian.little);
      var y = heapView.getFloat32(ptr + 4, Endian.little);
      return (x, y);
    }

    for (final verb in verbs) {
      switch (verb) {
        case PrivatePathVerb.move:
          var (x, y) = pointAt(pointsPtr);
          uiPath.moveTo(x, y);
          break;
        case PrivatePathVerb.line:
          var (x, y) = pointAt(pointsPtr);
          uiPath.lineTo(x, y);
          break;
        case PrivatePathVerb.quad:
          var (x1, y1) = pointAt(pointsPtr);
          var (x2, y2) = pointAt(pointsPtr + 8);
          uiPath.quadraticBezierTo(x1, y1, x2, y2);
          break;
        case PrivatePathVerb.cubic:
          var (x1, y1) = pointAt(pointsPtr);
          var (x2, y2) = pointAt(pointsPtr + 8);
          var (x3, y3) = pointAt(pointsPtr + 16);
          uiPath.cubicTo(x1, y1, x2, y2, x3, y3);
          break;
        case PrivatePathVerb.close:
          uiPath.close();
          break;
      }
      pointsPtr += PrivatePathVerb.pointCount(verb) * 8;
    }
  }

  static void _clipRenderPath(int rendererPtr, js.JSBigInt pathId) {
    var uiPath = _pathLookup[pathId];
    var uiCanvas = _canvasLookup[rendererPtr]?.target;
    if (uiPath != null && uiCanvas != null) {
      uiCanvas.clipPath(uiPath);
    }
  }

  static void _save(int rendererPtr) {
    var uiCanvas = _canvasLookup[rendererPtr]?.target;
    uiCanvas?.save();
  }

  static void _restore(int rendererPtr) {
    var uiCanvas = _canvasLookup[rendererPtr]?.target;
    uiCanvas?.restore();
  }

  static void _transform(int rendererPtr, double xx, double xy, double yx,
      double yy, double tx, double ty) {
    var uiCanvas = _canvasLookup[rendererPtr]?.target;
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

  static void _updateRenderPaint(
      js.JSBigInt paintId, int dataPtr, int dataSize) {
    var uiPaint = _paintLookup[paintId];
    if (uiPaint == null) {
      _paintLookup[paintId] = uiPaint = ui.Paint();
    }

    var reader = BinaryReader.fromList(RiveWasm.heap(dataPtr, dataSize));
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

  static void _updateIndexBuffer(
      js.JSBigInt indexBufferId, int dataPtr, int indicesSize) {
    var heap = RiveWasm.heap(dataPtr, indicesSize * 2);
    Uint16List uiIndexBuffer = Uint16List.fromList(
      Uint16List.view(heap.buffer, heap.offsetInBytes, indicesSize),
    );

    _indexBufferLookup[indexBufferId] = uiIndexBuffer;
  }

  static void _updateVertexBuffer(
      js.JSBigInt vertexBufferId, int dataPtr, int verticesSize) {
    List<ui.Offset> uiVertexBuffer = List.filled(
      verticesSize,
      ui.Offset.zero,
    );

    var heap = RiveWasm.heap(dataPtr, verticesSize * 8);
    Float32List vertices =
        Float32List.view(heap.buffer, heap.offsetInBytes, verticesSize * 2);

    int index = 0;
    for (int i = 0; i < verticesSize; i++) {
      var x = vertices[index++];
      var y = vertices[index++];
      uiVertexBuffer[i] = ui.Offset(x, y);
    }
    _vertexBufferLookup[vertexBufferId] = uiVertexBuffer;
  }

  static void _deleteRenderPath(js.JSBigInt pathId) =>
      _pathLookup.remove(pathId);
  static void _deleteRenderPaint(js.JSBigInt paintId) =>
      _paintLookup.remove(paintId);
  static void _deleteVertexBuffer(js.JSBigInt bufferId) =>
      _vertexBufferLookup.remove(bufferId);
  static void _deleteIndexBuffer(js.JSBigInt bufferId) =>
      _indexBufferLookup.remove(bufferId);

  static void _deleteRenderer(int renderer) {
    if (_canvasLookup[renderer]?.target == null) {
      _canvasLookup.remove(renderer);
    }
  }

  @override
  Future<void> completedDecodingFile(bool success) async {
    if (success) {
      // these images belong to the RiveFile loaded, so wait for them to load before
      // completing the load.
      var loading = List<WebFlutterFactoryImage>.from(_loadingImages);
      _loadingImages.clear();
      for (final image in loading) {
        var completer = image.completer;
        if (completer != null) {
          await completer.future;
        }
      }
    }
  }

  static final WebFlutterFactory _instance = WebFlutterFactory._();

  static WebFlutterFactory get instance => _instance;

  @override
  bool isValidRenderer(Renderer renderer) => renderer is FlutterRendererWeb;
}

Renderer makeFlutterRenderer(ui.Canvas canvas) => FlutterRendererWeb(canvas);

dynamic getGpu() => UnsupportedError('No direct access to gpu on web.');

dynamic getQueue() =>
    UnsupportedError('No direct access to render queue on web.');

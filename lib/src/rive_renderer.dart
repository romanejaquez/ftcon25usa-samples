import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' as flutter;
import 'package:rive_native/rive_text.dart' as common;
import 'package:rive_native/rive_native.dart';
import 'package:rive_native/rive_text.dart';
import '../src/ffi/rive_renderer_ffi.dart'
    if (dart.library.js_interop) '../src/web/rive_renderer_web.dart';
import '../src/ffi/flutter_renderer_ffi.dart'
    if (dart.library.js_interop) '../src/web/flutter_renderer_web.dart';

enum PaintingStyle {
  stroke,
  fill,
}

enum PathFillType { nonZero, evenOdd, clockWise }

abstract class RenderGradient {
  final Vec2D start;
  final List<ui.Color> colors;
  final List<double> stops;

  RenderGradient(this.start, this.colors, this.stops);
}

class RenderRadialGradient extends RenderGradient {
  final double radius;
  RenderRadialGradient(super.start, this.radius, super.colors, super.stops);
}

class RenderLinearGradient extends RenderGradient {
  final Vec2D end;
  RenderLinearGradient(super.start, this.end, super.colors, super.stops);
}

abstract class RenderPaint {
  ui.Color get color;
  set color(ui.Color value);

  PaintingStyle get style;
  set style(PaintingStyle value);

  double get thickness;
  set thickness(double value);

  ui.StrokeJoin get join;
  set join(ui.StrokeJoin value);

  ui.StrokeCap get cap;
  set cap(ui.StrokeCap value);

  ui.BlendMode get blendMode;
  set blendMode(ui.BlendMode value);

  RenderGradient? get gradient;
  set gradient(RenderGradient? gradient);

  void dispose();

  bool get isAntiAlias;
  set isAntiAlias(bool value);

  double get feather;
  set feather(double value);
}

enum TrimPathMode { none, sequential, synchronized }

abstract class TrimPathEffect {
  double get offset;
  set offset(double value);

  double get start;
  set start(double value);

  double get end;
  set end(double value);

  TrimPathMode get mode;
  set mode(TrimPathMode value);

  void invalidate();
  void dispose();

  RenderPath effectPath(RenderPath path);
}

abstract class DashPathEffect {
  double get offset;
  set offset(double value);

  bool get offsetIsPercentage;
  set offsetIsPercentage(bool value);

  void clearDashArray();
  void addToDashArray(double value, bool percentage);
  void dispose();
  void invalidate();
  RenderPath effectPath(RenderPath path);

  double get pathLength;
}

enum PathVerb { move, line, quad, cubic, close }

class PathCommand {
  final PathVerb verb;
  final List<Vec2D> points;

  PathCommand(this.verb, {required this.points});

  factory PathCommand.move(Vec2D to) =>
      PathCommand(PathVerb.move, points: List.unmodifiable([to]));

  factory PathCommand.line(Vec2D from, Vec2D to) =>
      PathCommand(PathVerb.line, points: List.unmodifiable([from, to]));

  factory PathCommand.quad(Vec2D from, Vec2D control, Vec2D to) =>
      PathCommand(PathVerb.quad,
          points: List.unmodifiable([from, control, to]));

  factory PathCommand.cubic(
          Vec2D from, Vec2D controlOut, Vec2D controlIn, Vec2D to) =>
      PathCommand(PathVerb.cubic,
          points: List.unmodifiable([from, controlOut, controlIn, to]));

  factory PathCommand.close() =>
      PathCommand(PathVerb.close, points: List.unmodifiable([]));
}

abstract class RenderText {
  void append(
    String text, {
    required Font font,
    RenderPaint? paint,
    double size = 16,
    double lineHeight = -1,
    double letterSpacing = 0,
  });

  void clear();

  TextSizing get sizing;
  TextOverflow get overflow;
  TextAlign get align;
  double get maxWidth;
  double get maxHeight;
  double get paragraphSpacing;

  set sizing(TextSizing value);
  set overflow(TextOverflow value);
  set align(TextAlign value);
  set maxWidth(double value);
  set maxHeight(double value);
  set paragraphSpacing(double value);

  /// Returns the bounds of the text object (helpful for aligning multiple
  /// text objects/procredurally drawn shapes).
  AABB get bounds;

  bool get isEmpty;

  void dispose();
}

abstract class RenderPath implements PathInterface {
  Iterable<PathCommand> get commands;
  AABB computePreciseBounds(Mat2D transform);
  AABB computeBounds(Mat2D transform);
  double computePreciseLength(Mat2D transform);

  // Returns null if the path is not colinear. Returns the line segment defined
  // by a start and an end point if it is colinear.
  Segment2D? get isColinear;

  bool get hasBounds;

  bool get isClosed;

  void reset();

  @override
  void moveTo(double x, double y);

  @override
  void lineTo(double x, double y);

  void quadTo(double cx, double cy, double x, double y);

  @override
  void cubicTo(double ox, double oy, double ix, double iy, double x, double y);

  @override
  void close();

  void move(Vec2D to) => moveTo(to.x, to.y);

  void line(Vec2D to) => lineTo(to.x, to.y);

  void quad(Vec2D control, Vec2D to) =>
      quadTo(control.x, control.y, to.x, to.y);

  void cubic(Vec2D control1, Vec2D control2, Vec2D to) =>
      cubicTo(control1.x, control1.y, control2.x, control2.y, to.x, to.y);

  void addPath(RenderPath path, Mat2D transform);

  void addPathBackwards(RenderPath path, Mat2D transform);

  void dispose();

  void addRect(ui.Rect rect) {
    moveTo(rect.left, rect.top);
    lineTo(rect.right, rect.top);
    lineTo(rect.right, rect.bottom);
    lineTo(rect.left, rect.bottom);
    close();
  }

  static const c = 0.5519150244935105707435627;
  static final List<Vec2D> unitCircle = [
    Vec2D.fromValues(1, 0),
    Vec2D.fromValues(1, c),
    Vec2D.fromValues(c, 1), // quadrant 1 ( 4:30)
    Vec2D.fromValues(0, 1),
    Vec2D.fromValues(-c, 1),
    Vec2D.fromValues(-1, c), // quadrant 2 ( 7:30)
    Vec2D.fromValues(-1, 0),
    Vec2D.fromValues(-1, -c),
    Vec2D.fromValues(-c, -1), // quadrant 3 (10:30)
    Vec2D.fromValues(0, -1),
    Vec2D.fromValues(c, -1),
    Vec2D.fromValues(1, -c), // quadrant 4 ( 1:30)
    Vec2D.fromValues(1, 0),
  ];

  void addOval(ui.Rect rect) {
    var center = rect.center;
    var dx = center.dx;
    var dy = center.dy;
    var sx = rect.width * 0.5;
    var sy = rect.height * 0.5;

    Vec2D map(Vec2D p) => Vec2D.fromValues(p.x * sx + dx, p.y * sy + dy);

    move(map(unitCircle[0]));
    for (int i = 1; i <= 12; i += 3) {
      cubic(map(unitCircle[i + 0]), map(unitCircle[i + 1]),
          map(unitCircle[i + 2]));
    }

    close();
  }

  void addArc(
      ui.Offset center, double radius, double startAngle, double sweepAngle) {
    double endAngle = startAngle + sweepAngle;

    // Subdivides an arc into multiple cubics. Arc segments are approximated:
    // https://pomax.github.io/bezierinfo/#circles_cubic
    moveTo(
      center.dx,
      center.dy,
    );
    lineTo(
      center.dx + radius * cos(startAngle),
      center.dy + radius * sin(startAngle),
    );
    if (startAngle != endAngle) {
      var segments = (sweepAngle / pi * 4).round() + 1;
      var step = (endAngle - startAngle) / segments;
      segments -= 1;

      for (int i = 0; i < segments; i++, startAngle += step) {
        _cubicArcSegment(center, radius, startAngle, startAngle + step);
      }

      _cubicArcSegment(center, radius, startAngle, endAngle);
    }
    close();
  }

  void _cubicArcSegment(
      ui.Offset center, double radius, double fromAngle, double toAngle) {
    var scaledSinFrom = radius * sin(fromAngle);
    var scaledCosFrom = radius * cos(fromAngle);
    var scaledSinTo = radius * sin(toAngle);
    var scaledCosTo = radius * cos(toAngle);

    // https://www.charlespetzold.com/blog/2012/12/Bezier-Circles-and-Bezier-Ellipses.html
    var h = 4.0 / 3.0 * tan((toAngle - fromAngle) / 4.0);

    cubicTo(
      center.dx + scaledCosFrom - h * scaledSinFrom,
      center.dy + scaledSinFrom + h * scaledCosFrom,
      center.dx + scaledCosTo + h * scaledSinTo,
      center.dy + scaledSinTo - h * scaledCosTo,
      center.dx + scaledCosTo,
      center.dy + scaledSinTo,
    );
  }

  void addRawPath(
    common.RawPath rawPath, {
    Mat2D? transform,
    bool forceClockwise = false,
  });

  PathFillType get fillType;
  set fillType(PathFillType fillType);

  bool hitTest(
    Vec2D point, {
    Mat2D? transform,
    double hitRadius = 3,
  });

  bool isClockwise(Mat2D transform);
}

abstract class RenderImage {
  void dispose();

  int get width;
  int get height;
}

abstract class RenderBuffer {
  int get elementCount;
  void dispose();
}

abstract class IndexRenderBuffer extends RenderBuffer {
  void setIndices(Uint16List indices);
}

abstract class VertexRenderBuffer extends RenderBuffer {
  void setVertices(Float32List vertices);
}

abstract class FlutterRenderer {
  flutter.Canvas get canvas;
}

enum Fit {
  /// Rive content will fill the available view. If the aspect ratios differ,
  /// then the Rive content will be stretched.
  fill,

  /// Rive content will be contained within the view, preserving the aspect
  /// ratio. If the ratios differ, then a portion of the view will be unused
  contain,

  /// Rive will cover the view, preserving the aspect ratio. If the Rive
  /// content has a different ratio to the view, then the Rive content will be
  /// clipped.
  cover,

  /// Rive content will fill to the width of the view. This may result in
  /// clipping or unfilled view space.
  fitWidth,

  /// Rive content will fill to the height of the view. This may result in
  /// clipping or unfilled view space.
  fitHeight,

  /// Rive content will render to the size of its artboard, which may result
  /// in clipping or unfilled view space.
  none,

  /// Rive content is scaled down to the size of the view, preserving the
  /// aspect ratio. This is equivalent to Contain when the content is larger
  /// than the canvas. If the canvas is larger, then ScaleDown will not scale
  /// up.
  scaleDown,

  /// Rive content will be resized automatically based on layout constraints of
  /// the artboard to match the underlying widget size.
  ///
  /// See: [Responsive Layout](https://rive.app/community/doc/layout/docBl81zd1GB#responsive-layout)
  layout,
}

abstract class Renderer {
  Factory get riveFactory;
  void drawPath(RenderPath path, RenderPaint paint);
  void drawImage(
      RenderImage image, flutter.BlendMode blendMode, double opacity);
  void drawImageMesh(
      RenderImage image,
      VertexRenderBuffer vertices,
      VertexRenderBuffer uvs,
      IndexRenderBuffer indices,
      flutter.BlendMode blendMode,
      double opacity);

  /// Draw a RenderText, supply [paint] to override styles provided during text
  /// building.
  void drawText(RenderText text, [RenderPaint? paint]);
  void clipPath(RenderPath path);
  void save();
  void restore();
  void transform(Mat2D matrix);

  void scale(double sx, [double? sy]) =>
      transform(Mat2D.fromScale(sx, sy ?? sx));

  void translate(double x, double y) => transform(Mat2D.fromTranslate(x, y));
  void rotate(double angle) => transform(Mat2D.fromRotation(Mat2D(), angle));

  /// Makes a Renderer for a Flutter Canvas.
  static Renderer make(flutter.Canvas canvas) => makeFlutterRenderer(canvas);

  static TrimPathEffect makeTrimPath() => makeTrimPathEffect();
  static DashPathEffect makeDashPath() => makeDashPathEffect();

  static dynamic get nativeGpu => getGpu();
  static dynamic get nativeQueue => getQueue();

  void align(Fit fit, flutter.Alignment alignment, AABB frame, AABB content,
          double scaleFactor) =>
      transform(computeAlignment(fit, alignment, frame, content, scaleFactor));

  static Mat2D computeAlignment(Fit fit, flutter.Alignment alignment,
      AABB frame, AABB content, double scaleFactor) {
    double contentWidth = content[2] - content[0];
    double contentHeight = content[3] - content[1];

    if (contentWidth == 0 || contentHeight == 0) {
      return Mat2D();
    }

    double x = -1 * content[0] -
        contentWidth / 2.0 -
        (alignment.x * contentWidth / 2.0);
    double y = -1 * content[1] -
        contentHeight / 2.0 -
        (alignment.y * contentHeight / 2.0);

    double scaleX = 1.0, scaleY = 1.0;

    switch (fit) {
      case Fit.fill:
        scaleX = frame.width / contentWidth;
        scaleY = frame.height / contentHeight;
        break;
      case Fit.contain:
        double minScale =
            min(frame.width / contentWidth, frame.height / contentHeight);
        scaleX = scaleY = minScale;
        break;
      case Fit.cover:
        double maxScale =
            max(frame.width / contentWidth, frame.height / contentHeight);
        scaleX = scaleY = maxScale;
        break;
      case Fit.fitHeight:
        double minScale = frame.height / contentHeight;
        scaleX = scaleY = minScale;
        break;
      case Fit.fitWidth:
        double minScale = frame.width / contentWidth;
        scaleX = scaleY = minScale;
        break;
      case Fit.none:
        scaleX = scaleY = 1.0;
        break;
      case Fit.scaleDown:
        double minScale =
            min(frame.width / contentWidth, frame.height / contentHeight);
        scaleX = scaleY = minScale < 1.0 ? minScale : 1.0;
        break;
      case Fit.layout:
        return Mat2D.fromScale(scaleFactor, scaleFactor);
    }

    Mat2D translation = Mat2D();

    translation[4] =
        frame[0] + frame.width / 2.0 + (alignment.x * frame.width / 2.0);
    translation[5] =
        frame[1] + frame.height / 2.0 + (alignment.y * frame.height / 2.0);

    return Mat2D.multiply(
        Mat2D(),
        Mat2D.multiply(Mat2D(), translation, Mat2D.fromScale(scaleX, scaleY)),
        Mat2D.fromTranslate(x, y));
  }

  // Helper drawing methods.
  void drawLine(flutter.Offset from, flutter.Offset to, RenderPaint paint) {
    drawPath(
      riveFactory.makePath()
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy),
      paint,
    );
  }

  void clipRect(flutter.Rect rect) {
    clipPath(
      riveFactory.makePath()
        ..addRect(
          rect,
        ),
    );
  }

  void drawRect(flutter.Rect rect, RenderPaint paint) {
    drawPath(
      riveFactory.makePath()
        ..addRect(
          rect,
        ),
      paint,
    );
  }

  void drawCircle(flutter.Offset center, double radius, RenderPaint paint) {
    drawPath(
      riveFactory.makePath()
        ..addOval(
          flutter.Rect.fromCircle(
            center: center,
            radius: radius,
          ),
        ),
      paint,
    );
  }

  void dispose() {}
}

abstract class PathMeasure {
  static const double kDefaultTolerance = 0.5;
  static PathMeasure make(RenderPath renderPath,
          {double tolerance = kDefaultTolerance}) =>
      makePathMeasure(renderPath, tolerance);
  double get length;

  (Vec2D pos, Vec2D tan) atDistance(double distance);
  (Vec2D pos, Vec2D tan, double distance) atPercentage(double percentage);

  void dispose();
}

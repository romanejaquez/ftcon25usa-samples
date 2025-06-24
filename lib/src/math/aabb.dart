import 'dart:math';
import 'dart:ui';
import 'package:rive_native/src/math/mat2d.dart';
import 'package:rive_native/src/math/vec2d.dart';

class IAABB {
  int left, top, right, bottom;

  IAABB(int l, int t, int r, int b)
      : left = l,
        top = t,
        right = r,
        bottom = b;

  IAABB.zero()
      : left = 0,
        top = 0,
        right = 0,
        bottom = 0;

  int get width => right - left;
  int get height => bottom - top;
  bool get empty => left >= right || top >= bottom;

  IAABB inset(int dx, int dy) =>
      IAABB(left + dx, top + dy, right - dx, bottom - dy);

  IAABB offset(int dx, int dy) =>
      IAABB(left + dx, top + dy, right + dx, bottom + dy);
}

class AABB {
  double left, top, right, bottom;

  Vec2D get topLeft => minimum;

  Vec2D get topCenter => Vec2D.fromValues(minimum.x + width / 2, minimum.y);
  Vec2D get bottomCenter => Vec2D.fromValues(minimum.x + width / 2, maximum.y);
  Vec2D get leftCenter => Vec2D.fromValues(minimum.x, minimum.y + height / 2);
  Vec2D get rightCenter => Vec2D.fromValues(maximum.x, minimum.y + height / 2);

  Vec2D get topRight {
    return Vec2D.fromValues(right, top);
  }

  Vec2D get bottomRight => maximum;

  Vec2D get bottomLeft {
    return Vec2D.fromValues(left, bottom);
  }

  Vec2D get minimum {
    return Vec2D.fromValues(left, top);
  }

  Vec2D get maximum {
    return Vec2D.fromValues(right, bottom);
  }

  double get minX => left;
  double get maxX => right;
  double get minY => top;
  double get maxY => bottom;

  double get centerX => (left + right) * 0.5;
  double get centerY => (top + bottom) * 0.5;

  AABB()
      : left = 0,
        top = 0,
        right = 0,
        bottom = 0;

  AABB.clone(AABB a)
      : left = a.left,
        top = a.top,
        right = a.right,
        bottom = a.bottom;

  AABB.fromValues(double l, double t, double r, double b)
      : left = l,
        top = t,
        right = r,
        bottom = b;

  AABB.fromLTRB(double l, double t, double r, double b)
      : this.fromValues(l, t, r, b);

  AABB.fromLTWH(double l, double t, double w, double h)
      : this.fromValues(l, t, l + w, t + h);

  @Deprecated('Use AABB.fromLTWH')
  AABB.fromCoordinates({
    required double x,
    required double y,
    required double width,
    required double height,
  })  : left = x,
        top = y,
        right = x + width,
        bottom = y + height;

  AABB.empty()
      : left = double.maxFinite,
        top = double.maxFinite,
        right = -double.maxFinite,
        bottom = -double.maxFinite;

  factory AABB.expand(AABB from, double amount) {
    var aabb = AABB.clone(from);
    if (aabb.width < amount) {
      aabb.left -= amount / 2;
      aabb.right += amount / 2;
    }
    if (aabb.height < amount) {
      aabb.top -= amount / 2;
      aabb.bottom += amount / 2;
    }
    return aabb;
  }

  factory AABB.pad(AABB from, double amount) {
    var aabb = AABB.clone(from);
    aabb.left -= amount;
    aabb.right += amount;
    aabb.top -= amount;
    aabb.bottom += amount;
    return aabb;
  }

  bool get isEmpty => !AABB.isValid(this);

  Vec2D includePoint(Vec2D point, Mat2D? transform) {
    var transformedPoint = transform == null ? point : transform * point;
    expandToPoint(transformedPoint);
    return transformedPoint;
  }

  AABB inset(double dx, double dy) {
    return AABB.fromValues(left + dx, top + dy, right - dx, bottom - dy);
  }

  AABB offset(double dx, double dy) {
    return AABB.fromValues(left + dx, top + dy, right + dx, bottom + dy);
  }

  void expandToPoint(Vec2D point) {
    var x = point.x;
    var y = point.y;
    if (x < left) {
      left = x;
    }
    if (x > right) {
      right = x;
    }
    if (y < top) {
      top = y;
    }
    if (y > bottom) {
      bottom = y;
    }
  }

  AABB.fromMinMax(Vec2D min, Vec2D max)
      : left = min.x,
        top = min.y,
        right = max.x,
        bottom = max.y;

  AABB.collapsed(Vec2D point)
      : left = point.x,
        top = point.y,
        right = point.x,
        bottom = point.y;

  static bool areEqual(AABB a, AABB b) {
    return a.left == b.left &&
        a.top == b.top &&
        a.right == b.right &&
        a.bottom == b.bottom;
  }

  double get width => right - left;

  double get height => bottom - top;

  double get area => width * height;

  AABB operator *(double v) =>
      AABB.fromValues(left * v, top * v, right * v, bottom * v);

  AABB operator /(double v) =>
      AABB.fromValues(left / v, top / v, right / v, bottom / v);

  Rect get rect => Rect.fromLTRB(left, top, right, bottom);

// TODO: Still required for bounds_resize.dart
// deprecated
  double operator [](int idx) {
    if (idx == 0) return left;
    if (idx == 1) return top;
    if (idx == 2) return right;
    if (idx == 3) return bottom;
    throw Exception('bad index');
  }

// deprecated
  void operator []=(int idx, double v) {
    if (idx == 0) {
      left = v;
    } else if (idx == 1) {
      top = v;
    } else if (idx == 2) {
      right = v;
    } else if (idx == 3) {
      bottom = v;
    } else {
      throw Exception('bad index');
    }
  }

  Vec2D center() {
    return Vec2D.fromValues((left + right) * 0.5, (top + bottom) * 0.5);
  }

  /// Get the point at x/y factor (where [0, 0] is center, [-1, 0] is left
  /// center, [1, 0] is right center).
  Vec2D pointAt(double xf, double yf) => Vec2D.fromValues(
      left + width * (xf + 1) / 2, top + height * (yf + 1) / 2);

  // Inverse of pointAt
  Vec2D factorFrom(Vec2D point) => Vec2D.fromValues(
      width == 0 ? 0 : (point.x - left) * 2 / width - 1,
      height == 0 ? 0 : (point.y - top) * 2 / height - 1);

  static AABB copy(AABB out, AABB a) {
    out.left = a.left;
    out.top = a.top;
    out.right = a.right;
    out.bottom = a.bottom;
    return out;
  }

  static Vec2D size(Vec2D out, AABB a) {
    out.x = a.width;
    out.y = a.height;
    return out;
  }

  static Vec2D extents(Vec2D out, AABB a) {
    out.x = a.width * 0.5;
    out.y = a.height * 0.5;
    return out;
  }

  static double perimeter(AABB a) {
    return 2.0 * (a.width + a.height);
  }

  static AABB combine(AABB out, AABB a, AABB b) {
    out.left = min(a.left, b.left);
    out.top = min(a.top, b.top);
    out.right = max(a.right, b.right);
    out.bottom = max(a.bottom, b.bottom);
    return out;
  }

  bool containsBounds(AABB b) {
    return left <= b.left &&
        top <= b.top &&
        b.right <= right &&
        b.bottom <= bottom;
  }

  static bool isValid(AABB a) {
    double dx = a.width;
    double dy = a.height;
    return dx >= 0 &&
        dy >= 0 &&
        // todo: does this handle -inf ?
        a.left <= double.maxFinite &&
        a.top <= double.maxFinite &&
        a.right <= double.maxFinite &&
        a.bottom <= double.maxFinite;
  }

  static bool testOverlap(AABB a, AABB b) {
    double d1x = b.left - a.right;
    double d1y = b.top - a.bottom;

    double d2x = a.left - b.right;
    double d2y = a.top - b.bottom;

    if (d1x > 0.0 || d1y > 0.0) {
      return false;
    }

    if (d2x > 0.0 || d2y > 0.0) {
      return false;
    }

    return true;
  }

  bool contains(Vec2D point) {
    return point.x >= left &&
        point.x <= right &&
        point.y >= top &&
        point.y <= bottom;
  }

  AABB translate(Vec2D vec) => offset(vec.x, vec.y);

  IAABB round() =>
      IAABB(left.round(), top.round(), right.round(), bottom.round());

  @override
  String toString() {
    return '$left $top $right $bottom';
  }

  AABB transform(Mat2D matrix) {
    return AABB.fromPoints([
      minimum,
      Vec2D.fromValues(maximum.x, minimum.y),
      maximum,
      Vec2D.fromValues(minimum.x, maximum.y)
    ], transform: matrix);
  }

  /// Compute an AABB from a set of points with an optional [transform] to apply
  /// before computing.
  factory AABB.fromPoints(
    Iterable<Vec2D> points, {
    Mat2D? transform,
    double expand = 0,
  }) {
    double minX = double.maxFinite;
    double minY = double.maxFinite;
    double maxX = -double.maxFinite;
    double maxY = -double.maxFinite;

    for (final point in points) {
      var p = transform == null ? point : transform * point;

      final x = p.x;
      final y = p.y;
      if (x < minX) {
        minX = x;
      }
      if (y < minY) {
        minY = y;
      }

      if (x > maxX) {
        maxX = x;
      }
      if (y > maxY) {
        maxY = y;
      }
    }

    // Make sure the box is at least this wide/high
    if (expand != 0) {
      double width = maxX - minX;
      double diff = expand - width;
      if (diff > 0) {
        diff /= 2;
        minX -= diff;
        maxX += diff;
      }
      double height = maxY - minY;
      diff = expand - height;

      if (diff > 0) {
        diff /= 2;
        minY -= diff;
        maxY += diff;
      }
    }
    return AABB.fromValues(minX, minY, maxX, maxY);
  }
}

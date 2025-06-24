enum PathFillRule {
  nonZero,
  evenOdd,
}

enum PathDirection {
  clockwise,
  counterclockwise,
}

abstract class PathInterface {
  void moveTo(double x, double y);
  void lineTo(double x, double y);
  void cubicTo(double ox, double oy, double ix, double iy, double x, double y);
  void close();
}

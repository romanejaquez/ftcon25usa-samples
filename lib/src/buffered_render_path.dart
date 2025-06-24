import 'dart:typed_data';

import 'package:rive_native/rive_native.dart';

class PrivatePathVerb {
  static const int move = 0;
  static const int line = 1;
  static const int quad = 2;
  static const int cubic = 4;
  static const int close = 5;

  static int pointCount(int verb) {
    switch (verb) {
      case PrivatePathVerb.close:
        return 0;
      case PrivatePathVerb.line:
      case PrivatePathVerb.move:
        return 1;
      case PrivatePathVerb.quad:
        return 2;
      case PrivatePathVerb.cubic:
        return 3;
      default:
        return 0;
    }
  }
}

abstract class BufferedRenderPath extends RenderPath {
  final List<int> verbs = [];
  final List<double> points = [];

  void resetBuffer() {
    verbs.clear();
    points.clear();
  }

  Uint8List get scratchBuffer;

  void appendCommands(int commandCount);
  void updateRenderPath();

  void update() {
    if (verbs.isEmpty) {
      return;
    }
    var list = scratchBuffer;
    var view =
        ByteData.view(list.buffer, list.offsetInBytes, list.lengthInBytes);

    int offset = 0;
    int pointIndex = 0;
    int commandCount = 0;
    for (final verb in verbs) {
      int pointCount = PrivatePathVerb.pointCount(verb);
      int requiredSize = pointCount * 8 + 1;
      if (requiredSize + offset >= list.length) {
        appendCommands(commandCount);
        offset = 0;
        commandCount = 0;
      }

      view.setUint8(offset++, verb);
      for (int i = 0; i < pointCount; i++) {
        view.setFloat32(offset, points[pointIndex++], Endian.little);
        offset += 4;
        view.setFloat32(offset, points[pointIndex++], Endian.little);
        offset += 4;
      }

      commandCount++;
    }
    if (commandCount > 0) {
      appendCommands(commandCount);
    }
    updateRenderPath();

    resetBuffer();
  }

  @override
  void close() => verbs.add(PrivatePathVerb.close);

  @override
  void cubicTo(double ox, double oy, double ix, double iy, double x, double y) {
    points.add(ox);
    points.add(oy);
    points.add(ix);
    points.add(iy);
    points.add(x);
    points.add(y);
    verbs.add(PrivatePathVerb.cubic);
  }

  @override
  void quadTo(double cx, double cy, double x, double y) {
    points.add(cx);
    points.add(cy);
    points.add(x);
    points.add(y);
    verbs.add(PrivatePathVerb.quad);
  }

  @override
  void lineTo(double x, double y) {
    points.add(x);
    points.add(y);
    verbs.add(PrivatePathVerb.line);
  }

  @override
  void moveTo(double x, double y) {
    points.add(x);
    points.add(y);
    verbs.add(PrivatePathVerb.move);
  }
}

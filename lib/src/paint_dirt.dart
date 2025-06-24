// PaintDirt that we receive from the C++ bindings (slightly different).
class PaintDirtFromNative {
  static const int style = 1 << 0;
  static const int color = 1 << 1;
  static const int thickness = 1 << 2;
  static const int join = 1 << 3;
  static const int cap = 1 << 4;
  static const int blendMode = 1 << 5;
  static const int linear = 1 << 6;
  static const int radial = 1 << 7;
  static const int removeGradient = 1 << 8;
}

// PaintDirt that we send to the C++ bindings.
class PaintDirt {
  static const int style = 1 << 0;
  static const int color = 1 << 1;
  static const int thickness = 1 << 2;
  static const int join = 1 << 3;
  static const int cap = 1 << 4;
  static const int blendMode = 1 << 5;
  static const int radial =
      1 << 6; // 0 == linear, 1 == radial only valid if stops != 0
  static const int done = 1 << 7; // 1 when no more gradien stops will follow

  // Anything higher than 8 bits will not be written to native, but can be used
  // as flags.
  // Not anymore, we've promoted this to a 16 bit flag
  static const int feather = 1 << 8;
  static const int gradient = 1 << 9;
}

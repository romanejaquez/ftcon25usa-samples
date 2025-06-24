import 'package:flutter/painting.dart';
import 'package:rive_native/rive_native.dart';

abstract class RiveDefaults {
  /// The default [Alignment] for Rive artboards.
  static const alignment = Alignment.center;

  /// The default [Fit] for Rive artboards.
  static const fit = Fit.contain;

  /// The default layout scale factor.
  static const layoutScaleFactor = 1.0;
}

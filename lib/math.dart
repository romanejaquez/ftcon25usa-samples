export 'package:rive_native/src/math/aabb.dart';
export 'package:rive_native/src/math/circle_constant.dart';
export 'package:rive_native/src/math/hit_test.dart';
export 'package:rive_native/src/math/mat2d.dart';
export 'package:rive_native/src/math/path_types.dart';
export 'package:rive_native/src/math/segment2d.dart';
export 'package:rive_native/src/math/transform_components.dart';
export 'package:rive_native/src/math/vec2d.dart';

/// Location of an integer within a bitfield.
/// https://en.wikipedia.org/wiki/C_syntax#Bit_fields
class BitFieldLoc {
  final int start;
  final int count;
  final int mask;

  const BitFieldLoc(this.start, int end)
      : assert(end >= start),
        // Rive runtime only supports 32 bits per field. Pack multiple bitfields
        // if you need more.
        assert(end < 32),
        count = end - start + 1,
        mask = ((1 << (end - start + 1)) - 1) << start;

  int read(int bits) => (bits & mask) >> start;
  int write(int bits, int value) => (bits & ~mask) | ((value << start) & mask);
}

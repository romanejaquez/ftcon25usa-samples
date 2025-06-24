import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';
import 'package:rive_native/rive_native.dart' as rive;
import 'package:rive_native/src/defaults.dart';

/// How to behave during hit tests on Rive Listeners (hit targets).
enum RiveHitTestBehavior {
  /// No hit testing will be performed.
  none,

  /// The bounds of the Rive graphic will consume all hits, even if there is
  /// no listener (hit area) at the target point. Content behind the animation
  /// will not receive hits.
  opaque,

  /// Rive will only consume hits where there is a listener (hit area) at the
  /// target point. Content behind the graphic will only receive hits if
  /// no target listener was hit.
  translucent,

  /// All hits will pass through the graphic, regardless of whether a
  /// a Rive listener was hit. Rive listeners will still receive hits.
  transparent,
}

/// The default [RiveHitTestBehavior] for Rive listeners.
const defaultRiveHitTestBehavior = RiveHitTestBehavior.opaque;

/// The default [MouseCursor] for Rive listeners.
const defaultRiveCursor = MouseCursor.defer;

/// Mixin that provides methods for handling pointer events on a [RivePainter].
///
/// The `hitTest` method will be invoked to determine if the pointer event
/// occurred within the widget's bounds and to check if a hit occurred on
/// a Rive listener.
///
/// The `pointerEvent` method will be invoked when a pointer event occurs
/// on the widget.
///
/// The `cursor` property determines the cursor to use when the pointer is over
///
/// The `hitTestBehavior` property determines how the widget will behave
/// during hit tests.
///
/// The `localToArtboard` method will convert a local offset to the artboard
/// coordinate space.
base mixin RivePointerEventMixin on rive.RivePainter {
  /// Determine if a pointer event occurred within the widget's bounds and
  /// to check if a hit occurred on a Rive listener.
  bool hitTest(Offset position);

  /// Handle a pointer event.
  void pointerEvent(PointerEvent event, HitTestEntry entry);

  /// The cursor to use when the pointer is over the hit test area.
  MouseCursor get cursor => _cursor;
  MouseCursor _cursor = defaultRiveCursor;
  set cursor(MouseCursor value) {
    if (_cursor != value) {
      _cursor = value;
      // A repaint is needed in order to trigger a device update of
      // [MouseTracker] so that this new value can be found.
      notifyListeners();
    }
  }

  /// The hit test behavior to use when determining if a pointer event occurred
  /// within the widget's bounds and to check if a hit occurred on a Rive
  /// listener.
  RiveHitTestBehavior get hitTestBehavior => _hitTestBehavior;
  RiveHitTestBehavior _hitTestBehavior = defaultRiveHitTestBehavior;
  set hitTestBehavior(RiveHitTestBehavior value) => _hitTestBehavior = value;

  /// Convert a local offset to the artboard coordinate space.
  ///
  /// This will use the current artboard size and device pixel ratio to
  /// transform the offset.
  ///
  /// The artboard is set in [artboardChanged].
  @nonVirtual
  rive.Vec2D localToArtboard({
    required Offset position,
    required rive.AABB artboardBounds,
    required rive.Fit fit,
    required Alignment alignment,
    required Size size,
    double scaleFactor = RiveDefaults.layoutScaleFactor,
  }) {
    var viewTransform = rive.Renderer.computeAlignment(
      fit,
      alignment,
      rive.AABB.fromValues(0, 0, size.width, size.height),
      artboardBounds,
      scaleFactor,
    );
    final inverseViewTransform = rive.Mat2D();
    if (!rive.Mat2D.invert(inverseViewTransform, viewTransform)) {
      return rive.Vec2D();
    }
    return inverseViewTransform * rive.Vec2D.fromOffset(position);
  }
}

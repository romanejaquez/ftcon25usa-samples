import 'dart:collection';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:rive_native/layout_engine.dart';
import 'package:rive_native/src/ffi/dynamic_library_helper.dart';

DynamicLibrary get _nativeLib => DynamicLibraryHelper.nativeLib;

final Pointer<Void> Function() _makeYogaStyle = _nativeLib
    .lookup<NativeFunction<Pointer<Void> Function()>>('makeYogaStyle')
    .asFunction();

final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _disposeYogaStyleNative =
    _nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'disposeYogaStyle');

final void Function(Pointer<Void>) _disposeYogaStyle =
    _disposeYogaStyleNative.asFunction();

final Pointer<Void> Function() _makeYogaNode = _nativeLib
    .lookup<NativeFunction<Pointer<Void> Function()>>('makeYogaNode')
    .asFunction();

final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _disposeYogaNodeNative =
    _nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'disposeYogaNode');

final void Function(Pointer<Void>) _disposeYogaNode =
    _disposeYogaNodeNative.asFunction();

final void Function(Pointer<Void>, Pointer<Void>) _yogaNodeSetStyle = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<Void>)>>(
        'yogaNodeSetStyle')
    .asFunction();

final bool Function(Pointer<Void>) _yogaNodeCheckAndResetUpdated = _nativeLib
    .lookup<
        NativeFunction<
            Bool Function(
              Pointer<Void>,
            )>>('yogaNodeCheckAndResetUpdated')
    .asFunction();

final int Function(Pointer<Void>) _yogaNodeGetType = _nativeLib
    .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>('yogaNodeGetType')
    .asFunction();

final void Function(Pointer<Void>, int) _yogaNodeSetType = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Int32)>>(
        'yogaNodeSetType')
    .asFunction();

final int Function(Pointer<Void>) _yogaStyleGetAlignContent = _nativeLib
    .lookup<NativeFunction<Int Function(Pointer<Void>)>>(
        'yogaStyleGetAlignContent')
    .asFunction();

final void Function(Pointer<Void>, int) _yogaStyleSetAlignContent = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Int)>>(
        'yogaStyleSetAlignContent')
    .asFunction();

final int Function(Pointer<Void>) _yogaStyleGetDirection = _nativeLib
    .lookup<NativeFunction<Int Function(Pointer<Void>)>>(
        'yogaStyleGetDirection')
    .asFunction();

final void Function(Pointer<Void>, int) _yogaStyleSetDirection = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Int)>>(
        'yogaStyleSetDirection')
    .asFunction();

final int Function(Pointer<Void>) _yogaStyleGetFlexDirection = _nativeLib
    .lookup<NativeFunction<Int Function(Pointer<Void>)>>(
        'yogaStyleGetFlexDirection')
    .asFunction();

final void Function(Pointer<Void>, int) _yogaStyleSetFlexDirection = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Int)>>(
        'yogaStyleSetFlexDirection')
    .asFunction();

final int Function(Pointer<Void>) _yogaStyleGetJustifyContent = _nativeLib
    .lookup<NativeFunction<Int Function(Pointer<Void>)>>(
        'yogaStyleGetJustifyContent')
    .asFunction();

final void Function(Pointer<Void>, int) _yogaStyleSetJustifyContent = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Int)>>(
        'yogaStyleSetJustifyContent')
    .asFunction();

final int Function(Pointer<Void>) _yogaStyleGetAlignItems = _nativeLib
    .lookup<NativeFunction<Int Function(Pointer<Void>)>>(
        'yogaStyleGetAlignItems')
    .asFunction();

final void Function(Pointer<Void>, int) _yogaStyleSetAlignItems = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Int)>>(
        'yogaStyleSetAlignItems')
    .asFunction();

final int Function(Pointer<Void>) _yogaStyleGetAlignSelf = _nativeLib
    .lookup<NativeFunction<Int Function(Pointer<Void>)>>(
        'yogaStyleGetAlignSelf')
    .asFunction();

final void Function(Pointer<Void>, int) _yogaStyleSetAlignSelf = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Int)>>(
        'yogaStyleSetAlignSelf')
    .asFunction();

final int Function(Pointer<Void>) _yogaStyleGetPositionType = _nativeLib
    .lookup<NativeFunction<Int Function(Pointer<Void>)>>(
        'yogaStyleGetPositionType')
    .asFunction();

final void Function(Pointer<Void>, int) _yogaStyleSetPositionType = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Int)>>(
        'yogaStyleSetPositionType')
    .asFunction();

final int Function(Pointer<Void>) _yogaStyleGetFlexWrap = _nativeLib
    .lookup<NativeFunction<Int Function(Pointer<Void>)>>('yogaStyleGetFlexWrap')
    .asFunction();

final void Function(Pointer<Void>, int) _yogaStyleSetFlexWrap = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Int)>>(
        'yogaStyleSetFlexWrap')
    .asFunction();

final int Function(Pointer<Void>) _yogaStyleGetOverflow = _nativeLib
    .lookup<NativeFunction<Int Function(Pointer<Void>)>>('yogaStyleGetOverflow')
    .asFunction();

final void Function(Pointer<Void>, int) _yogaStyleSetOverflow = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Int)>>(
        'yogaStyleSetOverflow')
    .asFunction();

final int Function(Pointer<Void>) _yogaStyleGetDisplay = _nativeLib
    .lookup<NativeFunction<Int Function(Pointer<Void>)>>('yogaStyleGetDisplay')
    .asFunction();

final void Function(Pointer<Void>, int) _yogaStyleSetDisplay = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Int)>>(
        'yogaStyleSetDisplay')
    .asFunction();

final double Function(Pointer<Void>) _yogaStyleGetFlex = _nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>('yogaStyleGetFlex')
    .asFunction();

final void Function(Pointer<Void>, double) _yogaStyleSetFlex = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
        'yogaStyleSetFlex')
    .asFunction();

final double Function(Pointer<Void>) _yogaStyleGetFlexGrow = _nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
        'yogaStyleGetFlexGrow')
    .asFunction();

final void Function(Pointer<Void>, double) _yogaStyleSetFlexGrow = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
        'yogaStyleSetFlexGrow')
    .asFunction();

final double Function(Pointer<Void>) _yogaStyleGetFlexShrink = _nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
        'yogaStyleGetFlexShrink')
    .asFunction();

final void Function(Pointer<Void>, double) _yogaStyleSetFlexShrink = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
        'yogaStyleSetFlexShrink')
    .asFunction();

final class _YGValue extends Struct {
  @Float()
  external double value;
  @Int32()
  external int unit;

  LayoutValue toLayoutValue() => LayoutValue(
        value: value,
        unit: LayoutUnit.values[unit],
      );
}

final _YGValue Function(Pointer<Void>) _yogaStyleGetFlexBasis = _nativeLib
    .lookup<NativeFunction<_YGValue Function(Pointer<Void>)>>(
        'yogaStyleGetFlexBasis')
    .asFunction();

final void Function(Pointer<Void>, double, int) _yogaStyleSetFlexBasis =
    _nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Float, Int32)>>(
            'yogaStyleSetFlexBasis')
        .asFunction();

final _YGValue Function(Pointer<Void>, int) _yogaStyleGetMargin = _nativeLib
    .lookup<NativeFunction<_YGValue Function(Pointer<Void>, Int32)>>(
        'yogaStyleGetMargin')
    .asFunction();

final void Function(Pointer<Void>, int, double, int) _yogaStyleSetMargin =
    _nativeLib
        .lookup<
            NativeFunction<
                Void Function(
                    Pointer<Void>, Int32, Float, Int32)>>('yogaStyleSetMargin')
        .asFunction();

final _YGValue Function(Pointer<Void>, int) _yogaStyleGetPosition = _nativeLib
    .lookup<NativeFunction<_YGValue Function(Pointer<Void>, Int32)>>(
        'yogaStyleGetPosition')
    .asFunction();

final void Function(Pointer<Void>, int, double, int) _yogaStyleSetPosition =
    _nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Int32, Float,
                    Int32)>>('yogaStyleSetPosition')
        .asFunction();

final _YGValue Function(Pointer<Void>, int) _yogaStyleGetPadding = _nativeLib
    .lookup<NativeFunction<_YGValue Function(Pointer<Void>, Int32)>>(
        'yogaStyleGetPadding')
    .asFunction();

final void Function(Pointer<Void>, int, double, int) _yogaStyleSetPadding =
    _nativeLib
        .lookup<
            NativeFunction<
                Void Function(
                    Pointer<Void>, Int32, Float, Int32)>>('yogaStyleSetPadding')
        .asFunction();

final _YGValue Function(Pointer<Void>, int) _yogaStyleGetBorder = _nativeLib
    .lookup<NativeFunction<_YGValue Function(Pointer<Void>, Int32)>>(
        'yogaStyleGetBorder')
    .asFunction();

final void Function(Pointer<Void>, int, double, int) _yogaStyleSetBorder =
    _nativeLib
        .lookup<
            NativeFunction<
                Void Function(
                    Pointer<Void>, Int32, Float, Int32)>>('yogaStyleSetBorder')
        .asFunction();

final _YGValue Function(Pointer<Void>, int) _yogaStyleGetGap = _nativeLib
    .lookup<NativeFunction<_YGValue Function(Pointer<Void>, Int32)>>(
        'yogaStyleGetGap')
    .asFunction();

final void Function(Pointer<Void>, int, double, int) _yogaStyleSetGap =
    _nativeLib
        .lookup<
            NativeFunction<
                Void Function(
                    Pointer<Void>, Int32, Float, Int32)>>('yogaStyleSetGap')
        .asFunction();

final _YGValue Function(Pointer<Void>, int) _yogaStyleGetDimension = _nativeLib
    .lookup<NativeFunction<_YGValue Function(Pointer<Void>, Int32)>>(
        'yogaStyleGetDimension')
    .asFunction();

final void Function(Pointer<Void>, int, double, int) _yogaStyleSetDimension =
    _nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Int32, Float,
                    Int32)>>('yogaStyleSetDimension')
        .asFunction();

final _YGValue Function(Pointer<Void>, int) _yogaStyleGetMinDimension =
    _nativeLib
        .lookup<NativeFunction<_YGValue Function(Pointer<Void>, Int32)>>(
            'yogaStyleGetMinDimension')
        .asFunction();

final void Function(Pointer<Void>, int, double, int) _yogaStyleSetMinDimension =
    _nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Int32, Float,
                    Int32)>>('yogaStyleSetMinDimension')
        .asFunction();

final void Function(Pointer<Void>, Pointer<Void>, int) _yogaNodeInsertChild =
    _nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Pointer<Void>,
                    Int32 index)>>('yogaNodeInsertChild')
        .asFunction();

final void Function(Pointer<Void>, Pointer<Void>) _yogaNodeRemoveChild =
    _nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<Void>)>>(
            'yogaNodeRemoveChild')
        .asFunction();

final void Function(Pointer<Void>) _yogaNodeClearChildren = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'yogaNodeClearChildren')
    .asFunction();

final _YGValue Function(Pointer<Void>, int) _yogaStyleGetMaxDimension =
    _nativeLib
        .lookup<NativeFunction<_YGValue Function(Pointer<Void>, Int32)>>(
            'yogaStyleGetMaxDimension')
        .asFunction();

final void Function(Pointer<Void>, int, double, int) _yogaStyleSetMaxDimension =
    _nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Int32, Float,
                    Int32)>>('yogaStyleSetMaxDimension')
        .asFunction();

final void Function(Pointer<Void>, double, double, int)
    _yogaNodeCalculateLayout = _nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Float, Float,
                    Int32)>>('yogaNodeCalculateLayout')
        .asFunction();

final class _YGLayout extends Struct {
  @Float()
  external double left;

  @Float()
  external double top;

  @Float()
  external double width;

  @Float()
  external double height;

  @override
  String toString() => 'Layout $left $top $width $height';

  Layout toLayout() => Layout(left, top, width, height);

  LayoutPadding toPadding() => LayoutPadding(left, top, width, height);
}

final _YGLayout Function(Pointer<Void>) _yogaNodeGetLayout = _nativeLib
    .lookup<NativeFunction<_YGLayout Function(Pointer<Void>)>>(
        'yogaNodeGetLayout')
    .asFunction();

final _YGLayout Function(Pointer<Void>) _yogaNodeGetPadding = _nativeLib
    .lookup<NativeFunction<_YGLayout Function(Pointer<Void>)>>(
        'yogaNodeGetPadding')
    .asFunction();

final class _YGSize extends Struct {
  @Float()
  external double width;

  @Float()
  external double height;
}

typedef _MeasureFuncFFI = _YGSize Function(
    Pointer<Void>, Float, Int32, Float, Int32);
typedef _BaselineFuncFFI = Float Function(Pointer<Void>, Float, Float);

final void Function(Pointer<Void>, Pointer<NativeFunction<_BaselineFuncFFI>>)
    _yogaNodeSetBaselineFunc = _nativeLib
        .lookup<
                NativeFunction<
                    Void Function(Pointer<Void>,
                        Pointer<NativeFunction<_BaselineFuncFFI>>)>>(
            'yogaNodeSetBaselineFunc')
        .asFunction();

// ignore: unused_element
final void Function(Pointer<Void>) _yogaNodeClearBaselineFunc = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'yogaNodeClearMeasureFunc')
    .asFunction();

final void Function(Pointer<Void>, Pointer<NativeFunction<_MeasureFuncFFI>>)
    _yogaNodeSetMeasureFunc = _nativeLib
        .lookup<
                NativeFunction<
                    Void Function(Pointer<Void>,
                        Pointer<NativeFunction<_MeasureFuncFFI>>)>>(
            'yogaNodeSetMeasureFunc')
        .asFunction();

final void Function(Pointer<Void>) _yogaNodeClearMeasureFunc = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'yogaNodeClearMeasureFunc')
    .asFunction();

final void Function(Pointer<Void>) _yogaNodeMarkDirty = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>('yogaNodeMarkDirty')
    .asFunction();

class LayoutNodeFFI extends LayoutNode implements Finalizable {
  static final _finalizer = NativeFinalizer(_disposeYogaNodeNative);
  final bool isOwned;
  Pointer<Void> _nativePtr;
  LayoutNodeFFI(this._nativePtr, this.isOwned) {
    if (isOwned) {
      _finalizer.attach(this, _nativePtr.cast(), detach: this);
    }
  }

  @override
  void dispose() {
    if (_nativePtr == nullptr) {
      return;
    }
    if (isOwned) {
      _finalizer.detach(this);
      _disposeYogaNode(_nativePtr);
    }
    _callbackLookup.remove(_nativePtr);
    _nativePtr = nullptr;
  }

  @override
  void setStyle(LayoutStyle style) =>
      _yogaNodeSetStyle(_nativePtr, (style as LayoutStyleFFI)._nativePtr);

  @override
  LayoutNodeType get nodeType =>
      LayoutNodeType.values[_yogaNodeGetType(_nativePtr)];

  @override
  bool checkAndResetUpdated() => _yogaNodeCheckAndResetUpdated(_nativePtr);

  @override
  set nodeType(LayoutNodeType value) =>
      _yogaNodeSetType(_nativePtr, value.index);

  @override
  void calculateLayout(double availableWidth, double availableHeight,
          LayoutDirection direction) =>
      _yogaNodeCalculateLayout(
          _nativePtr, availableWidth, availableHeight, direction.index);

  @override
  Layout get layout => _yogaNodeGetLayout(_nativePtr).toLayout();

  @override
  LayoutPadding get layoutPadding =>
      _yogaNodeGetPadding(_nativePtr).toPadding();

  @override
  void clearChildren() => _yogaNodeClearChildren(_nativePtr);

  @override
  void insertChild(LayoutNode node, int index) => _yogaNodeInsertChild(
      _nativePtr, (node as LayoutNodeFFI)._nativePtr, index);

  @override
  void removeChild(LayoutNode node) =>
      _yogaNodeRemoveChild(_nativePtr, (node as LayoutNodeFFI)._nativePtr);

  static Pointer<_YGSize>? _measuredSizePtr;
  static late _YGSize _measuredSize;

  // Store a hashmap to lookup pointer to layout nodes, necessary when using a
  // measure or baseline callback.
  static final HashMap<Pointer<Void>, WeakReference<LayoutNodeFFI>>
      _callbackLookup = HashMap<Pointer<Void>, WeakReference<LayoutNodeFFI>>();

  MeasureFunction? _measureFunction;
  @override
  MeasureFunction? get measureFunction => _measureFunction;

  @override
  set measureFunction(MeasureFunction? value) {
    if (value == _measureFunction) {
      return;
    }
    if (_measuredSizePtr == null) {
      _measuredSizePtr = malloc<_YGSize>();
      _measuredSize = _measuredSizePtr!.ref;
    }
    _measureFunction = value;
    if (value == null) {
      _yogaNodeClearMeasureFunc(_nativePtr);
      return;
    }
    _callbackLookup[_nativePtr] = WeakReference(this);
    _yogaNodeSetMeasureFunc(_nativePtr, _proxyMeasurePointer);
  }

  BaselineFunction? _baselineFunction;
  @override
  BaselineFunction? get baselineFunction => _baselineFunction;

  @override
  set baselineFunction(BaselineFunction? value) {
    if (value == _baselineFunction) {
      return;
    }
    _baselineFunction = value;
    if (value == null) {
      _yogaNodeClearMeasureFunc(_nativePtr);
      return;
    }
    _callbackLookup[_nativePtr] = WeakReference(this);

    _yogaNodeSetBaselineFunc(_nativePtr, _proxyBaselinePointer);
  }

  final _proxyMeasurePointer =
      Pointer.fromFunction<_MeasureFuncFFI>(_proxyMeasure);

  final _proxyBaselinePointer =
      Pointer.fromFunction<_BaselineFuncFFI>(_proxyBaseline, 0.0);

  // Static helper to bridge native call.
  static _YGSize _proxyMeasure(Pointer<Void> nodePtr, double width,
      int widthModeValue, double height, int heightModeValue) {
    var node = _callbackLookup[nodePtr]?.target;
    if (node == null) {
      _measuredSize.width = 0;
      _measuredSize.height = 0;
    } else {
      var measuredSize = node._measureFunction?.call(
          node,
          width,
          LayoutMeasureMode.values[widthModeValue],
          height,
          LayoutMeasureMode.values[heightModeValue]);
      _measuredSize.width = measuredSize?.width ?? 0;
      _measuredSize.height = measuredSize?.height ?? 0;
    }
    return _measuredSize;
  }

  static double _proxyBaseline(
      Pointer<Void> nodePtr, double width, double height) {
    double baseline = 0;
    var node = _callbackLookup[nodePtr]?.target;
    if (node != null) {
      baseline = node._baselineFunction?.call(
            node,
            width,
            height,
          ) ??
          0;
    }
    return baseline;
  }

  @override
  void markDirty() => _yogaNodeMarkDirty(_nativePtr);
}

class LayoutStyleFFI extends LayoutStyle implements Finalizable {
  Pointer<Void> _nativePtr;
  static final _finalizer = NativeFinalizer(_disposeYogaStyleNative);

  LayoutStyleFFI(this._nativePtr) {
    _finalizer.attach(this, _nativePtr.cast(), detach: this);
  }

  @override
  void dispose() {
    if (_nativePtr == nullptr) {
      return;
    }
    _finalizer.detach(this);
    _disposeYogaStyle(_nativePtr);
    _nativePtr = nullptr;
  }

  @override
  LayoutAlign get alignContent =>
      LayoutAlign.values[_yogaStyleGetAlignContent(_nativePtr)];

  @override
  set alignContent(LayoutAlign value) =>
      _yogaStyleSetAlignContent(_nativePtr, value.index);

  @override
  LayoutDirection get direction =>
      LayoutDirection.values[_yogaStyleGetDirection(_nativePtr)];

  @override
  set direction(LayoutDirection value) =>
      _yogaStyleSetDirection(_nativePtr, value.index);

  @override
  LayoutFlexDirection get flexDirection =>
      LayoutFlexDirection.values[_yogaStyleGetFlexDirection(_nativePtr)];

  @override
  set flexDirection(LayoutFlexDirection value) =>
      _yogaStyleSetFlexDirection(_nativePtr, value.index);

  @override
  LayoutJustify get justifyContent =>
      LayoutJustify.values[_yogaStyleGetJustifyContent(_nativePtr)];

  @override
  set justifyContent(LayoutJustify value) =>
      _yogaStyleSetJustifyContent(_nativePtr, value.index);

  @override
  LayoutAlign get alignItems =>
      LayoutAlign.values[_yogaStyleGetAlignItems(_nativePtr)];

  @override
  set alignItems(LayoutAlign value) =>
      _yogaStyleSetAlignItems(_nativePtr, value.index);

  @override
  LayoutAlign get alignSelf =>
      LayoutAlign.values[_yogaStyleGetAlignSelf(_nativePtr)];

  @override
  set alignSelf(LayoutAlign value) =>
      _yogaStyleSetAlignSelf(_nativePtr, value.index);

  @override
  LayoutPosition get positionType =>
      LayoutPosition.values[_yogaStyleGetPositionType(_nativePtr)];

  @override
  set positionType(LayoutPosition value) =>
      _yogaStyleSetPositionType(_nativePtr, value.index);

  @override
  LayoutWrap get flexWrap =>
      LayoutWrap.values[_yogaStyleGetFlexWrap(_nativePtr)];

  @override
  set flexWrap(LayoutWrap value) =>
      _yogaStyleSetFlexWrap(_nativePtr, value.index);

  @override
  LayoutOverflow get overflow =>
      LayoutOverflow.values[_yogaStyleGetOverflow(_nativePtr)];

  @override
  set overflow(LayoutOverflow value) =>
      _yogaStyleSetOverflow(_nativePtr, value.index);

  @override
  LayoutDisplay get display =>
      LayoutDisplay.values[_yogaStyleGetDisplay(_nativePtr)];

  @override
  set display(LayoutDisplay value) =>
      _yogaStyleSetDisplay(_nativePtr, value.index);

  @override
  double? get flex {
    double value = _yogaStyleGetFlex(_nativePtr);
    if (value.isNaN) {
      return null;
    }
    return value;
  }

  @override
  set flex(double? value) => _yogaStyleSetFlex(_nativePtr, value ?? double.nan);

  @override
  double? get flexGrow {
    double value = _yogaStyleGetFlexGrow(_nativePtr);
    if (value.isNaN) {
      return null;
    }
    return value;
  }

  @override
  set flexGrow(double? value) =>
      _yogaStyleSetFlexGrow(_nativePtr, value ?? double.nan);

  @override
  double? get flexShrink {
    double value = _yogaStyleGetFlexShrink(_nativePtr);
    if (value.isNaN) {
      return null;
    }
    return value;
  }

  @override
  set flexShrink(double? value) =>
      _yogaStyleSetFlexShrink(_nativePtr, value ?? double.nan);

  @override
  LayoutValue get flexBasis =>
      _yogaStyleGetFlexBasis(_nativePtr).toLayoutValue();

  @override
  set flexBasis(LayoutValue value) =>
      _yogaStyleSetFlexBasis(_nativePtr, value.value, value.unit.index);

  @override
  LayoutValue getMargin(LayoutEdge edge) =>
      _yogaStyleGetMargin(_nativePtr, edge.index).toLayoutValue();

  @override
  void setMargin(LayoutEdge edge, LayoutValue value) => _yogaStyleSetMargin(
      _nativePtr, edge.index, value.value, value.unit.index);

  @override
  LayoutValue getPosition(LayoutEdge edge) =>
      _yogaStyleGetPosition(_nativePtr, edge.index).toLayoutValue();

  @override
  void setPosition(LayoutEdge edge, LayoutValue value) => _yogaStyleSetPosition(
      _nativePtr, edge.index, value.value, value.unit.index);

  @override
  LayoutValue getPadding(LayoutEdge edge) =>
      _yogaStyleGetPadding(_nativePtr, edge.index).toLayoutValue();

  @override
  void setPadding(LayoutEdge edge, LayoutValue value) => _yogaStyleSetPadding(
      _nativePtr, edge.index, value.value, value.unit.index);

  @override
  LayoutValue getBorder(LayoutEdge edge) =>
      _yogaStyleGetBorder(_nativePtr, edge.index).toLayoutValue();

  @override
  void setBorder(LayoutEdge edge, LayoutValue value) => _yogaStyleSetBorder(
      _nativePtr, edge.index, value.value, value.unit.index);

  @override
  LayoutValue getGap(LayoutGutter gutter) =>
      _yogaStyleGetGap(_nativePtr, gutter.index).toLayoutValue();

  @override
  void setGap(LayoutGutter gutter, LayoutValue value) =>
      _yogaStyleSetGap(_nativePtr, gutter.index, value.value, value.unit.index);

  @override
  LayoutValue getDimension(LayoutDimension dimension) =>
      _yogaStyleGetDimension(_nativePtr, dimension.index).toLayoutValue();

  @override
  void setDimension(LayoutDimension dimension, LayoutValue value) =>
      _yogaStyleSetDimension(
          _nativePtr, dimension.index, value.value, value.unit.index);

  @override
  LayoutValue getMinDimension(LayoutDimension dimension) =>
      _yogaStyleGetMinDimension(_nativePtr, dimension.index).toLayoutValue();

  @override
  void setMinDimension(LayoutDimension dimension, LayoutValue value) =>
      _yogaStyleSetMinDimension(
          _nativePtr, dimension.index, value.value, value.unit.index);

  @override
  LayoutValue getMaxDimension(LayoutDimension dimension) =>
      _yogaStyleGetMaxDimension(_nativePtr, dimension.index).toLayoutValue();

  @override
  void setMaxDimension(LayoutDimension dimension, LayoutValue value) =>
      _yogaStyleSetMaxDimension(
          _nativePtr, dimension.index, value.value, value.unit.index);
}

LayoutStyle makeLayoutStyle() => LayoutStyleFFI(_makeYogaStyle());

LayoutNode makeLayoutNode() => LayoutNodeFFI(_makeYogaNode(), true);

LayoutNode makeLayoutNodeExternal(dynamic ref) =>
    LayoutNodeFFI(ref as Pointer<Void>, false);

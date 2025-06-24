import 'dart:collection';
import 'dart:js_interop' as js;
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:rive_native/layout_engine.dart';

late js.JSFunction _makeYogaStyle;
late js.JSFunction _disposeYogaStyle;
late js.JSFunction _yogaStyleGetAlignContent;
late js.JSFunction _yogaStyleSetAlignContent;
late js.JSFunction _yogaStyleGetDirection;
late js.JSFunction _yogaStyleSetDirection;
late js.JSFunction _yogaStyleGetFlexDirection;
late js.JSFunction _yogaStyleSetFlexDirection;
late js.JSFunction _yogaStyleGetJustifyContent;
late js.JSFunction _yogaStyleSetJustifyContent;
late js.JSFunction _yogaStyleGetAlignItems;
late js.JSFunction _yogaStyleSetAlignItems;
late js.JSFunction _yogaStyleGetAlignSelf;
late js.JSFunction _yogaStyleSetAlignSelf;
late js.JSFunction _yogaStyleGetPositionType;
late js.JSFunction _yogaStyleSetPositionType;
late js.JSFunction _yogaStyleGetFlexWrap;
late js.JSFunction _yogaStyleSetFlexWrap;
late js.JSFunction _yogaStyleGetOverflow;
late js.JSFunction _yogaStyleSetOverflow;
late js.JSFunction _yogaStyleGetDisplay;
late js.JSFunction _yogaStyleSetDisplay;
late js.JSFunction _yogaStyleGetFlex;
late js.JSFunction _yogaStyleSetFlex;
late js.JSFunction _yogaStyleGetFlexGrow;
late js.JSFunction _yogaStyleSetFlexGrow;
late js.JSFunction _yogaStyleGetFlexShrink;
late js.JSFunction _yogaStyleSetFlexShrink;
late js.JSFunction _yogaStyleGetFlexBasis;
late js.JSFunction _yogaStyleSetFlexBasis;
late js.JSFunction _yogaStyleGetMargin;
late js.JSFunction _yogaStyleSetMargin;
late js.JSFunction _yogaStyleGetPosition;
late js.JSFunction _yogaStyleSetPosition;
late js.JSFunction _yogaStyleGetPadding;
late js.JSFunction _yogaStyleSetPadding;
late js.JSFunction _yogaStyleGetBorder;
late js.JSFunction _yogaStyleSetBorder;
late js.JSFunction _yogaStyleGetGap;
late js.JSFunction _yogaStyleSetGap;
late js.JSFunction _yogaStyleGetDimension;
late js.JSFunction _yogaStyleSetDimension;
late js.JSFunction _yogaStyleGetMinDimension;
late js.JSFunction _yogaStyleSetMinDimension;
late js.JSFunction _yogaStyleGetMaxDimension;
late js.JSFunction _yogaStyleSetMaxDimension;
late js.JSFunction _makeYogaNode;
late js.JSFunction _disposeYogaNode;
late js.JSFunction _yogaNodeCalculateLayout;
late js.JSFunction _yogaNodeGetLayout;
late js.JSFunction _yogaNodeGetPadding;
late js.JSFunction _yogaNodeSetMeasureFunc;
late js.JSFunction _yogaNodeClearMeasureFunc;
late js.JSFunction _yogaNodeSetBaselineFunc;
late js.JSFunction _yogaNodeClearBaselineFunc;
late js.JSFunction _yogaNodeMarkDirty;
late js.JSFunction _yogaNodeInsertChild;
late js.JSFunction _yogaNodeRemoveChild;
late js.JSFunction _yogaNodeClearChildren;
late js.JSFunction _yogaNodeSetStyle;
late js.JSFunction _yogaNodeGetType;
late js.JSFunction _yogaNodeSetType;
late js.JSFunction _yogaNodeCheckAndResetUpdated;

// ignore: avoid_classes_with_only_static_members
class LayoutEngineWasm {
  static void link(js.JSObject module) {
    _makeYogaStyle = module['_makeYogaStyle'] as js.JSFunction;
    _disposeYogaStyle = module['_disposeYogaStyle'] as js.JSFunction;
    _yogaStyleGetAlignContent =
        module['_yogaStyleGetAlignContent'] as js.JSFunction;
    _yogaStyleSetAlignContent =
        module['_yogaStyleSetAlignContent'] as js.JSFunction;
    _yogaStyleGetDirection = module['_yogaStyleGetDirection'] as js.JSFunction;
    _yogaStyleSetDirection = module['_yogaStyleSetDirection'] as js.JSFunction;
    _yogaStyleGetFlexDirection =
        module['_yogaStyleGetFlexDirection'] as js.JSFunction;
    _yogaStyleSetFlexDirection =
        module['_yogaStyleSetFlexDirection'] as js.JSFunction;
    _yogaStyleGetJustifyContent =
        module['_yogaStyleGetJustifyContent'] as js.JSFunction;
    _yogaStyleSetJustifyContent =
        module['_yogaStyleSetJustifyContent'] as js.JSFunction;
    _yogaStyleGetAlignItems =
        module['_yogaStyleGetAlignItems'] as js.JSFunction;
    _yogaStyleSetAlignItems =
        module['_yogaStyleSetAlignItems'] as js.JSFunction;
    _yogaStyleGetAlignSelf = module['_yogaStyleGetAlignSelf'] as js.JSFunction;
    _yogaStyleSetAlignSelf = module['_yogaStyleSetAlignSelf'] as js.JSFunction;
    _yogaStyleGetPositionType =
        module['_yogaStyleGetPositionType'] as js.JSFunction;
    _yogaStyleSetPositionType =
        module['_yogaStyleSetPositionType'] as js.JSFunction;
    _yogaStyleGetFlexWrap = module['_yogaStyleGetFlexWrap'] as js.JSFunction;
    _yogaStyleSetFlexWrap = module['_yogaStyleSetFlexWrap'] as js.JSFunction;
    _yogaStyleGetOverflow = module['_yogaStyleGetOverflow'] as js.JSFunction;
    _yogaStyleSetOverflow = module['_yogaStyleSetOverflow'] as js.JSFunction;
    _yogaStyleGetDisplay = module['_yogaStyleGetDisplay'] as js.JSFunction;
    _yogaStyleSetDisplay = module['_yogaStyleSetDisplay'] as js.JSFunction;
    _yogaStyleGetFlex = module['_yogaStyleGetFlex'] as js.JSFunction;
    _yogaStyleSetFlex = module['_yogaStyleSetFlex'] as js.JSFunction;
    _yogaStyleGetFlexGrow = module['_yogaStyleGetFlexGrow'] as js.JSFunction;
    _yogaStyleSetFlexGrow = module['_yogaStyleSetFlexGrow'] as js.JSFunction;
    _yogaStyleGetFlexShrink =
        module['_yogaStyleGetFlexShrink'] as js.JSFunction;
    _yogaStyleSetFlexShrink =
        module['_yogaStyleSetFlexShrink'] as js.JSFunction;
    _yogaStyleGetFlexBasis = module['yogaStyleGetFlexBasis'] as js.JSFunction;
    _yogaStyleSetFlexBasis = module['_yogaStyleSetFlexBasis'] as js.JSFunction;
    _yogaStyleGetMargin = module['yogaStyleGetMargin'] as js.JSFunction;
    _yogaStyleSetMargin = module['_yogaStyleSetMargin'] as js.JSFunction;
    _yogaStyleGetPosition = module['yogaStyleGetPosition'] as js.JSFunction;
    _yogaStyleSetPosition = module['_yogaStyleSetPosition'] as js.JSFunction;
    _yogaStyleGetPadding = module['yogaStyleGetPadding'] as js.JSFunction;
    _yogaStyleSetPadding = module['_yogaStyleSetPadding'] as js.JSFunction;
    _yogaStyleGetBorder = module['yogaStyleGetBorder'] as js.JSFunction;
    _yogaStyleSetBorder = module['_yogaStyleSetBorder'] as js.JSFunction;
    _yogaStyleGetGap = module['yogaStyleGetGap'] as js.JSFunction;
    _yogaStyleSetGap = module['_yogaStyleSetGap'] as js.JSFunction;
    _yogaStyleGetDimension = module['yogaStyleGetDimension'] as js.JSFunction;
    _yogaStyleSetDimension = module['_yogaStyleSetDimension'] as js.JSFunction;
    _yogaStyleGetMinDimension =
        module['yogaStyleGetMinDimension'] as js.JSFunction;
    _yogaStyleSetMinDimension =
        module['_yogaStyleSetMinDimension'] as js.JSFunction;
    _yogaStyleGetMaxDimension =
        module['yogaStyleGetMaxDimension'] as js.JSFunction;
    _yogaStyleSetMaxDimension =
        module['_yogaStyleSetMaxDimension'] as js.JSFunction;
    _makeYogaNode = module['_makeYogaNode'] as js.JSFunction;
    _disposeYogaNode = module['disposeYogaNode'] as js.JSFunction;
    _yogaNodeCalculateLayout =
        module['_yogaNodeCalculateLayout'] as js.JSFunction;
    _yogaNodeGetLayout = module['yogaNodeGetLayout'] as js.JSFunction;
    _yogaNodeGetPadding = module['yogaNodeGetPadding'] as js.JSFunction;
    _yogaNodeSetMeasureFunc = module['yogaNodeSetMeasureFunc'] as js.JSFunction;
    _yogaNodeClearMeasureFunc =
        module['yogaNodeClearMeasureFunc'] as js.JSFunction;
    _yogaNodeSetBaselineFunc =
        module['yogaNodeSetBaselineFunc'] as js.JSFunction;
    _yogaNodeClearBaselineFunc =
        module['yogaNodeClearBaselineFunc'] as js.JSFunction;
    _yogaNodeMarkDirty = module['_yogaNodeMarkDirty'] as js.JSFunction;
    _yogaNodeInsertChild = module['_yogaNodeInsertChild'] as js.JSFunction;
    _yogaNodeRemoveChild = module['_yogaNodeRemoveChild'] as js.JSFunction;
    _yogaNodeClearChildren = module['_yogaNodeClearChildren'] as js.JSFunction;
    _yogaNodeSetStyle = module['_yogaNodeSetStyle'] as js.JSFunction;
    _yogaNodeGetType = module['_yogaNodeGetType'] as js.JSFunction;
    _yogaNodeSetType = module['_yogaNodeSetType'] as js.JSFunction;
    _yogaNodeCheckAndResetUpdated =
        module['_yogaNodeCheckAndResetUpdated'] as js.JSFunction;
  }
}

LayoutValue _layoutValueFromJs(dynamic data) {
  if (data is js.JSObject) {
    return LayoutValue(
      value: data['value'] as double,
      unit: LayoutUnit.values[data['unit'] as int],
    );
  }
  return const LayoutValue.undefined();
}

class LayoutStyleWasm extends LayoutStyle {
  static final Finalizer<int> _finalizer = Finalizer(
    (nativePtr) => _disposeYogaStyle.callAsFunction(
      null,
      nativePtr.toJS,
    ),
  );
  int _nativePtr;

  LayoutStyleWasm(this._nativePtr) {
    _finalizer.attach(this, _nativePtr, detach: this);
  }

  @override
  void dispose() {
    _disposeYogaStyle.callAsFunction(null, _nativePtr.toJS);
    _nativePtr = 0;
    _finalizer.detach(this);
  }

  @override
  LayoutAlign get alignContent => LayoutAlign.values[(_yogaStyleGetAlignContent
          .callAsFunction(null, _nativePtr.toJS) as js.JSNumber)
      .toDartInt];

  @override
  set alignContent(LayoutAlign value) => _yogaStyleSetAlignContent
      .callAsFunction(null, _nativePtr.toJS, value.index.toJS);

  @override
  LayoutDirection get direction => LayoutDirection.values[
      (_yogaStyleGetDirection.callAsFunction(null, _nativePtr.toJS)
              as js.JSNumber)
          .toDartInt];

  @override
  set direction(LayoutDirection value) => _yogaStyleSetDirection.callAsFunction(
      null, _nativePtr.toJS, value.index.toJS);

  @override
  LayoutFlexDirection get flexDirection => LayoutFlexDirection.values[
      (_yogaStyleGetFlexDirection.callAsFunction(null, _nativePtr.toJS)
              as js.JSNumber)
          .toDartInt];

  @override
  set flexDirection(LayoutFlexDirection value) =>
      _yogaStyleSetFlexDirection.callAsFunction(
        null,
        _nativePtr.toJS,
        value.index.toJS,
      );

  @override
  LayoutJustify get justifyContent => LayoutJustify.values[
      (_yogaStyleGetJustifyContent.callAsFunction(null, _nativePtr.toJS)
              as js.JSNumber)
          .toDartInt];

  @override
  set justifyContent(LayoutJustify value) =>
      _yogaStyleSetJustifyContent.callAsFunction(
        null,
        _nativePtr.toJS,
        value.index.toJS,
      );

  @override
  LayoutAlign get alignItems => LayoutAlign.values[(_yogaStyleGetAlignItems
          .callAsFunction(null, _nativePtr.toJS) as js.JSNumber)
      .toDartInt];

  @override
  set alignItems(LayoutAlign value) => _yogaStyleSetAlignItems.callAsFunction(
      null, _nativePtr.toJS, value.index.toJS);

  @override
  LayoutAlign get alignSelf => LayoutAlign.values[(_yogaStyleGetAlignSelf
          .callAsFunction(null, _nativePtr.toJS) as js.JSNumber)
      .toDartInt];

  @override
  set alignSelf(LayoutAlign value) => _yogaStyleSetAlignSelf.callAsFunction(
      null, _nativePtr.toJS, value.index.toJS);

  @override
  LayoutPosition get positionType => LayoutPosition.values[
      (_yogaStyleGetPositionType.callAsFunction(null, _nativePtr.toJS)
              as js.JSNumber)
          .toDartInt];

  @override
  set positionType(LayoutPosition value) => _yogaStyleSetPositionType
      .callAsFunction(null, _nativePtr.toJS, value.index.toJS);

  @override
  LayoutWrap get flexWrap => LayoutWrap.values[(_yogaStyleGetFlexWrap
          .callAsFunction(null, _nativePtr.toJS) as js.JSNumber)
      .toDartInt];

  @override
  set flexWrap(LayoutWrap value) => _yogaStyleSetFlexWrap.callAsFunction(
      null, _nativePtr.toJS, value.index.toJS);

  @override
  LayoutOverflow get overflow => LayoutOverflow.values[(_yogaStyleGetOverflow
          .callAsFunction(null, _nativePtr.toJS) as js.JSNumber)
      .toDartInt];

  @override
  set overflow(LayoutOverflow value) => _yogaStyleSetOverflow.callAsFunction(
      null, _nativePtr.toJS, value.index.toJS);

  @override
  LayoutDisplay get display => LayoutDisplay.values[(_yogaStyleGetDisplay
          .callAsFunction(null, _nativePtr.toJS) as js.JSNumber)
      .toDartInt];

  @override
  set display(LayoutDisplay value) => _yogaStyleSetDisplay.callAsFunction(
      null, _nativePtr.toJS, value.index.toJS);

  @override
  double? get flex {
    double value =
        (_yogaStyleGetFlex.callAsFunction(null, _nativePtr.toJS) as js.JSNumber)
            .toDartDouble;
    if (value.isNaN) {
      return null;
    }
    return value;
  }

  @override
  set flex(double? value) => _yogaStyleSetFlex.callAsFunction(
        null,
        _nativePtr.toJS,
        (value ?? double.nan).toJS,
      );

  @override
  double? get flexGrow {
    double value = (_yogaStyleGetFlexGrow.callAsFunction(null, _nativePtr.toJS)
            as js.JSNumber)
        .toDartDouble;
    if (value.isNaN) {
      return null;
    }
    return value;
  }

  @override
  set flexGrow(double? value) => _yogaStyleSetFlexGrow.callAsFunction(
      null, _nativePtr.toJS, (value ?? double.nan).toJS);

  @override
  double? get flexShrink {
    double value = (_yogaStyleGetFlexShrink.callAsFunction(
            null, _nativePtr.toJS) as js.JSNumber)
        .toDartDouble;
    if (value.isNaN) {
      return null;
    }
    return value;
  }

  @override
  set flexShrink(double? value) => _yogaStyleSetFlexShrink.callAsFunction(
        null,
        _nativePtr.toJS,
        (value ?? double.nan).toJS,
      );

  @override
  LayoutValue get flexBasis => _layoutValueFromJs(
        _yogaStyleGetFlexBasis.callAsFunction(
          null,
          _nativePtr.toJS,
        ),
      );

  @override
  set flexBasis(LayoutValue value) => _yogaStyleSetFlexBasis.callAsFunction(
        null,
        _nativePtr.toJS,
        value.value.toJS,
        value.unit.index.toJS,
      );

  @override
  LayoutValue getMargin(LayoutEdge edge) => _layoutValueFromJs(
        _yogaStyleGetMargin.callAsFunction(
          null,
          _nativePtr.toJS,
          edge.index.toJS,
        ),
      );

  @override
  void setMargin(LayoutEdge edge, LayoutValue value) =>
      _yogaStyleSetMargin.callAsFunction(
        null,
        _nativePtr.toJS,
        edge.index.toJS,
        value.value.toJS,
        value.unit.index.toJS,
      );

  @override
  LayoutValue getPosition(LayoutEdge edge) => _layoutValueFromJs(
        _yogaStyleGetPosition.callAsFunction(
          null,
          _nativePtr.toJS,
          edge.index.toJS,
        ),
      );

  @override
  void setPosition(LayoutEdge edge, LayoutValue value) =>
      _yogaStyleSetPosition.callAsFunction(
        null,
        _nativePtr.toJS,
        edge.index.toJS,
        value.value.toJS,
        value.unit.index.toJS,
      );

  @override
  LayoutValue getPadding(LayoutEdge edge) => _layoutValueFromJs(
        _yogaStyleGetPadding.callAsFunction(
          null,
          _nativePtr.toJS,
          edge.index.toJS,
        ),
      );

  @override
  void setPadding(LayoutEdge edge, LayoutValue value) =>
      _yogaStyleSetPadding.callAsFunction(
        null,
        _nativePtr.toJS,
        edge.index.toJS,
        value.value.toJS,
        value.unit.index.toJS,
      );

  @override
  LayoutValue getBorder(LayoutEdge edge) => _layoutValueFromJs(
        _yogaStyleGetBorder.callAsFunction(
          null,
          _nativePtr.toJS,
          edge.index.toJS,
        ),
      );

  @override
  void setBorder(LayoutEdge edge, LayoutValue value) =>
      _yogaStyleSetBorder.callAsFunction(
        null,
        _nativePtr.toJS,
        edge.index.toJS,
        value.value.toJS,
        value.unit.index.toJS,
      );

  @override
  LayoutValue getGap(LayoutGutter gutter) => _layoutValueFromJs(
        _yogaStyleGetGap.callAsFunction(
          _nativePtr.toJS,
          gutter.index.toJS,
        ),
      );

  @override
  void setGap(LayoutGutter gutter, LayoutValue value) =>
      _yogaStyleSetGap.callAsFunction(
        null,
        _nativePtr.toJS,
        gutter.index.toJS,
        value.value.toJS,
        value.unit.index.toJS,
      );

  @override
  LayoutValue getDimension(LayoutDimension dimension) => _layoutValueFromJs(
        _yogaStyleGetDimension.callAsFunction(
          null,
          _nativePtr.toJS,
          dimension.index.toJS,
        ),
      );

  @override
  void setDimension(LayoutDimension dimension, LayoutValue value) =>
      _yogaStyleSetDimension.callAsFunction(
        null,
        _nativePtr.toJS,
        dimension.index.toJS,
        value.value.toJS,
        value.unit.index.toJS,
      );

  @override
  LayoutValue getMinDimension(LayoutDimension dimension) => _layoutValueFromJs(
        _yogaStyleGetMinDimension.callAsFunction(
          null,
          _nativePtr.toJS,
          dimension.index.toJS,
        ),
      );

  @override
  void setMinDimension(LayoutDimension dimension, LayoutValue value) =>
      _yogaStyleSetMinDimension.callAsFunction(
        null,
        _nativePtr.toJS,
        dimension.index.toJS,
        value.value.toJS,
        value.unit.index.toJS,
      );

  @override
  LayoutValue getMaxDimension(LayoutDimension dimension) => _layoutValueFromJs(
        _yogaStyleGetMaxDimension.callAsFunction(
          null,
          _nativePtr.toJS,
          dimension.index.toJS,
        ),
      );

  @override
  void setMaxDimension(LayoutDimension dimension, LayoutValue value) =>
      _yogaStyleSetMaxDimension.callAsFunction(
        null,
        _nativePtr.toJS,
        dimension.index.toJS,
        value.value.toJS,
        value.unit.index.toJS,
      );
}

class LayoutNodeWasm extends LayoutNode {
  static final Finalizer<int> _finalizer = Finalizer(
    (nativePtr) => _disposeYogaNode.callAsFunction(
      null,
      nativePtr.toJS,
    ),
  );

  int _nativePtr;
  final bool isOwned;
  LayoutNodeWasm(this._nativePtr, this.isOwned) {
    if (isOwned) {
      _finalizer.attach(this, _nativePtr, detach: this);
    }
  }

  @override
  void dispose() {
    if (isOwned) {
      _disposeYogaNode.callAsFunction(
        null,
        _nativePtr.toJS,
      );
      _finalizer.detach(this);
    }
    _callbackLookup.remove(_nativePtr);
    _nativePtr = 0;
  }

  @override
  void setStyle(LayoutStyle style) => _yogaNodeSetStyle.callAsFunction(
        null,
        _nativePtr.toJS,
        (style as LayoutStyleWasm)._nativePtr.toJS,
      );

  @override
  LayoutNodeType get nodeType => LayoutNodeType.values[
      (_yogaNodeGetType.callAsFunction(null, _nativePtr.toJS) as js.JSNumber)
          .toDartInt];

  @override
  set nodeType(LayoutNodeType value) => _yogaNodeSetType.callAsFunction(
        null,
        _nativePtr.toJS,
        value.index.toJS,
      );

  @override
  bool checkAndResetUpdated() =>
      (_yogaNodeCheckAndResetUpdated.callAsFunction(
        null,
        _nativePtr.toJS,
      ) as js.JSNumber)
          .toDartInt ==
      1;

  @override
  void calculateLayout(double availableWidth, double availableHeight,
          LayoutDirection direction) =>
      _yogaNodeCalculateLayout.callAsFunction(
        null,
        _nativePtr.toJS,
        availableWidth.toJS,
        availableHeight.toJS,
        direction.index.toJS,
      );

  @override
  Layout get layout {
    var data =
        _yogaNodeGetLayout.callAsFunction(null, _nativePtr.toJS) as js.JSObject;
    return Layout(
      (data['left'] as js.JSNumber).toDartDouble,
      (data['top'] as js.JSNumber).toDartDouble,
      (data['width'] as js.JSNumber).toDartDouble,
      (data['height'] as js.JSNumber).toDartDouble,
    );
  }

  @override
  LayoutPadding get layoutPadding {
    var data = _yogaNodeGetPadding.callAsFunction(null, _nativePtr.toJS)
        as js.JSObject;
    return LayoutPadding(
      (data['left'] as js.JSNumber).toDartDouble,
      (data['top'] as js.JSNumber).toDartDouble,
      (data['width'] as js.JSNumber).toDartDouble,
      (data['height'] as js.JSNumber).toDartDouble,
    );
  }

  @override
  void clearChildren() => _yogaNodeClearChildren.callAsFunction(
        null,
        _nativePtr.toJS,
      );

  @override
  void insertChild(LayoutNode node, int index) =>
      _yogaNodeInsertChild.callAsFunction(
        null,
        _nativePtr.toJS,
        (node as LayoutNodeWasm)._nativePtr.toJS,
        index.toJS,
      );

  @override
  void removeChild(LayoutNode node) => _yogaNodeRemoveChild.callAsFunction(
      null, _nativePtr.toJS, (node as LayoutNodeWasm)._nativePtr.toJS);

  // Store a hashmap to lookup pointer to layout nodes, necessary when using a
  // measure or baseline callback.
  static final HashMap<int, LayoutNodeWasm> _callbackLookup =
      HashMap<int, LayoutNodeWasm>();

  static js.JSFloat32Array _measureFunc(int nativeLayout, double width,
      int widthMode, double height, int heightMode) {
    var layoutNode = _callbackLookup[nativeLayout];
    if (layoutNode == null) {
      return Float32List.fromList([0, 0]).toJS;
    }
    var size = layoutNode.measureFunction != null
        ? layoutNode.measureFunction!.call(
            layoutNode,
            width,
            LayoutMeasureMode.values[widthMode],
            height,
            LayoutMeasureMode.values[heightMode])
        : Size.zero;
    return Float32List.fromList([size.width, size.height]).toJS;
  }

  MeasureFunction? _measureFunction;
  @override
  MeasureFunction? get measureFunction => _measureFunction;

  @override
  set measureFunction(MeasureFunction? value) {
    if (value == _measureFunction) {
      return;
    }
    _measureFunction = value;
    if (value == null) {
      _callbackLookup.remove(_nativePtr);
      _yogaNodeClearMeasureFunc.callAsFunction(null, _nativePtr.toJS);
    } else {
      _yogaNodeSetMeasureFunc.callAsFunction(
        null,
        _nativePtr.toJS,
        _measureFunc.toJS,
      );
      _callbackLookup[_nativePtr] = this;
    }
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
      _yogaNodeClearBaselineFunc.callAsFunction(
        null,
        _nativePtr.toJS,
      );
    } else {
      _yogaNodeSetBaselineFunc.callAsFunction(
        null,
        _nativePtr.toJS,
        (int nativeLayout, double width, double height) {
          var layoutNode = _callbackLookup[nativeLayout];
          if (layoutNode == null) {
            return Float32List.fromList([0, 0]).toJS;
          }
          return value(layoutNode, width, height).toJS;
        }.toJS,
      );
      _callbackLookup[_nativePtr] = this;
    }
  }

  @override
  void markDirty() => _yogaNodeMarkDirty.callAsFunction(
        null,
        _nativePtr.toJS,
      );
}

LayoutStyle makeLayoutStyle() =>
    LayoutStyleWasm((_makeYogaStyle.callAsFunction() as js.JSNumber).toDartInt);

LayoutNode makeLayoutNode() => LayoutNodeWasm(
    (_makeYogaNode.callAsFunction() as js.JSNumber).toDartInt, true);

LayoutNode makeLayoutNodeExternal(dynamic ref) =>
    LayoutNodeWasm(ref as int, false);

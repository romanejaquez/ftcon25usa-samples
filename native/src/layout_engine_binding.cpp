#include "yoga/YGNode.h"
#include "rive_native/external.hpp"

#include <stdio.h>
#include <cstdint>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include <emscripten/bind.h>
#include <emscripten/val.h>
#include <emscripten/html5.h>
using namespace emscripten;
struct NodeContext
{
    emscripten::val measureFunc;
    emscripten::val baselineFunc;
};
#endif
EXPORT YGStyle* makeYogaStyle() { return new YGStyle(); }

EXPORT void disposeYogaStyle(YGStyle* style) { delete style; }

EXPORT int yogaStyleGetAlignContent(YGStyle* style)
{
    if (style == nullptr)
    {
        return 0;
    }
    YGAlign align = style->alignContent();
    return (int)align;
}

EXPORT void yogaStyleSetAlignContent(YGStyle* style, int align)
{
    if (style == nullptr)
    {
        return;
    }
    style->alignContent() = (YGAlign)align;
}

EXPORT int yogaStyleGetDirection(YGStyle* style)
{
    if (style == nullptr)
    {
        return 0;
    }
    YGDirection direction = style->direction();
    return (int)direction;
}

EXPORT void yogaStyleSetDirection(YGStyle* style, int direction)
{
    if (style == nullptr)
    {
        return;
    }
    style->direction() = (YGDirection)direction;
}

EXPORT int yogaStyleGetFlexDirection(YGStyle* style)
{
    if (style == nullptr)
    {
        return 0;
    }
    YGFlexDirection flexDirection = style->flexDirection();
    return (int)flexDirection;
}

EXPORT void yogaStyleSetFlexDirection(YGStyle* style, int flexDirection)
{
    if (style == nullptr)
    {
        return;
    }
    style->flexDirection() = (YGFlexDirection)flexDirection;
}

EXPORT int yogaStyleGetJustifyContent(YGStyle* style)
{
    if (style == nullptr)
    {
        return 0;
    }
    YGJustify justify = style->justifyContent();
    return (int)justify;
}

EXPORT void yogaStyleSetJustifyContent(YGStyle* style, int justify)
{
    if (style == nullptr)
    {
        return;
    }
    style->justifyContent() = (YGJustify)justify;
}

EXPORT int yogaStyleGetAlignItems(YGStyle* style)
{
    if (style == nullptr)
    {
        return 0;
    }
    YGAlign align = style->alignItems();
    return (int)align;
}

EXPORT void yogaStyleSetAlignItems(YGStyle* style, int align)
{
    if (style == nullptr)
    {
        return;
    }
    style->alignItems() = (YGAlign)align;
}

EXPORT int yogaStyleGetAlignSelf(YGStyle* style)
{
    if (style == nullptr)
    {
        return 0;
    }
    YGAlign align = style->alignSelf();
    return (int)align;
}

EXPORT void yogaStyleSetAlignSelf(YGStyle* style, int align)
{
    if (style == nullptr)
    {
        return;
    }
    style->alignSelf() = (YGAlign)align;
}

EXPORT int yogaStyleGetPositionType(YGStyle* style)
{
    if (style == nullptr)
    {
        return 0;
    }
    YGPositionType position = style->positionType();
    return (int)position;
}

EXPORT void yogaStyleSetPositionType(YGStyle* style, int position)
{
    if (style == nullptr)
    {
        return;
    }
    style->positionType() = (YGPositionType)position;
}

EXPORT int yogaStyleGetFlexWrap(YGStyle* style)
{
    if (style == nullptr)
    {
        return 0;
    }
    YGWrap wrap = style->flexWrap();
    return (int)wrap;
}

EXPORT void yogaStyleSetFlexWrap(YGStyle* style, int wrap)
{
    if (style == nullptr)
    {
        return;
    }
    style->flexWrap() = (YGWrap)wrap;
}

EXPORT int yogaStyleGetOverflow(YGStyle* style)
{
    if (style == nullptr)
    {
        return 0;
    }
    YGOverflow overflow = style->overflow();
    return (int)overflow;
}

EXPORT void yogaStyleSetOverflow(YGStyle* style, int overflow)
{
    if (style == nullptr)
    {
        return;
    }
    style->overflow() = (YGOverflow)overflow;
}

EXPORT int yogaStyleGetDisplay(YGStyle* style)
{
    if (style == nullptr)
    {
        return 0;
    }
    YGDisplay display = style->display();
    return (int)display;
}

EXPORT void yogaStyleSetDisplay(YGStyle* style, int display)
{
    if (style == nullptr)
    {
        return;
    }
    style->display() = (YGDisplay)display;
}

EXPORT float yogaStyleGetFlex(YGStyle* style)
{
    if (style == nullptr)
    {
        return 0;
    }
    YGFloatOptional optional = style->flex();
    return optional.unwrap();
}

EXPORT void yogaStyleSetFlex(YGStyle* style, float flex)
{
    if (style == nullptr)
    {
        return;
    }
    style->flex() = YGFloatOptional(flex);
}

EXPORT float yogaStyleGetFlexGrow(YGStyle* style)
{
    if (style == nullptr)
    {
        return 0;
    }
    YGFloatOptional optional = style->flexGrow();
    return optional.unwrap();
}

EXPORT void yogaStyleSetFlexGrow(YGStyle* style, float flex)
{
    if (style == nullptr)
    {
        return;
    }
    style->flexGrow() = YGFloatOptional(flex);
}

EXPORT float yogaStyleGetFlexShrink(YGStyle* style)
{
    if (style == nullptr)
    {
        return 0;
    }
    YGFloatOptional optional = style->flexShrink();
    return optional.unwrap();
}

EXPORT void yogaStyleSetFlexShrink(YGStyle* style, float flex)
{
    if (style == nullptr)
    {
        return;
    }
    style->flexShrink() = YGFloatOptional(flex);
}

EXPORT void yogaStyleSetFlexBasis(YGStyle* style, float value, int unit)
{
    if (style == nullptr)
    {
        return;
    }
    style->flexBasis() = (YGValue){value, (YGUnit)unit};
}

EXPORT void yogaStyleSetMargin(YGStyle* style, int edge, float value, int unit)
{
    if (style == nullptr)
    {
        return;
    }
    style->margin()[(YGEdge)edge] = (YGValue){value, (YGUnit)unit};
}

EXPORT void yogaStyleSetPosition(YGStyle* style,
                                 int edge,
                                 float value,
                                 int unit)
{
    if (style == nullptr)
    {
        return;
    }
    style->position()[(YGEdge)edge] = (YGValue){value, (YGUnit)unit};
}

EXPORT void yogaStyleSetPadding(YGStyle* style, int edge, float value, int unit)
{
    if (style == nullptr)
    {
        return;
    }
    style->padding()[(YGEdge)edge] = (YGValue){value, (YGUnit)unit};
}

EXPORT void yogaStyleSetBorder(YGStyle* style, int edge, float value, int unit)
{
    if (style == nullptr)
    {
        return;
    }
    style->border()[(YGEdge)edge] = (YGValue){value, (YGUnit)unit};
}

EXPORT void yogaStyleSetGap(YGStyle* style, int gutter, float value, int unit)
{
    if (style == nullptr)
    {
        return;
    }
    style->gap()[(YGGutter)gutter] = (YGValue){value, (YGUnit)unit};
}

EXPORT void yogaStyleSetDimension(YGStyle* style,
                                  int dimension,
                                  float value,
                                  int unit)
{
    if (style == nullptr)
    {
        return;
    }
    style->dimensions()[(YGDimension)dimension] =
        (YGValue){value, (YGUnit)unit};
}

EXPORT void yogaStyleSetMinDimension(YGStyle* style,
                                     int dimension,
                                     float value,
                                     int unit)
{
    if (style == nullptr)
    {
        return;
    }
    style->minDimensions()[(YGDimension)dimension] =
        (YGValue){value, (YGUnit)unit};
}

EXPORT void yogaStyleSetMaxDimension(YGStyle* style,
                                     int dimension,
                                     float value,
                                     int unit)
{
    if (style == nullptr)
    {
        return;
    }
    style->maxDimensions()[(YGDimension)dimension] =
        (YGValue){value, (YGUnit)unit};
}

EXPORT YGNode* makeYogaNode()
{
    auto node = new YGNode();
    // Default to use fractional pixel values
    node->getConfig()->setPointScaleFactor(0);
    return node;
}

EXPORT bool yogaNodeCheckAndResetUpdated(YGNode* node)
{
    if (node == nullptr)
    {
        return false;
    }

    bool updated = node->getHasNewLayout();
    node->setHasNewLayout(false);
    return updated;
}

EXPORT void yogaNodeSetStyle(YGNode* node, YGStyle* style)
{
    if (node == nullptr)
    {
        return;
    }
    node->setStyle(*style);
}

EXPORT int yogaNodeGetType(YGNode* node)
{
    if (node == nullptr)
    {
        return 0;
    }
    return (int)node->getNodeType();
}

EXPORT void yogaNodeSetType(YGNode* node, int type)
{
    if (node == nullptr)
    {
        return;
    }
    node->setNodeType((YGNodeType)type);
}

EXPORT void yogaNodeInsertChild(YGNode* node, YGNode* child, int index)
{
    if (node == nullptr || child == nullptr)
    {
        return;
    }
    node->insertChild(child, index);
    child->setOwner(node);
    node->markDirtyAndPropagate();
}

EXPORT void yogaNodeRemoveChild(YGNode* node, YGNode* child)
{
    if (node == nullptr || child == nullptr)
    {
        return;
    }
    YGNodeRemoveChild(node, child);
}

EXPORT void yogaNodeClearChildren(YGNode* node)
{
    if (node == nullptr)
    {
        return;
    }
    YGNodeRemoveAllChildren(node);
}

EXPORT void yogaNodeCalculateLayout(YGNode* node,
                                    float availableWidth,
                                    float availableHeight,
                                    int direction)
{
    if (node == nullptr)
    {
        return;
    }
    YGNodeCalculateLayout(node,
                          availableWidth,
                          availableHeight,
                          (YGDirection)direction);
}

EXPORT void yogaNodeMarkDirty(YGNode* node)
{
    if (node == nullptr)
    {
        return;
    }

    node->markDirtyAndPropagate();
}

struct Layout
{
    float left;
    float top;
    float width;
    float height;
};

#ifdef __EMSCRIPTEN__
Layout yogaNodeGetLayout(WasmPtr nodePtr)
{
    YGNode* node = (YGNode*)nodePtr;
    if (node == nullptr)
    {
        return {};
    }
    return {YGNodeLayoutGetLeft(node),
            YGNodeLayoutGetTop(node),
            YGNodeLayoutGetWidth(node),
            YGNodeLayoutGetHeight(node)};
}
Layout yogaNodeGetPadding(WasmPtr nodePtr)
{
    YGNode* node = (YGNode*)nodePtr;
    if (node == nullptr)
    {
        return {};
    }
    return {YGNodeLayoutGetPadding(node, YGEdgeLeft),
            YGNodeLayoutGetPadding(node, YGEdgeTop),
            YGNodeLayoutGetPadding(node, YGEdgeRight),
            YGNodeLayoutGetPadding(node, YGEdgeBottom)};
}
YGValue yogaStyleGetFlexBasis(WasmPtr stylePtr)
{
    YGStyle* style = (YGStyle*)stylePtr;
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }
    facebook::yoga::detail::CompactValue compact = style->flexBasis();

    YGValue value = compact;
    return value;
}
YGValue yogaStyleGetMargin(WasmPtr stylePtr, int edge)
{
    YGStyle* style = (YGStyle*)stylePtr;
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }

    return style->margin()[(YGEdge)edge];
}
YGValue yogaStyleGetPosition(WasmPtr stylePtr, int edge)
{
    YGStyle* style = (YGStyle*)stylePtr;
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }

    return style->position()[(YGEdge)edge];
}
YGValue yogaStyleGetPadding(WasmPtr stylePtr, int edge)
{
    YGStyle* style = (YGStyle*)stylePtr;
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }

    return style->padding()[(YGEdge)edge];
}
YGValue yogaStyleGetGap(WasmPtr stylePtr, int gutter)
{
    YGStyle* style = (YGStyle*)stylePtr;
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }

    return style->gap()[(YGGutter)gutter];
}
YGValue yogaStyleGetBorder(WasmPtr stylePtr, int edge)
{
    YGStyle* style = (YGStyle*)stylePtr;
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }

    return style->border()[(YGEdge)edge];
}
YGValue yogaStyleGetDimension(WasmPtr stylePtr, int dimension)
{
    YGStyle* style = (YGStyle*)stylePtr;
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }

    return style->dimensions()[(YGDimension)dimension];
}
YGValue yogaStyleGetMinDimension(WasmPtr stylePtr, int dimension)
{
    YGStyle* style = (YGStyle*)stylePtr;
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }

    return style->minDimensions()[(YGDimension)dimension];
}
YGValue yogaStyleGetMaxDimension(WasmPtr stylePtr, int dimension)
{
    YGStyle* style = (YGStyle*)stylePtr;
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }

    return style->maxDimensions()[(YGDimension)dimension];
}
static YGSize _measureFunc(YGNode* node,
                           float width,
                           YGMeasureMode widthMode,
                           float height,
                           YGMeasureMode heightMode)
{
    auto nodeContext = (NodeContext*)node->getContext();
    assert(nodeContext != nullptr);

    emscripten::val result = nodeContext->measureFunc((WasmPtr)node,
                                                      width,
                                                      (int)widthMode,
                                                      height,
                                                      (int)heightMode);
    return {result[0].as<float>(), result[1].as<float>()};
}
static float _baselineFunc(YGNode* node, float width, float height)
{
    auto nodeContext = (NodeContext*)node->getContext();
    assert(nodeContext != nullptr);

    emscripten::val result =
        nodeContext->baselineFunc((WasmPtr)node, width, height);
    return result.as<float>();
}
EXPORT void yogaNodeSetMeasureFunc(WasmPtr nodePtr, emscripten::val measureFunc)
{
    YGNode* node = (YGNode*)nodePtr;
    if (node == nullptr)
    {
        return;
    }
    auto context = (NodeContext*)node->getContext();
    if (context == nullptr)
    {
        context = new NodeContext();
        node->setContext(context);
    }
    context->measureFunc = measureFunc;

    node->setMeasureFunc(_measureFunc);
}
EXPORT void yogaNodeClearMeasureFunc(WasmPtr nodePtr)
{
    YGNode* node = (YGNode*)nodePtr;
    if (node == nullptr)
    {
        return;
    }
    node->setMeasureFunc(nullptr);
}
EXPORT void yogaNodeSetBaselineFunc(WasmPtr nodePtr,
                                    emscripten::val baselineFunc)
{
    YGNode* node = (YGNode*)nodePtr;
    if (node == nullptr)
    {
        return;
    }
    auto context = (NodeContext*)node->getContext();
    if (context == nullptr)
    {
        context = new NodeContext();
        node->setContext(context);
    }
    context->baselineFunc = baselineFunc;

    node->setBaselineFunc(_baselineFunc);
}
EXPORT void yogaNodeClearBaselineFunc(WasmPtr nodePtr)
{
    YGNode* node = (YGNode*)nodePtr;
    if (node == nullptr)
    {
        return;
    }
    node->setBaselineFunc(nullptr);
}
EXPORT void disposeYogaNode(WasmPtr nodePtr)
{
    YGNode* node = (YGNode*)nodePtr;
    if (node == nullptr)
    {
        return;
    }
    delete (NodeContext*)node->getContext();
    delete node;
}

EMSCRIPTEN_BINDINGS(LayoutEngine)
{
    value_object<Layout>("Layout")
        .field("left", &Layout::left)
        .field("top", &Layout::top)
        .field("width", &Layout::width)
        .field("height", &Layout::height);

    value_object<YGValue>("YGValue")
        .field("value", &YGValue::value)
        .field("unit",
               optional_override(
                   [](const YGValue& self) -> int { return (int)self.unit; }),
               optional_override([](YGValue& self, int value) {
                   self.unit = (YGUnit)value;
               }));

    function("yogaNodeGetLayout", &yogaNodeGetLayout);
    function("yogaNodeGetPadding", &yogaNodeGetPadding);
    function("yogaStyleGetFlexBasis", &yogaStyleGetFlexBasis);
    function("yogaStyleGetMargin", &yogaStyleGetMargin);
    function("yogaStyleGetPosition", &yogaStyleGetPosition);
    function("yogaStyleGetPadding", &yogaStyleGetPadding);
    function("yogaStyleGetBorder", &yogaStyleGetBorder);
    function("yogaStyleGetGap", &yogaStyleGetGap);
    function("yogaStyleGetDimension", &yogaStyleGetDimension);
    function("yogaStyleGetMinDimension", &yogaStyleGetMinDimension);
    function("yogaStyleGetMaxDimension", &yogaStyleGetMaxDimension);
    function("yogaNodeSetMeasureFunc", &yogaNodeSetMeasureFunc);
    function("yogaNodeClearMeasureFunc", &yogaNodeClearMeasureFunc);
    function("yogaNodeSetBaselineFunc", &yogaNodeSetBaselineFunc);
    function("yogaNodeClearBaselineFunc", &yogaNodeClearBaselineFunc);
    function("disposeYogaNode", &disposeYogaNode);
}
#else
EXPORT Layout yogaNodeGetLayout(YGNode* node)
{
    if (node == nullptr)
    {
        return {};
    }

    return {YGNodeLayoutGetLeft(node),
            YGNodeLayoutGetTop(node),
            YGNodeLayoutGetWidth(node),
            YGNodeLayoutGetHeight(node)};
}
EXPORT Layout yogaNodeGetPadding(YGNode* node)
{
    if (node == nullptr)
    {
        return {};
    }
    return {YGNodeLayoutGetPadding(node, YGEdgeLeft),
            YGNodeLayoutGetPadding(node, YGEdgeTop),
            YGNodeLayoutGetPadding(node, YGEdgeRight),
            YGNodeLayoutGetPadding(node, YGEdgeBottom)};
}
EXPORT YGValue yogaStyleGetFlexBasis(YGStyle* style)
{
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }
    facebook::yoga::detail::CompactValue compact = style->flexBasis();

    YGValue value = compact;
    return value;
}
EXPORT YGValue yogaStyleGetMargin(YGStyle* style, int edge)
{
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }

    return style->margin()[(YGEdge)edge];
}
EXPORT YGValue yogaStyleGetPosition(YGStyle* style, int edge)
{
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }

    return style->position()[(YGEdge)edge];
}
EXPORT YGValue yogaStyleGetPadding(YGStyle* style, int edge)
{
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }

    return style->padding()[(YGEdge)edge];
}
EXPORT YGValue yogaStyleGetBorder(YGStyle* style, int edge)
{
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }

    return style->border()[(YGEdge)edge];
}
EXPORT YGValue yogaStyleGetGap(YGStyle* style, int gutter)
{
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }

    return style->gap()[(YGGutter)gutter];
}
EXPORT YGValue yogaStyleGetDimension(YGStyle* style, int dimension)
{
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }

    return style->dimensions()[(YGDimension)dimension];
}
EXPORT YGValue yogaStyleGetMinDimension(YGStyle* style, int dimension)
{
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }

    return style->minDimensions()[(YGDimension)dimension];
}
EXPORT YGValue yogaStyleGetMaxDimension(YGStyle* style, int dimension)
{
    if (style == nullptr)
    {
        return {0.0f, YGUnitAuto};
    }

    return style->maxDimensions()[(YGDimension)dimension];
}

EXPORT void yogaNodeSetMeasureFunc(YGNode* node, YGMeasureFunc measureFunc)
{
    if (node == nullptr)
    {
        return;
    }
    node->setMeasureFunc(measureFunc);
}

EXPORT void yogaNodeClearMeasureFunc(YGNode* node)
{
    if (node == nullptr)
    {
        return;
    }

    node->setMeasureFunc(nullptr);
}

EXPORT void yogaNodeSetBaselineFunc(YGNode* node, YGBaselineFunc baselineFunc)
{
    if (node == nullptr)
    {
        return;
    }

    node->setBaselineFunc(baselineFunc);
}

EXPORT void yogaNodeClearBaselineFunc(YGNode* node)
{
    if (node == nullptr)
    {
        return;
    }

    node->setBaselineFunc(nullptr);
}

EXPORT void disposeYogaNode(YGNode* node) { delete node; }
#endif
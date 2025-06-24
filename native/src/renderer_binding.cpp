#include "rive_native/external.hpp"
#include "rive_native/rive_binding.hpp"
#include "rive/shapes/paint/color.hpp"
#include "rive/core/binary_reader.hpp"
#include "rive/shapes/paint/trim_path.hpp"
#include "rive/shapes/paint/dash_path.hpp"
#include "renderer/src/rive_render_path.hpp"
#include "rive/math/hit_test.hpp"
#include "rive/math/path_measure.hpp"
#include "rive/shapes/paint/dash.hpp"

const rive::RawPath& renderPathToRawPath(rive::Factory* factory,
                                         rive::RenderPath* renderPath);
const rive::FillRule renderPathFillRule(rive::Factory* factory,
                                        rive::RenderPath* renderPath);

static rive::RawPath buildingPath;

static rive::Vec2D readVec2(rive::BinaryReader& reader)
{
    float x = reader.readFloat32();
    float y = reader.readFloat32();
    return rive::Vec2D(x, y);
}

const int scratchBufferSize = 1024;
EXPORT void appendCommands(uint8_t* memory, uint32_t commands)
{
    rive::BinaryReader reader(rive::Span<uint8_t>(memory, scratchBufferSize));
    for (int i = 0; i < commands; i++)
    {
        rive::PathVerb verb = (rive::PathVerb)reader.readByte();

        switch (verb)
        {
            case rive::PathVerb::move:
            {
                auto v = readVec2(reader);
                buildingPath.move(v);
                break;
            }
            case rive::PathVerb::line:
            {
                auto v = readVec2(reader);
                buildingPath.line(v);
                break;
            }
            case rive::PathVerb::quad:
            {
                auto control = readVec2(reader);
                auto to = readVec2(reader);
                buildingPath.quad(control, to);
                break;
            }
            case rive::PathVerb::cubic:
            {
                auto control1 = readVec2(reader);
                auto control2 = readVec2(reader);
                auto to = readVec2(reader);
                buildingPath.cubic(control1, control2, to);
                break;
            }
            case rive::PathVerb::close:
                buildingPath.close();
                break;
        }
    }
}

class DashPathEffect : public rive::PathDasher
{
public:
    rive::ShapePaintPath* effectPath(const rive::ShapePaintPath* source)
    {
        return dash(source->rawPath(), &m_offset, m_dashes);
    }

    rive::ShapePaintPath* effectPath(const rive::RawPath* source)
    {
        return dash(source, &m_offset, m_dashes);
    }

    void offset(float value, bool isPercentage)
    {
        m_offset.length(value);
        m_offset.lengthIsPercentage(isPercentage);
        invalidateDash();
    }

    float offsetValue() { return m_offset.length(); }
    float offsetIsPercentage() { return m_offset.lengthIsPercentage(); }

    void clearDashes()
    {
        for (auto dash : m_dashes)
        {
            delete dash;
        }
        m_dashes.clear();
        invalidateDash();
    }

    void addDash(float value, bool percentage)
    {
        m_dashes.emplace_back(new rive::Dash(value, percentage));
        invalidateDash();
    }

    void invalidate() { invalidateSourcePath(); }

private:
    rive::Dash m_offset;
    std::vector<rive::Dash*> m_dashes;
};

EXPORT rive::RenderPath* dashPathEffectPath(rive::Factory* factory,
                                            DashPathEffect* dashPath,
                                            rive::RenderPath* renderPath)
{
    if (dashPath == nullptr || renderPath == nullptr)
    {
        return nullptr;
    }
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    const rive::RawPath& rawPath = renderPathToRawPath(factory, renderPath);
    auto resultPath = dashPath->effectPath(&rawPath);
    auto resultRenderPath = resultPath->renderPath(factory);
    resultRenderPath->ref();
    return resultRenderPath;
}

EXPORT DashPathEffect* makeDashPathEffect() { return new DashPathEffect(); }
EXPORT void deleteDashPathEffect(DashPathEffect* dashPath) { delete dashPath; }

EXPORT float dashPathEffectGetPathLength(DashPathEffect* dashPath)
{
    if (dashPath == nullptr)
    {
        return 0.0f;
    }
    return dashPath->pathLength();
}

EXPORT void dashPathEffectSetOffset(DashPathEffect* dashPath, float offset)
{
    if (dashPath == nullptr)
    {
        return;
    }
    dashPath->offset(offset, dashPath->offsetIsPercentage());
}

EXPORT float dashPathEffectGetOffset(DashPathEffect* dashPath)
{
    if (dashPath == nullptr)
    {
        return 0.0f;
    }
    return dashPath->offsetValue();
}

EXPORT void dashPathEffectSetOffsetIsPercentage(DashPathEffect* dashPath,
                                                bool isPercentage)
{
    if (dashPath == nullptr)
    {
        return;
    }
    dashPath->offset(dashPath->offsetValue(), isPercentage);
}

EXPORT bool dashPathEffectGetOffsetIsPercentage(DashPathEffect* dashPath)
{
    if (dashPath == nullptr)
    {
        return false;
    }
    return dashPath->offsetIsPercentage();
}

EXPORT void dashPathClearDashes(DashPathEffect* dashPath)
{
    if (dashPath == nullptr)
    {
        return;
    }
    dashPath->clearDashes();
}

EXPORT void dashPathAddDash(DashPathEffect* dashPath,
                            float distance,
                            bool isPercentage)
{
    if (dashPath == nullptr)
    {
        return;
    }
    dashPath->addDash(distance, isPercentage);
}

EXPORT void dashPathInvalidate(DashPathEffect* dashPath)
{
    if (dashPath == nullptr)
    {
        return;
    }
    dashPath->invalidate();
}

class EditorTrimPath : public rive::TrimPath
{
public:
    rive::ShapePaintPath* effectPath(const rive::RawPath* source)
    {
        if (m_path.hasRenderPath())
        {
            // Previous result hasn't been invalidated, it's still good.
            return &m_path;
        }

        trimPath(source);

        return &m_path;
    }
};
EXPORT EditorTrimPath* makeTrimPathEffect() { return new EditorTrimPath(); }

EXPORT void trimPathEffectSetStart(EditorTrimPath* trimPath, float start)
{
    if (trimPath == nullptr)
    {
        return;
    }
    trimPath->start(start);
}

EXPORT float trimPathEffectGetStart(EditorTrimPath* trimPath)
{
    if (trimPath == nullptr)
    {
        return 0.0f;
    }
    return trimPath->start();
}

EXPORT void trimPathEffectSetEnd(EditorTrimPath* trimPath, float end)
{
    if (trimPath == nullptr)
    {
        return;
    }
    trimPath->end(end);
}

EXPORT float trimPathEffectGetEnd(EditorTrimPath* trimPath)
{
    if (trimPath == nullptr)
    {
        return 0.0f;
    }
    return trimPath->end();
}

EXPORT void trimPathEffectSetOffset(EditorTrimPath* trimPath, float offset)
{
    if (trimPath == nullptr)
    {
        return;
    }
    trimPath->offset(offset);
}

EXPORT float trimPathEffectGetOffset(EditorTrimPath* trimPath)
{
    if (trimPath == nullptr)
    {
        return 0.0f;
    }
    return trimPath->offset();
}

EXPORT void trimPathEffectSetMode(EditorTrimPath* trimPath, uint8_t mode)
{
    if (trimPath == nullptr)
    {
        return;
    }
    trimPath->modeValue(mode);
}

EXPORT uint8_t trimPathEffectGetMode(EditorTrimPath* trimPath)
{
    if (trimPath == nullptr)
    {
        return 0;
    }
    return trimPath->modeValue();
}

EXPORT void trimPathEffectInvalidate(EditorTrimPath* trimPath)
{
    if (trimPath == nullptr)
    {
        return;
    }
    trimPath->invalidateEffect();
}

EXPORT void deleteTrimPathEffect(EditorTrimPath* trimPath) { delete trimPath; }

EXPORT rive::RenderPath* trimPathEffectPath(rive::Factory* factory,
                                            EditorTrimPath* trimPath,
                                            rive::RenderPath* renderPath)
{
    if (trimPath == nullptr || renderPath == nullptr)
    {
        return nullptr;
    }
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    const rive::RawPath& rawPath = renderPathToRawPath(factory, renderPath);
    auto resultPath = trimPath->effectPath(&rawPath);
    auto resultRenderPath = resultPath->renderPath(factory);
    resultRenderPath->ref();
    return resultRenderPath;
}

EXPORT void deleteRenderPath(rive::RenderPath* renderPath)
{
    if (renderPath == nullptr)
    {
        return;
    }
    renderPath->unref();
}

EXPORT rive::RenderPath* makeRenderPath(rive::Factory* factory)
{
    if (factory == nullptr)
    {
        factory = riveFactory();
    }

    rive::rcp<rive::RenderPath> renderPath =
        factory->makeRenderPath(buildingPath, rive::FillRule::nonZero);
    buildingPath.rewind();
    return renderPath.release();
}

EXPORT void appendRenderPath(rive::RenderPath* path)
{
    if (path == nullptr)
    {
        return;
    }
    buildingPath.addTo(path);
    buildingPath.rewind();
}

EXPORT rive::RenderPath* makeEmptyRenderPath(rive::Factory* factory)
{
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    rive::rcp<rive::RenderPath> renderPath = factory->makeEmptyRenderPath();
    return renderPath.release();
}

EXPORT void rewindRenderPath(rive::RenderPath* path)
{
    if (path == nullptr)
    {
        return;
    }
    path->rewind();
}

EXPORT void renderPathSetFillRule(rive::RenderPath* path, uint8_t fillRule)
{
    if (path == nullptr)
    {
        return;
    }
    path->fillRule((rive::FillRule)fillRule);
}

EXPORT void drawPath(rive::Renderer* renderer,
                     rive::RenderPath* path,
                     rive::RenderPaint* paint)
{
    if (renderer == nullptr || path == nullptr)
    {
        return;
    }
    renderer->drawPath(path, paint);
}

EXPORT void drawImage(rive::Renderer* renderer,
                      rive::RenderImage* image,
                      uint8_t blendModeValue,
                      float opacity)
{
    if (renderer == nullptr || image == nullptr)
    {
        return;
    }
    renderer->drawImage(image, (rive::BlendMode)blendModeValue, opacity);
}

EXPORT void drawImageMesh(rive::Renderer* renderer,
                          rive::RenderImage* image,
                          rive::RenderBuffer* vertices,
                          rive::RenderBuffer* uvs,
                          rive::RenderBuffer* indices,
                          uint32_t vertexCount,
                          uint32_t indexCount,
                          uint8_t blendModeValue,
                          float opacity)
{
    if (renderer == nullptr || image == nullptr || vertices == nullptr ||
        uvs == nullptr || indices == nullptr || indexCount == 0)
    {
        return;
    }
    renderer->drawImageMesh(image,
                            ref_rcp(vertices),
                            ref_rcp(uvs),
                            ref_rcp(indices),
                            vertexCount,
                            indexCount,
                            (rive::BlendMode)blendModeValue,
                            opacity);
}

EXPORT void clipPath(rive::Renderer* renderer, rive::RenderPath* path)
{
    if (path == nullptr || renderer == nullptr)
    {
        return;
    }
    renderer->clipPath(path);
}

EXPORT void save(rive::Renderer* renderer)
{
    if (renderer == nullptr)
    {
        return;
    }
    renderer->save();
}

EXPORT void restore(rive::Renderer* renderer)
{
    if (renderer == nullptr)
    {
        return;
    }
    renderer->restore();
}

EXPORT void transform(rive::Renderer* renderer,
                      float x1,
                      float y1,
                      float x2,
                      float y2,
                      float tx,
                      float ty)
{
    if (renderer == nullptr)
    {
        return;
    }
    rive::Mat2D matrix(x1, y1, x2, y2, tx, ty);
    renderer->transform(matrix);
}

EXPORT void addRawPath(rive::RenderPath* to, rive::RawPath* rawPath)
{
    if (to == nullptr || rawPath == nullptr)
    {
        return;
    }
    rawPath->addTo(to);
}

EXPORT void addRawPathWithTransform(rive::RenderPath* to,
                                    rive::RawPath* rawPath,
                                    float x1,
                                    float y1,
                                    float x2,
                                    float y2,
                                    float tx,
                                    float ty)
{
    if (to == nullptr || rawPath == nullptr)
    {
        return;
    }
    rive::Mat2D matrix(x1, y1, x2, y2, tx, ty);
    rawPath->transform(matrix).addTo(to);
}

EXPORT void addRawPathWithTransformClockwise(rive::RenderPath* to,
                                             rive::RawPath* rawPath,
                                             float x1,
                                             float y1,
                                             float x2,
                                             float y2,
                                             float tx,
                                             float ty)
{
    if (to == nullptr || rawPath == nullptr)
    {
        return;
    }
    // Assumes rawPath is clockwise already.
    rive::Mat2D matrix(x1, y1, x2, y2, tx, ty);
    if (matrix.determinant() >= 0)
    {
        rawPath->transform(matrix).addTo(to);
    }
    else
    {
        rive::RawPath scratchPath;
        scratchPath.addPathBackwards(*rawPath, &matrix);
        scratchPath.addTo(to);
    }
}

EXPORT void addPath(rive::RenderPath* to,
                    rive::RenderPath* path,
                    float x1,
                    float y1,
                    float x2,
                    float y2,
                    float tx,
                    float ty)
{
    rive::Mat2D matrix(x1, y1, x2, y2, tx, ty);
    to->addPath(path, matrix);
}

EXPORT void addPathBackwards(rive::Factory* factory,
                             rive::RenderPath* to,
                             rive::RenderPath* path,
                             float x1,
                             float y1,
                             float x2,
                             float y2,
                             float tx,
                             float ty)
{
    if (to == nullptr || path == nullptr)
    {
        return;
    }
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    const rive::RawPath& rawPath = renderPathToRawPath(factory, path);
    rive::RawPath backwardsRawPath;
    rive::Mat2D matrix(x1, y1, x2, y2, tx, ty);
    if (rawPath.empty())
    {
        return;
    }

    backwardsRawPath.addPathBackwards(rawPath, &matrix);
    backwardsRawPath.addTo(to);
}

EXPORT rive::RenderPaint* makeRenderPaint(rive::Factory* factory)
{
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    rive::rcp<rive::RenderPaint> paint = factory->makeRenderPaint();
    return paint.release();
}

EXPORT void deleteRenderPaint(rive::RenderPaint* paint) { delete paint; }

enum PaintDirt : uint16_t
{
    style = 1 << 0,
    color = 1 << 1,
    thickness = 1 << 2,
    join = 1 << 3,
    cap = 1 << 4,
    blendMode = 1 << 5,
    radial = 1 << 6, // 0 == linear, 1 == radial only valid if stops != 0
    done = 1 << 7,   // 1 when no more gradien stops will follow
    feather = 1 << 8
};

std::vector<rive::ColorInt> gradientColors;
std::vector<float> gradientStops;

EXPORT void updatePaint(rive::Factory* factory,
                        rive::RenderPaint* paint,
                        uint16_t flags,
                        const uint8_t* memory,
                        uint16_t stops)
{
    if (paint == nullptr)
    {
        return;
    }
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    // Update this if we change the buffer size in dart too.
    rive::BinaryReader reader(
        rive::Span<const uint8_t>(memory, scratchBufferSize));
    if ((flags & PaintDirt::style) != 0)
    {
        uint8_t style = reader.readByte();
        switch (style)
        {
            case 0:
                paint->style(rive::RenderPaintStyle::stroke);
                break;
            case 1:
                paint->style(rive::RenderPaintStyle::fill);
                break;
            case 2:
                paint->style(rive::RenderPaintStyle::fill);
                break;
        }
    }
    if ((flags & PaintDirt::color) != 0)
    {
        rive::ColorInt color = reader.readUint32();
        paint->color(color);
    }
    if ((flags & PaintDirt::thickness) != 0)
    {
        paint->thickness(reader.readFloat32());
    }
    if ((flags & PaintDirt::join) != 0)
    {
        paint->join((rive::StrokeJoin)reader.readByte());
    }
    if ((flags & PaintDirt::cap) != 0)
    {
        paint->cap((rive::StrokeCap)reader.readByte());
    }
    if ((flags & PaintDirt::blendMode) != 0)
    {
        uint8_t mode = reader.readByte();
        paint->blendMode(static_cast<rive::BlendMode>(mode));
    }
    // Flag meaning to remove the gradient.
    if (stops == 0xFFFF)
    {
        paint->shader(nullptr);
    }
    else if (stops != 0)
    {
        bool isRadial = (flags & PaintDirt::radial) != 0;

        for (int i = 0; i < stops; i++)
        {
            gradientStops.push_back(reader.readFloat32());
            gradientColors.push_back((rive::ColorInt)reader.readUint32());
        }
        if ((flags & PaintDirt::done) != 0)
        {
            // Offsets packed at end
            if (isRadial)
            {
                float cx = reader.readFloat32();
                float cy = reader.readFloat32();
                float radius = reader.readFloat32();
                paint->shader(
                    factory->makeRadialGradient(cx,
                                                cy,
                                                radius,
                                                gradientColors.data(),
                                                gradientStops.data(),
                                                gradientColors.size()));
            }
            else
            {
                float sx = reader.readFloat32();
                float sy = reader.readFloat32();
                float ex = reader.readFloat32();
                float ey = reader.readFloat32();
                paint->shader(
                    factory->makeLinearGradient(sx,
                                                sy,
                                                ex,
                                                ey,
                                                gradientColors.data(),
                                                gradientStops.data(),
                                                gradientColors.size()));
            }
            gradientStops.clear();
            gradientColors.clear();
        }
    }
    if ((flags & PaintDirt::feather) != 0)
    {
        paint->feather(reader.readFloat32());
    }
}

EXPORT rive::RenderImage* decodeRenderImage(rive::Factory* factory,
                                            const uint8_t* bytes,
                                            uint64_t length)
{
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    auto image = factory->decodeImage(rive::Span(bytes, length));
    if (image)
    {
        return image.release();
    }
    return nullptr;
}

EXPORT int renderImageWidth(rive::RenderImage* image)
{
    if (image == nullptr)
    {
        return 0;
    }
    return image->width();
}

EXPORT int renderImageHeight(rive::RenderImage* image)
{
    if (image == nullptr)
    {
        return 0;
    }
    return image->height();
}

EXPORT void deleteRenderImage(rive::RenderImage* image)
{
    if (image == nullptr)
    {
        return;
    }
    image->unref();
}

EXPORT rive::RenderBuffer* makeVertexRenderBuffer(rive::Factory* factory,
                                                  uint32_t vertexCount)
{
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    return factory
        ->makeRenderBuffer(rive::RenderBufferType::vertex,
                           rive::RenderBufferFlags::none,
                           vertexCount * sizeof(rive::Vec2D))
        .release();
}

EXPORT rive::RenderBuffer* makeIndexRenderBuffer(rive::Factory* factory,
                                                 uint32_t indexCount)
{
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    return factory
        ->makeRenderBuffer(rive::RenderBufferType::index,
                           rive::RenderBufferFlags::none,
                           indexCount * sizeof(uint16_t))
        .release();
}

EXPORT void* mapRenderBuffer(rive::RenderBuffer* buffer)
{
    if (buffer == nullptr)
    {
        return nullptr;
    }
    return buffer->map();
}

EXPORT void unmapRenderBuffer(rive::RenderBuffer* buffer)
{
    if (buffer == nullptr)
    {
        return;
    }
    return buffer->unmap();
}

EXPORT void deleteRenderBuffer(rive::RenderBuffer* buffer)
{
    if (buffer == nullptr)
    {
        return;
    }
    buffer->unref();
}

EXPORT bool renderPathHitTest(rive::Factory* factory,
                              rive::RenderPath* renderPath,
                              float x,
                              float y,
                              float hitRadius,
                              float x1,
                              float y1,
                              float x2,
                              float y2,
                              float tx,
                              float ty)
{
    if (renderPath == nullptr)
    {
        return false;
    }
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    const rive::RawPath& rawPath = renderPathToRawPath(factory, renderPath);
    rive::Mat2D transform(x1, y1, x2, y2, tx, ty);

    auto hitArea =
        rive::AABB(x - hitRadius, y - hitRadius, x + hitRadius, y + hitRadius)
            .round();

    rive::HitTester tester(hitArea);
    for (auto iter : rawPath)
    {
        rive::PathVerb verb = std::get<0>(iter);
        const rive::Vec2D* pts = std::get<1>(iter);
        switch (verb)
        {
            case rive::PathVerb::move:
                tester.move(transform * pts[0]);
                break;
            case rive::PathVerb::line:
                tester.line(transform * pts[1]);
                break;
            case rive::PathVerb::cubic:
                tester.cubic(transform * pts[1],
                             transform * pts[2],
                             transform * pts[3]);
                break;
            case rive::PathVerb::close:
                tester.close();
                break;
            case rive::PathVerb::quad:
                tester.cubic(
                    transform * rive::Vec2D::lerp(pts[0], pts[1], 2 / 3.f),
                    transform * rive::Vec2D::lerp(pts[2], pts[1], 2 / 3.f),
                    transform * pts[2]);
                break;
        }
    }

    return tester.test(renderPathFillRule(factory, renderPath));
}

EXPORT bool renderPathIsClockwise(rive::Factory* factory,
                                  rive::RenderPath* renderPath,
                                  float matrixDeterminant)
{
    if (renderPath == nullptr)
    {
        return false;
    }
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    const rive::RawPath& rawPath = renderPathToRawPath(factory, renderPath);
    return rawPath.computeCoarseArea() * matrixDeterminant >= 0;
}

EXPORT rive::PathMeasure* makePathMeasure(rive::Factory* factory,
                                          rive::RenderPath* renderPath,
                                          float tolerance)
{
    if (renderPath == nullptr)
    {
        return nullptr;
    }
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    const rive::RawPath& rawPath = renderPathToRawPath(factory, renderPath);
    return new rive::PathMeasure(&rawPath, tolerance);
}

EXPORT void deletePathMeasure(rive::PathMeasure* pathMeasure)
{
    delete pathMeasure;
}
EXPORT void pathMeasureAtDistance(rive::PathMeasure* pathMeasure,
                                  float distance,
                                  float* out)
{
    if (pathMeasure == nullptr)
    {
        return;
    }
    auto result = pathMeasure->atDistance(distance);
    memcpy(out, &result, sizeof(float) * 5);
}

EXPORT void pathMeasureAtPercentage(rive::PathMeasure* pathMeasure,
                                    float percentage,
                                    float* out)
{
    if (pathMeasure == nullptr)
    {
        return;
    }
    auto result = pathMeasure->atPercentage(percentage);
    memcpy(out, &result, sizeof(float) * 5);
}

EXPORT float pathMeasureLength(rive::PathMeasure* pathMeasure)
{
    if (pathMeasure == nullptr)
    {
        return 0.0f;
    }
    return pathMeasure->length();
}

EXPORT void renderPathPreciseBounds(rive::Factory* factory,
                                    rive::RenderPath* renderPath,
                                    float x1,
                                    float y1,
                                    float x2,
                                    float y2,
                                    float tx,
                                    float ty,
                                    float* out)
{
    if (renderPath == nullptr)
    {
        return;
    }
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    const rive::RawPath& rawPath = renderPathToRawPath(factory, renderPath);
    rive::Mat2D matrix(x1, y1, x2, y2, tx, ty);
    rive::AABB bounds = matrix != rive::Mat2D()
                            ? rawPath.transform(matrix).preciseBounds()
                            : rawPath.preciseBounds();
    memcpy(out, &bounds, sizeof(float) * 4);
}

EXPORT void renderPathBounds(rive::Factory* factory,
                             rive::RenderPath* renderPath,
                             float x1,
                             float y1,
                             float x2,
                             float y2,
                             float tx,
                             float ty,
                             float* out)
{
    if (renderPath == nullptr)
    {
        return;
    }
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    const rive::RawPath& rawPath = renderPathToRawPath(factory, renderPath);
    rive::Mat2D matrix(x1, y1, x2, y2, tx, ty);
    rive::AABB bounds = matrix != rive::Mat2D()
                            ? rawPath.transform(matrix).bounds()
                            : rawPath.bounds();
    memcpy(out, &bounds, sizeof(float) * 4);
}

EXPORT float renderPathPreciseLength(rive::Factory* factory,
                                     rive::RenderPath* renderPath,
                                     float x1,
                                     float y1,
                                     float x2,
                                     float y2,
                                     float tx,
                                     float ty)
{
    float l = 0.0;
    if (renderPath == nullptr)
    {
        return l;
    }
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    const rive::RawPath& rawPath = renderPathToRawPath(factory, renderPath);
    rive::Mat2D matrix(x1, y1, x2, y2, tx, ty);
    rive::RawPath source = rawPath.transform(matrix);
    rive::ContourMeasureIter iter(&source);
    while (auto contour = iter.next())
    {
        l += contour->length();
    }

    return l;
}

class ColinearCheck
{
public:
    const rive::Vec2D& pointA() { return m_pointA; }
    const rive::Vec2D& pointB() { return m_pointB; }

    bool addPoint(const rive::Vec2D& point)
    {
        if (m_pointCount == 0)
        {
            m_pointA = point;
            m_pointCount++;
        }
        else if (m_pointCount == 1)
        {
            m_pointB = point;
            auto diff = m_pointB - m_pointA;
            m_slope = diff.y / diff.x;
        }
        else
        {
            auto diff = point - m_pointA;
            auto slope = diff.y / diff.x;
            if (std::abs(m_slope - slope) >= 0.1f)
            {
                return false;
            }
        }

        return true;
    }

private:
    int m_pointCount = 0;
    rive::Vec2D m_pointA;
    rive::Vec2D m_pointB;
    float m_slope = 0.0f;
};

EXPORT bool renderPathColinearCheck(rive::Factory* factory,
                                    rive::RenderPath* renderPath,
                                    float* out)
{
    if (renderPath == nullptr)
    {
        return false;
    }
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    const rive::RawPath& rawPath = renderPathToRawPath(factory, renderPath);

    ColinearCheck check;
    for (auto point : rawPath.points())
    {
        if (!check.addPoint(point))
        {
            return false;
        }
    }
    memcpy(out, &check.pointA(), sizeof(float) * 2);
    memcpy(out + 2, &check.pointB(), sizeof(float) * 2);
    return true;
}

EXPORT bool renderPathIsClosed(rive::Factory* factory,
                               rive::RenderPath* renderPath)
{
    if (renderPath == nullptr)
    {
        return false;
    }
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    const rive::RawPath& rawPath = renderPathToRawPath(factory, renderPath);
    return rawPath.isClosed();
}

EXPORT bool renderPathHasBounds(rive::Factory* factory,
                                rive::RenderPath* renderPath)
{
    if (renderPath == nullptr)
    {
        return false;
    }
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    const rive::RawPath& rawPath = renderPathToRawPath(factory, renderPath);
    for (auto iter : rawPath)
    {
        rive::PathVerb verb = std::get<0>(iter);
        switch (verb)
        {
            case rive::PathVerb::move:
                return true;
            case rive::PathVerb::line:
                return true;
            case rive::PathVerb::cubic:
                return true;
            case rive::PathVerb::close:
                break;
            case rive::PathVerb::quad:
                return true;
        }
    }
    return false;
}

EXPORT int32_t renderPathCopyBuffers(rive::Factory* factory,
                                     rive::RenderPath* renderPath,
                                     uint8_t* verbBuffer,
                                     uint32_t verbBufferSize,
                                     float* pointBuffer,
                                     uint32_t pointBufferSize)
{
    if (renderPath == nullptr)
    {
        return false;
    }
    if (factory == nullptr)
    {
        factory = riveFactory();
    }
    const rive::RawPath& rawPath = renderPathToRawPath(factory, renderPath);
    if (verbBufferSize < (uint32_t)rawPath.verbs().size() ||
        pointBufferSize < (uint32_t)rawPath.points().size())
    {
        return -(int)rawPath.verbs().size();
    }
    memcpy((void*)verbBuffer,
           (void*)rawPath.verbs().data(),
           rawPath.verbs().size());
    memcpy((void*)pointBuffer,
           (void*)rawPath.points().data(),
           sizeof(float) * 2 * rawPath.points().size());

    return (int32_t)rawPath.verbs().size();
}

#if defined(__EMSCRIPTEN__)
EXPORT uint8_t* allocateBuffer(uint32_t size) { return new uint8_t[size]; }
EXPORT void deleteBuffer(uint8_t* buffer) { delete[] buffer; }
#endif

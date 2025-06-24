#include "rive_native/rive_binding.hpp"
#include "rive_native/external.hpp"
#include "rive/core/vector_binary_writer.hpp"
#include "renderer/src/rive_render_path.hpp"
#include <condition_variable>
#include <mutex>
#include <thread>
#include <deque>
#include <functional>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include <emscripten/bind.h>
#include <emscripten/val.h>
#include <emscripten/html5.h>
using namespace emscripten;
#endif

/// This file contains the code that's the counterpart to
/// flutter_renderer_ffi/web.dart. It allows the native C++ runtime to call up
/// to Flutter for rendering. This means it has to create
/// RenderPath/Paint/RenderBuffer wrappers that are proxies for their Flutter
/// counterparts. This is mostly done through callbacks registered in Dart to
/// Native that Native can call up.
using namespace rive;

#if !defined(__EMSCRIPTEN__)
/// Helper from deleting stuff in a way that's safe for Flutter Isolate model.
class DeleteHelper
{
public:
    void processDeletions()
    {
        std::unique_lock<std::mutex> lock(m_mutex);
        while (!m_work.empty())
        {
            auto work = m_work.front();
            m_work.pop_front();
            lock.unlock();
            work();
            lock.lock();
        }
    }

    void schedule(std::function<void()> callback)
    {
        std::unique_lock<std::mutex> lock(m_mutex);
        m_work.push_back(callback);
    }

    void clear()
    {
        std::unique_lock<std::mutex> lock(m_mutex);
        m_work.clear();
    }

    void lock() { m_mutex.lock(); }
    void unlock() { m_mutex.unlock(); }

private:
    std::mutex m_mutex;
    std::deque<std::function<void()>> m_work;
};

DeleteHelper g_deleteHelper;
EXPORT void processScheduledDeletions() { g_deleteHelper.processDeletions(); }
#endif

enum class FlutterGradientType
{
    linear,
    radial
};

class FlutterGradient : public LITE_RTTI_OVERRIDE(RenderShader, FlutterGradient)
{
public:
    FlutterGradient(FlutterGradientType type,
                    const ColorInt colors[], // [count]
                    const float stops[],     // [count]
                    size_t count) :
        m_type(type),
        m_colors(colors, colors + count),
        m_stops(stops, stops + count)
    {}
    FlutterGradientType type() const { return m_type; }
    const std::vector<ColorInt>& colors() const { return m_colors; }
    const std::vector<float>& stops() const { return m_stops; }

private:
    FlutterGradientType m_type;
    std::vector<ColorInt> m_colors;
    std::vector<float> m_stops;
};

class FlutterLinearGradient : public FlutterGradient
{
public:
    FlutterLinearGradient(float sx,
                          float sy,
                          float ex,
                          float ey,
                          const ColorInt colors[], // [count]
                          const float stops[],     // [count]
                          size_t count) :
        FlutterGradient(FlutterGradientType::linear, colors, stops, count),
        m_sx(sx),
        m_sy(sy),
        m_ex(ex),
        m_ey(ey)
    {}

    float sx() const { return m_sx; }
    float sy() const { return m_sy; }
    float ex() const { return m_ex; }
    float ey() const { return m_ey; }

private:
    float m_sx;
    float m_sy;
    float m_ex;
    float m_ey;
};

class FlutterRadialGradient : public FlutterGradient
{
public:
    FlutterRadialGradient(float cx,
                          float cy,
                          float radius,
                          const ColorInt colors[], // [count]
                          const float stops[],     // [count]
                          size_t count) :
        FlutterGradient(FlutterGradientType::radial, colors, stops, count),
        m_cx(cx),
        m_cy(cy),
        m_radius(radius)
    {}

    float cx() const { return m_cx; }
    float cy() const { return m_cy; }
    float radius() const { return m_radius; }

private:
    float m_cx;
    float m_cy;
    float m_radius;
};

#if defined(__EMSCRIPTEN__)
emscripten::val g_decodeRenderImage = val::null();
emscripten::val g_deleteRenderImage = val::null();
emscripten::val g_drawRenderPath = val::null();
emscripten::val g_drawRenderImage = val::null();
emscripten::val g_drawMesh = val::null();
emscripten::val g_updateRenderPath = val::null();
emscripten::val g_clipRenderPath = val::null();
emscripten::val g_save = val::null();
emscripten::val g_restore = val::null();
emscripten::val g_transform = val::null();
emscripten::val g_updateRenderPaint = val::null();
emscripten::val g_updateIndexBuffer = val::null();
emscripten::val g_updateVertexBuffer = val::null();
emscripten::val g_deleteRenderPath = val::null();
emscripten::val g_deleteRenderPaint = val::null();
emscripten::val g_deleteVertexBuffer = val::null();
emscripten::val g_deleteIndexBuffer = val::null();
emscripten::val g_deleteRenderer = val::null();

using DecodeRenderImage = emscripten::val;
using DeleteRenderImage = emscripten::val;
using FlutterDrawRenderPath = emscripten::val;
using FlutterDrawRenderImage = emscripten::val;
using FlutterDrawMesh = emscripten::val;
using FlutterUpdateRenderPath = emscripten::val;
using FlutterClipRenderPath = emscripten::val;
using FlutterSave = emscripten::val;
using FlutterRestore = emscripten::val;
using FlutterTransform = emscripten::val;
using FlutterUpdateRenderPaint = emscripten::val;
using FlutterUpdateIndexBuffer = emscripten::val;
using FlutterUpdateVertexBuffer = emscripten::val;
using DeleteRenderPath = emscripten::val;
using DeleteRenderPaint = emscripten::val;
using DeleteVertexBuffer = emscripten::val;
using DeleteIndexBuffer = emscripten::val;
using DeleteRenderer = emscripten::val;

#else

typedef void (*DecodeRenderImage)(RenderImage* image,
                                  uint64_t id,
                                  const uint8_t* bytes,
                                  size_t count);
typedef void (*DeleteRenderImage)(uint64_t image);
typedef void (*DeleteRenderer)(Renderer* renderer);
typedef void (*DeleteRenderPath)(uint64_t path);
typedef void (*DeleteRenderPaint)(uint64_t paint);
typedef void (*DeleteVertexBuffer)(uint64_t buffer);
typedef void (*DeleteIndexBuffer)(uint64_t buffer);

typedef void (*FlutterDrawRenderPath)(Renderer*, uint64_t path, uint64_t paint);
typedef void (*FlutterDrawRenderImage)(Renderer*,
                                       uint64_t,
                                       uint8_t blendMode,
                                       float opacity);
typedef void (*FlutterDrawMesh)(Renderer*,
                                uint64_t image,
                                uint64_t vertices,
                                uint64_t uvs,
                                uint64_t indices,
                                uint32_t vertexCount,
                                uint32_t indexCount,
                                uint8_t blendMode,
                                float opacity);
typedef void (*FlutterUpdateRenderPath)(uint64_t path,
                                        Vec2D* points,
                                        uint8_t* verbs,
                                        size_t count,
                                        uint8_t fillRule);
typedef void (*FlutterUpdateRenderPaint)(uint64_t paint,
                                         uint8_t* buffer,
                                         size_t size);
typedef void (*FlutterUpdateIndexBuffer)(uint64_t id,
                                         uint16_t* buffer,
                                         size_t size);
typedef void (*FlutterUpdateVertexBuffer)(uint64_t id,
                                          Vec2D* buffer,
                                          size_t size);
typedef void (*FlutterClipRenderPath)(Renderer*, uint64_t path);
typedef void (*FlutterSave)(Renderer*);
typedef void (*FlutterRestore)(Renderer*);
typedef void (*FlutterTransform)(Renderer*,
                                 float xx,
                                 float xy,
                                 float yx,
                                 float yy,
                                 float tx,
                                 float ty);

DecodeRenderImage g_decodeRenderImage = nullptr;
DeleteRenderImage g_deleteRenderImage = nullptr;
FlutterDrawRenderPath g_drawRenderPath = nullptr;
FlutterDrawRenderImage g_drawRenderImage = nullptr;
FlutterDrawMesh g_drawMesh = nullptr;
FlutterUpdateRenderPath g_updateRenderPath = nullptr;
FlutterClipRenderPath g_clipRenderPath = nullptr;
FlutterSave g_save = nullptr;
FlutterRestore g_restore = nullptr;
FlutterTransform g_transform = nullptr;
FlutterUpdateRenderPaint g_updateRenderPaint = nullptr;
FlutterUpdateIndexBuffer g_updateIndexBuffer = nullptr;
FlutterUpdateVertexBuffer g_updateVertexBuffer = nullptr;
DeleteRenderPath g_deleteRenderPath = nullptr;
DeleteRenderPaint g_deleteRenderPaint = nullptr;
DeleteVertexBuffer g_deleteVertexBuffer = nullptr;
DeleteIndexBuffer g_deleteIndexBuffer = nullptr;
DeleteRenderer g_deleteRenderer = nullptr;
#endif

class PaintDirt
{
public:
    static const uint32_t style = 1 << 0;
    static const uint32_t color = 1 << 1;
    static const uint32_t thickness = 1 << 2;
    static const uint32_t join = 1 << 3;
    static const uint32_t cap = 1 << 4;
    static const uint32_t blendMode = 1 << 5;
    static const uint32_t linear = 1 << 6;
    static const uint32_t radial = 1 << 7;
    static const uint32_t removeGradient = 1 << 8;
};

static const uint64_t maxId = 9007199254740991; // 2^53-1;
static uint64_t nextId(uint64_t& next)
{
    uint64_t id = next;
    if (next == maxId)
    {
        next = 1;
    }
    else
    {
        next++;
    }
    return id;
}

static uint64_t nextPaintId = 1;
static uint64_t nextPathId = 1;
static uint64_t nextVertexBufferId = 1;
static uint64_t nextIndexBufferId = 1;
static uint64_t nextImageId = 1;

class FlutterRenderPaint
    : public LITE_RTTI_OVERRIDE(RenderPaint, FlutterRenderPaint)
{

public:
    uint64_t m_id;
    FlutterRenderPaint() : m_id(nextId(nextPaintId)) {}

    ~FlutterRenderPaint()
    {
#if defined(__EMSCRIPTEN__)
        if (CALLBACK_VALID(g_deleteRenderPaint))
        {
            g_deleteRenderPaint(m_id);
        }
#else
        auto id = m_id;
        g_deleteHelper.schedule([id]() {
            if (CALLBACK_VALID(g_deleteRenderPaint))
            {
                g_deleteRenderPaint(id);
            }
        });
#endif
    }

    void style(RenderPaintStyle style) override
    {
        if (m_paintStyle == style)
        {
            return;
        }
        m_paintStyle = style;
        m_dirty |= PaintDirt::style;
    }

    void color(unsigned int value) override
    {
        if (m_color == value)
        {
            return;
        }
        m_color = value;
        m_dirty |= PaintDirt::color;
    }

    void thickness(float value) override
    {
        if (m_thickness == value)
        {
            return;
        }
        m_thickness = value;
        m_dirty |= PaintDirt::thickness;
    }

    void join(StrokeJoin value) override
    {
        if (m_join == value)
        {
            return;
        }
        m_join = value;
        m_dirty |= PaintDirt::join;
    }

    void cap(StrokeCap value) override
    {
        if (m_cap == value)
        {
            return;
        }
        m_cap = value;
        m_dirty |= PaintDirt::cap;
    }

    void blendMode(BlendMode value) override
    {
        if (m_blendMode == value)
        {
            return;
        }
        m_blendMode = value;
        m_dirty |= PaintDirt::blendMode;
    }

    void shader(rcp<RenderShader> shader) override
    {
        if (m_gradient == shader)
        {
            return;
        }

        m_gradient = nullptr;
        if (shader == nullptr)
        {
            m_dirty |= PaintDirt::removeGradient;
            return;
        }

        LITE_RTTI_CAST_OR_RETURN(flutterGradient,
                                 FlutterGradient*,
                                 shader.get());
        m_gradient = ref_rcp(flutterGradient);

        bool isRadial = m_gradient->type() == FlutterGradientType::radial;
        if (isRadial)
        {
            m_dirty |= PaintDirt::radial;
        }
        else
        {
            m_dirty |= PaintDirt::linear;
        }
    }

    void invalidateStroke() override {}

    void update(BinaryWriter& writer)
    {
        if (m_dirty == 0)
        {
            return;
        }
        writer.write((uint16_t)m_dirty);

        if ((m_dirty & PaintDirt::style) != 0)
        {
            writer.write(
                (uint8_t)(m_paintStyle == RenderPaintStyle::stroke ? 0 : 1));
        }
        if ((m_dirty & PaintDirt::color) != 0)
        {
            writer.write((uint32_t)m_color);
        }
        if ((m_dirty & PaintDirt::thickness) != 0)
        {
            writer.write((float)m_thickness);
        }
        if ((m_dirty & PaintDirt::join) != 0)
        {
            writer.write((uint8_t)m_join);
        }
        if ((m_dirty & PaintDirt::cap) != 0)
        {
            writer.write((uint8_t)m_cap);
        }
        if ((m_dirty & PaintDirt::blendMode) != 0)
        {
            writer.write((uint8_t)m_blendMode);
        }

        if ((m_dirty & (PaintDirt::linear | PaintDirt::radial)) != 0)
        {
            bool isRadial = m_gradient->type() == FlutterGradientType::radial;

            uint32_t size = (uint32_t)m_gradient->stops().size();
            writer.write(size);
            for (uint32_t i = 0; i < size; i++)
            {
                writer.write(m_gradient->stops()[i]);
                writer.write((uint32_t)m_gradient->colors()[i]);
            }

            if (isRadial)
            {
                auto radial =
                    static_cast<const FlutterRadialGradient*>(m_gradient.get());

                writer.write(radial->cx());
                writer.write(radial->cy());
                writer.write(radial->radius());
            }
            else
            {
                auto linear =
                    static_cast<const FlutterLinearGradient*>(m_gradient.get());

                writer.write(linear->sx());
                writer.write(linear->sy());
                writer.write(linear->ex());
                writer.write(linear->ey());
            }
        }

        m_dirty = 0;
    }

    bool isDirty() const { return m_dirty != 0; }

private:
    float m_thickness = 0.0f;
    RenderPaintStyle m_paintStyle = RenderPaintStyle::fill;
    unsigned int m_color = 0x000000ff;
    uint32_t m_dirty = 0;
    BlendMode m_blendMode;
    StrokeJoin m_join = StrokeJoin::bevel;
    StrokeCap m_cap = StrokeCap::butt;
    rcp<const FlutterGradient> m_gradient;
};

class FlutterRenderPath
    : public LITE_RTTI_OVERRIDE(RenderPath, FlutterRenderPath)
{
public:
    uint64_t m_id;
    FlutterRenderPath(FillRule fillRule, RawPath& rawPath) :
        m_id(nextId(nextPathId)), m_fillRule(fillRule)
    {
        m_rawPath.swap(rawPath);
        m_rawPath.pruneEmptySegments();
        m_isDirty = true;
    }
    FlutterRenderPath() : m_id(nextId(nextPathId)) {}

    ~FlutterRenderPath()
    {
#if defined(__EMSCRIPTEN__)
        if (CALLBACK_VALID(g_deleteRenderPath))
        {
            g_deleteRenderPath(m_id);
        }
#else
        auto obj = m_id;
        g_deleteHelper.schedule([obj]() {
            if (CALLBACK_VALID(g_deleteRenderPath))
            {
                g_deleteRenderPath(obj);
            }
        });
#endif
    }

    void update()
    {
        if (!m_isDirty || !CALLBACK_VALID(g_updateRenderPath))
        {
            return;
        }

        g_updateRenderPath(m_id,
                           CAST_POINTER(Vec2D*) m_rawPath.points().data(),
                           CAST_POINTER(uint8_t*) m_rawPath.verbs().data(),
                           CAST_SIZE m_rawPath.verbs().size(),
                           (uint8_t)m_fillRule);

        m_isDirty = false;
    }

    void rewind() override
    {
        m_rawPath.reset();
        m_isDirty = true;
    }

    void fillRule(FillRule rule) override
    {
        m_fillRule = rule;
        m_isDirty = true;
    }

    void moveTo(float x, float y) override
    {
        m_rawPath.moveTo(x, y);
        m_isDirty = true;
    }
    void lineTo(float x, float y) override
    {
        m_rawPath.lineTo(x, y);
        m_isDirty = true;
    }
    void cubicTo(float ox, float oy, float ix, float iy, float x, float y)
        override
    {
        m_rawPath.cubicTo(ox, oy, ix, iy, x, y);
        m_isDirty = true;
    }
    void close() override
    {
        m_rawPath.close();
        m_isDirty = true;
    }

    void addRenderPath(RenderPath* path, const Mat2D& matrix) override
    {
        LITE_RTTI_CAST_OR_RETURN(flutterPath, FlutterRenderPath*, path);

        RawPath::Iter transformedPathIter =
            m_rawPath.addPath(flutterPath->m_rawPath, &matrix);
        if (matrix != Mat2D())
        {
            // Prune any segments that became empty after the transform.
            m_rawPath.pruneEmptySegments(transformedPathIter);
        }
        m_isDirty = true;
    }

    void addRawPath(const RawPath& path) override
    {
        m_rawPath.addPath(path, nullptr);
    }

    const RawPath& getRawPath() const { return m_rawPath; }
    FillRule getFillRule() const { return m_fillRule; }

private:
    FillRule m_fillRule = FillRule::nonZero;
    RawPath m_rawPath;
    bool m_isDirty = false;
};

static rive::RawPath emptyPath;
const rive::RawPath& renderPathToRawPath(rive::Factory* factory,
                                         rive::RenderPath* renderPath)
{
    if (factory == riveFactory())
    {
        LITE_RTTI_CAST_OR_RETURN(riveRenderPath,
                                 rive::RiveRenderPath*,
                                 renderPath)
        emptyPath;
        return riveRenderPath->getRawPath();
    }
    LITE_RTTI_CAST_OR_RETURN(flutterRenderPath, FlutterRenderPath*, renderPath)
    emptyPath;
    return flutterRenderPath->getRawPath();
}

const rive::FillRule renderPathFillRule(rive::Factory* factory,
                                        rive::RenderPath* renderPath)
{
    if (factory == riveFactory())
    {
        LITE_RTTI_CAST_OR_RETURN(riveRenderPath,
                                 rive::RiveRenderPath*,
                                 renderPath)
        rive::FillRule::nonZero;
        return riveRenderPath->getFillRule();
    }
    LITE_RTTI_CAST_OR_RETURN(flutterRenderPath, FlutterRenderPath*, renderPath)
    rive::FillRule::nonZero;
    return flutterRenderPath->getFillRule();
}

/// Factory callbacks to allow native to create and destroy Flutter resources.
EXPORT void initFactoryCallbacks(DecodeRenderImage decodeRenderImage,
                                 DeleteRenderImage deleteRenderImage,
                                 FlutterDrawRenderPath drawRenderPath,
                                 FlutterDrawRenderImage drawRenderImage,
                                 FlutterDrawMesh drawMesh,
                                 FlutterUpdateRenderPath updateRenderPath,
                                 FlutterClipRenderPath clipRenderPath,
                                 FlutterSave save,
                                 FlutterRestore restore,
                                 FlutterTransform transform,
                                 FlutterUpdateRenderPaint updateRenderPaint,
                                 FlutterUpdateIndexBuffer updateIndexBuffer,
                                 FlutterUpdateVertexBuffer updateVertexBuffer,
                                 DeleteRenderPath deleteRenderPath,
                                 DeleteRenderPaint deleteRenderPaint,
                                 DeleteVertexBuffer deleteVertexBuffer,
                                 DeleteIndexBuffer deleteIndexBuffer,
                                 DeleteRenderer deleteRenderer)
{
#if !defined(__EMSCRIPTEN__)
    g_deleteHelper.lock();
#endif
    g_decodeRenderImage = decodeRenderImage;
    g_deleteRenderImage = deleteRenderImage;
    g_drawRenderPath = drawRenderPath;
    g_drawRenderImage = drawRenderImage;
    g_drawMesh = drawMesh;
    g_updateRenderPath = updateRenderPath;
    g_clipRenderPath = clipRenderPath;
    g_save = save;
    g_restore = restore;
    g_transform = transform;
    g_updateRenderPaint = updateRenderPaint;
    g_updateIndexBuffer = updateIndexBuffer;
    g_updateVertexBuffer = updateVertexBuffer;
    g_deleteRenderPath = deleteRenderPath;
    g_deleteRenderPaint = deleteRenderPaint;
    g_deleteVertexBuffer = deleteVertexBuffer;
    g_deleteIndexBuffer = deleteIndexBuffer;
    g_deleteRenderer = deleteRenderer;
#if !defined(__EMSCRIPTEN__)
    g_deleteHelper.unlock();
#endif
}

class FlutterVertexBuffer
    : public LITE_RTTI_OVERRIDE(RenderBuffer, FlutterVertexBuffer)
{

public:
    uint64_t m_id;
    FlutterVertexBuffer(RenderBufferType type,
                        RenderBufferFlags flags,
                        size_t sizeInBytes) :
        lite_rtti_override(type, flags, sizeInBytes),
        m_vertices(sizeInBytes / sizeof(Vec2D)),
        m_id(nextId(nextVertexBufferId))
    {}

    ~FlutterVertexBuffer()
    {
#if defined(__EMSCRIPTEN__)
        if (CALLBACK_VALID(g_deleteVertexBuffer))
        {
            g_deleteVertexBuffer(m_id);
        }
#else
        auto obj = m_id;
        g_deleteHelper.schedule([obj]() {
            if (CALLBACK_VALID(g_deleteVertexBuffer))
            {
                g_deleteVertexBuffer(obj);
            }
        });
#endif
    }

    void* onMap() override { return (void*)m_vertices.data(); }
    void onUnmap() override { m_isDirty = true; }

    void update()
    {
        if (!m_isDirty)
        {
            return;
        }
        g_updateVertexBuffer(m_id,
                             CAST_POINTER m_vertices.data(),
                             CAST_SIZE m_vertices.size());
        m_isDirty = false;
    }

private:
    bool m_isDirty = false;
    std::vector<Vec2D> m_vertices;
};

class FlutterIndexBuffer
    : public LITE_RTTI_OVERRIDE(RenderBuffer, FlutterIndexBuffer)
{
public:
    uint64_t m_id;
    FlutterIndexBuffer(RenderBufferType type,
                       RenderBufferFlags flags,
                       size_t sizeInBytes) :
        lite_rtti_override(type, flags, sizeInBytes),
        m_indices(sizeInBytes / sizeof(uint16_t)),
        m_id(nextId(nextIndexBufferId))
    {}

    ~FlutterIndexBuffer()
    {
#if defined(__EMSCRIPTEN__)
        if (CALLBACK_VALID(g_deleteIndexBuffer))
        {
            g_deleteIndexBuffer(m_id);
        }
#else
        auto obj = m_id;
        g_deleteHelper.schedule([obj]() {
            if (CALLBACK_VALID(g_deleteIndexBuffer))
            {
                g_deleteIndexBuffer(obj);
            }
        });
#endif
    }

    void* onMap() override { return (void*)m_indices.data(); }
    void onUnmap() override { m_isDirty = true; }

    void update()
    {
        if (!m_isDirty)
        {
            return;
        }
        g_updateIndexBuffer(m_id,
                            CAST_POINTER m_indices.data(),
                            CAST_SIZE m_indices.size());
        m_isDirty = false;
    }

private:
    bool m_isDirty = false;
    std::vector<uint16_t> m_indices;
};

class FlutterRenderImage
    : public LITE_RTTI_OVERRIDE(RenderImage, FlutterRenderImage)
{
public:
    uint64_t m_id;
    FlutterRenderImage() : m_id(nextId(nextImageId)) {}
    ~FlutterRenderImage()
    {
#if defined(__EMSCRIPTEN__)
        if (CALLBACK_VALID(g_deleteRenderImage))
        {
            g_deleteRenderImage(m_id);
        }
#else
        // Let Flutter know this id is gone.
        auto obj = m_id;
        g_deleteHelper.schedule([obj]() {
            if (CALLBACK_VALID(g_deleteRenderImage))
            {
                g_deleteRenderImage(obj);
            }
        });
#endif
    }

    void size(uint32_t width, uint32_t height)
    {
        m_Width = width;
        m_Height = height;
    }
};

EXPORT void renderImageSetSize(FlutterRenderImage* renderImage,
                               uint32_t width,
                               uint32_t height)
{
    if (renderImage == nullptr)
    {
        return;
    }
    renderImage->size(width, height);
}

class FlutterRenderer : public Renderer
{
public:
    ~FlutterRenderer()
    {
#if defined(__EMSCRIPTEN__)
        if (CALLBACK_VALID(g_deleteRenderer))
        {
            g_deleteRenderer(CAST_POINTER this);
        }
#else
        auto obj = this;
        g_deleteHelper.schedule([obj]() {
            if (CALLBACK_VALID(g_deleteRenderer))
            {
                g_deleteRenderer(obj);
            }
        });
#endif
    }
    void save() override
    {
        if (CALLBACK_VALID(g_save))
        {
            g_save(CAST_POINTER this);
        }
    }
    void restore() override
    {
        if (CALLBACK_VALID(g_restore))
        {
            g_restore(CAST_POINTER this);
        }
    }
    void transform(const Mat2D& transform) override
    {
        if (CALLBACK_VALID(g_transform))
        {
            g_transform(CAST_POINTER this,
                        transform.xx(),
                        transform.xy(),
                        transform.yx(),
                        transform.yy(),
                        transform.tx(),
                        transform.ty());
        }
    }

    void drawPath(RenderPath* path, RenderPaint* paint) override
    {
        LITE_RTTI_CAST_OR_RETURN(flutterPath, FlutterRenderPath*, path);
        LITE_RTTI_CAST_OR_RETURN(flutterPaint, FlutterRenderPaint*, paint);

        if (flutterPaint->isDirty())
        {
            m_buffer.clear();
            VectorBinaryWriter writer(&m_buffer);
            flutterPaint->update(writer);
            g_updateRenderPaint(flutterPaint->m_id,
                                CAST_POINTER m_buffer.data(),
                                CAST_SIZE m_buffer.size());
        }

        flutterPath->update();
        if (CALLBACK_VALID(g_drawRenderPath))
        {
            g_drawRenderPath(CAST_POINTER this,
                             flutterPath->m_id,
                             flutterPaint->m_id);
        }
    }

    void clipPath(RenderPath* path) override
    {
        LITE_RTTI_CAST_OR_RETURN(flutterPath, FlutterRenderPath*, path);

        flutterPath->update();
        if (CALLBACK_VALID(g_clipRenderPath))
        {
            g_clipRenderPath(CAST_POINTER this, flutterPath->m_id);
        }
    }

    void drawImage(const RenderImage* renderImage,
                   BlendMode blendMode,
                   float opacity) override
    {
        LITE_RTTI_CAST_OR_RETURN(flutterRenderImage,
                                 const FlutterRenderImage*,
                                 renderImage);
        if (CALLBACK_VALID(g_drawRenderImage))
        {
            g_drawRenderImage(CAST_POINTER this,
                              flutterRenderImage->m_id,
                              (uint8_t)blendMode,
                              opacity);
        }
    }

    void drawImageMesh(const RenderImage* image,
                       rcp<RenderBuffer> vertices_f32,
                       rcp<RenderBuffer> uvCoords_f32,
                       rcp<RenderBuffer> indices_u16,
                       uint32_t vertexCount,
                       uint32_t indexCount,
                       BlendMode blendMode,
                       float opacity) override
    {
        LITE_RTTI_CAST_OR_RETURN(flutterRenderImage,
                                 const FlutterRenderImage*,
                                 image);
        LITE_RTTI_CAST_OR_RETURN(flutterVertexBuffer,
                                 FlutterVertexBuffer*,
                                 vertices_f32.get());
        LITE_RTTI_CAST_OR_RETURN(flutterUVBuffer,
                                 FlutterVertexBuffer*,
                                 uvCoords_f32.get());
        LITE_RTTI_CAST_OR_RETURN(flutterIndexBuffer,
                                 FlutterIndexBuffer*,
                                 indices_u16.get());

        flutterVertexBuffer->update();
        flutterUVBuffer->update();
        flutterIndexBuffer->update();

        if (CALLBACK_VALID(g_drawMesh))
        {
            g_drawMesh(CAST_POINTER this,
                       flutterRenderImage->m_id,
                       flutterVertexBuffer->m_id,
                       flutterUVBuffer->m_id,
                       flutterIndexBuffer->m_id,
                       vertexCount,
                       indexCount,
                       (uint8_t)blendMode,
                       opacity);
        }
    }

    // Buffer for marshaling data.
    std::vector<uint8_t> m_buffer;
};

class FlutterFactory : public Factory
{
public:
    rcp<RenderBuffer> makeRenderBuffer(RenderBufferType type,
                                       RenderBufferFlags flags,
                                       size_t sizeInBytes) override
    {
        switch (type)
        {
            case RenderBufferType::index:
                return make_rcp<FlutterIndexBuffer>(type, flags, sizeInBytes);
            case RenderBufferType::vertex:
                return make_rcp<FlutterVertexBuffer>(type, flags, sizeInBytes);
            default:
                RIVE_UNREACHABLE();
        }
    }

    rcp<RenderShader> makeLinearGradient(float sx,
                                         float sy,
                                         float ex,
                                         float ey,
                                         const ColorInt colors[], // [count]
                                         const float stops[],     // [count]
                                         size_t count) override
    {
        return rcp(
            new FlutterLinearGradient(sx, sy, ex, ey, colors, stops, count));
    }

    rcp<RenderShader> makeRadialGradient(float cx,
                                         float cy,
                                         float radius,
                                         const ColorInt colors[], // [count]
                                         const float stops[],     // [count]
                                         size_t count) override
    {
        return rcp(
            new FlutterRadialGradient(cx, cy, radius, colors, stops, count));
    }

    rcp<RenderPath> makeRenderPath(RawPath& path, FillRule rule) override
    {
        return make_rcp<FlutterRenderPath>(rule, path);
    }

    rcp<RenderPath> makeEmptyRenderPath() override
    {
        return make_rcp<FlutterRenderPath>();
    }

    rcp<RenderPaint> makeRenderPaint() override
    {
        return make_rcp<FlutterRenderPaint>();
    }

    rcp<RenderImage> decodeImage(Span<const uint8_t> encoded) override
    {
        if (!CALLBACK_VALID(g_decodeRenderImage))
        {
            return nullptr;
        }
        auto image = make_rcp<FlutterRenderImage>();
        g_decodeRenderImage(CAST_POINTER image.get(),
                            image->m_id,
                            CAST_POINTER encoded.data(),
                            CAST_SIZE encoded.size());
        return image;
    }
};

EXPORT rive::RenderImage* makeFlutterRenderImage()
{
    auto image = make_rcp<FlutterRenderImage>();
    return image.release();
}

EXPORT uint64_t flutterRenderImageId(FlutterRenderImage* image)
{
    if (image == nullptr)
    {
        return 0;
    }
    return image->m_id;
}

EXPORT FlutterRenderer* makeFlutterRenderer() { return new FlutterRenderer(); }

EXPORT void deleteFlutterRenderer(FlutterRenderer* renderer)
{
    delete renderer;
}

EXPORT FlutterFactory* makeFlutterFactory() { return new FlutterFactory(); }

EXPORT void deleteFlutterFactory(FlutterFactory* factory)
{
    // The factory is a singleton in Flutter so it gets nuked during a hot
    // restart. We want to make sure any pending work tasks don't execute in
    // Flutter land.
#if !defined(__EMSCRIPTEN__)
    g_deleteHelper.clear();
    g_deleteHelper.lock();
#endif
    RESET_CALLBACK(g_decodeRenderImage);
    RESET_CALLBACK(g_deleteRenderImage);
    RESET_CALLBACK(g_drawRenderPath);
    RESET_CALLBACK(g_drawRenderImage);
    RESET_CALLBACK(g_drawMesh);
    RESET_CALLBACK(g_updateRenderPath);
    RESET_CALLBACK(g_clipRenderPath);
    RESET_CALLBACK(g_save);
    RESET_CALLBACK(g_restore);
    RESET_CALLBACK(g_transform);
    RESET_CALLBACK(g_updateRenderPaint);
    RESET_CALLBACK(g_updateIndexBuffer);
    RESET_CALLBACK(g_updateVertexBuffer);
    RESET_CALLBACK(g_deleteRenderPath);
    RESET_CALLBACK(g_deleteRenderPaint);
    RESET_CALLBACK(g_deleteVertexBuffer);
    RESET_CALLBACK(g_deleteIndexBuffer);
    delete factory;
#if !defined(__EMSCRIPTEN__)
    g_deleteHelper.unlock();
#endif
}

#ifdef __EMSCRIPTEN__
EMSCRIPTEN_BINDINGS(FlutterFactory)
{
    function("initFactoryCallbacks", &initFactoryCallbacks);
}
#endif

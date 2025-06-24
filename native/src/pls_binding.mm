#include "rive_native/external.hpp"
#include "rive_native/external_objc.h"
#include "rive_native/rive_binding.hpp"
#include "rive/renderer/metal/render_context_metal_impl.h"
#include "rive/renderer/rive_renderer.hpp"
#include "rive/renderer/rive_render_factory.hpp"
#include "rive/shapes/paint/color.hpp"
#include "rive/core/binary_reader.hpp"
#include <unordered_map>

rive::gpu::RenderContext* g_renderContext = nullptr;

/// Calls from the Flutter plugin come in on a different thread so we use a
// mutex to ensure we're destroying/creating rive renderers without concurrently
// changing our shared state.
std::mutex g_mutex;

#ifdef RIVE_NATIVE_SHARED
void preCommitCallback(id<MTLCommandBuffer> commandBuffer, int64_t textureId)
{
    // Intentionally empty/no-op for shared builds as they're used for testing.
}
#endif

rive::Factory* riveFactory()
{
#ifndef RIVE_NATIVE_SHARED
    // We build the shared lib for Flutter tests, having a null context here is
    // ok as we can't initalize the rive renderer for Flutter tests.
    assert(g_renderContext != nullptr);
#endif
    return g_renderContext;
}

class MetalTextureRenderer
{
public:
    MetalTextureRenderer(int64_t renderTextureId,
                         rive::gpu::RenderContext* renderContext,
                         id<MTLCommandQueue> queue,
                         ReadWriteRing* ring,
                         id<MTLTexture> texture0,
                         id<MTLTexture> texture1,
                         id<MTLTexture> texture2,
                         uint32_t width,
                         uint32_t height) :
        m_ring(ring),
        m_flutterRenderTextureId(renderTextureId),
        m_renderContext(renderContext),
        m_queue(queue),
        m_width(width),
        m_height(height)
    {
        auto renderCtxImpl =
            m_renderContext
                ->static_impl_cast<rive::gpu::RenderContextMetalImpl>();
        m_renderTarget[0] = renderCtxImpl->makeRenderTarget(
            MTLPixelFormatBGRA8Unorm, width, height);
        m_renderTarget[0]->setTargetTexture(texture0);
        m_renderTarget[1] = renderCtxImpl->makeRenderTarget(
            MTLPixelFormatBGRA8Unorm, width, height);
        m_renderTarget[1]->setTargetTexture(texture1);
        m_renderTarget[2] = renderCtxImpl->makeRenderTarget(
            MTLPixelFormatBGRA8Unorm, width, height);
        m_renderTarget[2]->setTargetTexture(texture2);
        m_renderer = std::make_unique<rive::RiveRenderer>(m_renderContext);
    }

    uint32_t m_currentWriteIndex = 0;
    void begin(uint32_t writeIndex, bool clear, uint32_t color)
    {
        m_currentWriteIndex = writeIndex;
        m_renderContext->beginFrame({
            .renderTargetWidth = m_width,
            .renderTargetHeight = m_height,
            .loadAction = clear ? rive::gpu::LoadAction::clear
                                : rive::gpu::LoadAction::preserveRenderTarget,
            .clearColor = color,
        });
    }

    id<MTLTexture> currentTargetTexture()
    {
        return m_renderTarget[m_currentWriteIndex]->targetTexture();
    }

    void end(float devicePixelRatio)
    {
        id<MTLCommandBuffer> flushCommandBuffer = [m_queue commandBuffer];
        m_renderContext->flush(
            {.renderTarget = m_renderTarget[m_currentWriteIndex].get(),
             .externalCommandBuffer = (__bridge void*)flushCommandBuffer});

        preCommitCallback(flushCommandBuffer, m_flutterRenderTextureId);
        [flushCommandBuffer commit];
    }

    int64_t flutterRenderTextureId() { return m_flutterRenderTextureId; }
    rive::RiveRenderer* renderer() { return m_renderer.get(); }
    uint32_t width() { return m_width; }
    uint32_t height() { return m_height; }

private:
    ReadWriteRing* m_ring;
    int64_t m_flutterRenderTextureId;
    id<MTLCommandQueue> m_queue;
    rive::gpu::RenderContext* m_renderContext;
    rive::rcp<rive::gpu::RenderTargetMetal> m_renderTarget[3];
    std::unique_ptr<rive::RiveRenderer> m_renderer;
    uint32_t m_width;
    uint32_t m_height;

public:
    ReadWriteRing* ring() { return m_ring; }
};

std::unordered_map<int64_t, MetalTextureRenderer*> g_contexts;

void* createRiveRendererContext(void* gpu)
{
    std::unique_lock<std::mutex> lock(g_mutex);
    g_renderContext = rive::gpu::RenderContextMetalImpl::MakeContext(
                          (__bridge id<MTLDevice>)gpu)
                          .release();
    return g_renderContext;
}
void destroyRiveRendererContext(void* context)
{
    std::unique_lock<std::mutex> lock(g_mutex);
    if (g_renderContext == context)
    {
        g_renderContext = nullptr;
    }
    delete (rive::gpu::RenderContext*)context;
}

void* createRiveRenderer(int64_t renderTextureId,
                         void* queue,
                         ReadWriteRing* ring,
                         void* texture0,
                         void* texture1,
                         void* texture2,
                         uint32_t width,
                         uint32_t height)
{
    std::unique_lock<std::mutex> lock(g_mutex);
    assert(g_renderContext != nullptr);
    MetalTextureRenderer* context =
        new MetalTextureRenderer(renderTextureId,
                                 g_renderContext,
                                 (__bridge id<MTLCommandQueue>)queue,
                                 ring,
                                 (__bridge id<MTLTexture>)texture0,
                                 (__bridge id<MTLTexture>)texture1,
                                 (__bridge id<MTLTexture>)texture2,
                                 width,
                                 height);
    g_contexts[renderTextureId] = context;
    return context;
}

MetalTextureRenderer* g_boundRenderer = nullptr;

void destroyRiveRenderer(void* renderer)
{
    std::unique_lock<std::mutex> lock(g_mutex);
    MetalTextureRenderer* pls = static_cast<MetalTextureRenderer*>(renderer);
    auto itr = g_contexts.find(pls->flutterRenderTextureId());
    if (itr != g_contexts.end())
    {
        g_contexts.erase(itr);
    }
    if (g_boundRenderer == pls)
    {
        g_boundRenderer = nullptr;
    }
    delete pls;
}

EXPORT void* currentNativeTexture()
{
    std::unique_lock<std::mutex> lock(g_mutex);
    assert(g_boundRenderer != nullptr);
    return (__bridge void*)g_boundRenderer->currentTargetTexture();
}

EXPORT rive::Renderer* boundRenderer()
{
    std::unique_lock<std::mutex> lock(g_mutex);
    assert(g_boundRenderer != nullptr);
    return g_boundRenderer->renderer();
}

int64_t getBoundTextureId()
{
    std::unique_lock<std::mutex> lock(g_mutex);
    return g_boundRenderer == nullptr
               ? -1
               : g_boundRenderer->flutterRenderTextureId();
}

EXPORT void clear(int64_t renderTextureId, bool clear, uint32_t color)
{
    std::unique_lock<std::mutex> lock(g_mutex);
    MetalTextureRenderer* pls = nullptr;
    auto itr = g_contexts.find(renderTextureId);
    if (itr != g_contexts.end())
    {
        g_boundRenderer = pls = itr->second;
        uint32_t writeIndex = pls->ring()->nextWrite();
        pls->begin(writeIndex, clear, color);
    }
    else
    {
        g_boundRenderer = nullptr;
    }
}

EXPORT void flush(float devicePixelRatio)
{
    std::unique_lock<std::mutex> lock(g_mutex);
    if (g_boundRenderer != nullptr)
    {
        g_boundRenderer->end(devicePixelRatio);
    }
}

id<MTLDevice> _metalDevice;
id<MTLCommandQueue> _metalCommandQueue;
void setGPU(void* gpu, void* queue)
{
    _metalDevice = (__bridge id<MTLDevice>)gpu;
    _metalCommandQueue = (__bridge id<MTLCommandQueue>)queue;
}

EXPORT void* getGPU() { return (__bridge void*)_metalDevice; }

EXPORT void* getQueue() { return (__bridge void*)_metalCommandQueue; }

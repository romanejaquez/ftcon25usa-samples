#include "rive_native/external.hpp"
#include "rive_native/rive_binding.hpp"
#include "rive/renderer/d3d/render_context_d3d_impl.hpp"
#include "rive/renderer/rive_renderer.hpp"
#include <unordered_map>
#include <d3d11_4.h>

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN 1
#endif
#include <Windows.h>

class WindowsContextPLS;
std::unordered_map<int64_t, WindowsContextPLS*> g_contexts;
rive::gpu::RenderContext* g_renderContext = nullptr;

rive::Factory* riveFactory()
{
    assert(g_renderContext != nullptr);
    return g_renderContext;
}

PLUGIN_API void shutdown()
{
    g_contexts.clear();
    g_renderContext = nullptr;
}

class WindowsContextPLS
{
public:
    WindowsContextPLS(void* userData,
                      rive::gpu::RenderContext* rendererContext,
                      int64_t renderTextureId,
                      FlutterWindowsSwapchain* swapchain,
                      uint32_t width,
                      uint32_t height,
                      RendererEndCallback rendererEndCallback) :
        m_flutterRenderTextureId(renderTextureId),
        m_swapchain(swapchain),
        m_renderContext(rendererContext),
        m_width(width),
        m_height(height),
        m_userData(userData),
        m_rendererEndCallback(rendererEndCallback)
    {
        auto renderCtxImpl =
            m_renderContext
                ->static_impl_cast<rive::gpu::RenderContextD3DImpl>();
        m_renderTarget = renderCtxImpl->makeRenderTarget(width, height);
        m_renderer = std::make_unique<rive::RiveRenderer>(m_renderContext);

        // Attempt to acquire the interfaces necessary for working with fences.
        renderCtxImpl->gpu()->QueryInterface(__uuidof(ID3D11Device5), &m_gpu5);
        renderCtxImpl->gpuContext()->QueryInterface(
            __uuidof(ID3D11DeviceContext4),
            &m_gpuContext4);
        if (m_gpu5 != nullptr && m_gpuContext4 != nullptr)
        {
            // Fences are supported. Create one to track the end of frames.
            VERIFY_OK(m_gpu5->CreateFence(m_lastFrameIndex,
                                          D3D11_FENCE_FLAG_NONE,
                                          __uuidof(ID3D11Fence),
                                          (void**)&m_lastFrameFence));
            m_fenceWaitThread = std::thread(FenceWaitThread, this);
        }
        else
        {
            // Fences are NOT supported. Create a query instead to track when
            // frames complete.
            D3D11_QUERY_DESC queryDesc{};
            queryDesc.Query = D3D11_QUERY_EVENT;
            renderCtxImpl->gpu()->CreateQuery(
                &queryDesc,
                m_fallbackCompletionQuery.ReleaseAndGetAddressOf());
        }
    }

    ~WindowsContextPLS()
    {
        if (m_lastFrameFence)
        {
            // Tell m_fenceWaitThread to terminate.
            {
                std::unique_lock lock(m_fenceWaitMutex);
                assert(m_activeFenceWaitIndex == 0);
                m_activeFenceWaitIndex = THREAD_TERMINATE_INDEX;
            }
            m_fenceWaitCond.notify_one();
            m_fenceWaitThread.join();
        }
    }

    void begin(bool clear, uint32_t color)
    {
        m_renderContext->beginFrame({
            .renderTargetWidth = m_width,
            .renderTargetHeight = m_height,
            .loadAction = clear ? rive::gpu::LoadAction::clear
                                : rive::gpu::LoadAction::preserveRenderTarget,
            .clearColor = color,
            .disableRasterOrdering = true,
        });
    }

    void end(float devicePixelRatio)
    {
        auto renderContextImpl =
            m_renderContext
                ->static_impl_cast<rive::gpu::RenderContextD3DImpl>();
        auto swapchainTexture = m_swapchain->acquireRenderTexture();

        m_renderTarget->setTargetTexture(swapchainTexture->nativeTexture.Get());

        if (m_lastFrameFence == nullptr)
        {
            // Fences are not supported. Begin a query track the current frame.
            renderContextImpl->gpuContext()->Begin(
                m_fallbackCompletionQuery.Get());
        }

        m_renderContext->flush({.renderTarget = m_renderTarget.get()});

        if (m_lastFrameFence != nullptr)
        {
            if (m_lastFrameIndex > 0)
            {
                // Block until m_fenceWaitThread has finished waiting on the
                // fence and has presented the previous frame texture.
                std::unique_lock lock(m_fenceWaitMutex);
                while (m_activeFenceWaitIndex != 0)
                {
                    m_fenceWaitCond.wait(lock);
                }
            }

            // Insert a fence for this frame.
            VERIFY_OK(m_gpuContext4->Signal(m_lastFrameFence.Get(),
                                            ++m_lastFrameIndex));
        }
        else
        {
            // End the query for this frame.
            renderContextImpl->gpuContext()->End(
                m_fallbackCompletionQuery.Get());
        }

        renderContextImpl->gpuContext()->Flush();
        m_lastFrameTexture = std::move(swapchainTexture);

        if (m_lastFrameFence != nullptr)
        {
            // Kick off m_fenceWaitThread to wait on this frame's fence and then
            // present the texture.
            {
                std::unique_lock lock(m_fenceWaitMutex);
                assert(m_activeFenceWaitIndex == 0);
                m_activeFenceWaitIndex = m_lastFrameIndex;
            }
            m_fenceWaitCond.notify_one();
        }
        else
        {
            // Query if the GPU has finished rendering this frame.
            while (renderContextImpl->gpuContext()->GetData(
                       m_fallbackCompletionQuery.Get(),
                       nullptr,
                       0,
                       0) == S_FALSE)
            {
                // Poll m_fallbackCompletionQuery until the GPU is done. This is
                // a blocking operation that will hurt performance, but we only
                // have to do it when fences aren't supported. Fences have been
                // in D3D11 since the Windows 10 Creators Update (Version 1703),
                // released April 2017.
                std::this_thread::sleep_for(std::chrono::microseconds(500));
            }

            // Present the frame here since we don't have a background thread to
            // do it.
            m_swapchain->presentTexture(std::move(m_lastFrameTexture));
            m_rendererEndCallback(m_userData);
        }
    }

    int64_t flutterRenderTextureId() { return m_flutterRenderTextureId; }
    rive::RiveRenderer* renderer() { return m_renderer.get(); }
    uint32_t width() { return m_width; }
    uint32_t height() { return m_height; }

private:
    static void FenceWaitThread(void* thisPtr)
    {
        reinterpret_cast<WindowsContextPLS*>(thisPtr)->fenceWaitThread();
    }

    void fenceWaitThread()
    {
        for (;;)
        {
            // Block until the main thread gives us a fence to wait on.
            {
                std::unique_lock lock(m_fenceWaitMutex);
                while (m_activeFenceWaitIndex == 0)
                {
                    m_fenceWaitCond.wait(lock);
                }
            }

            if (m_activeFenceWaitIndex == THREAD_TERMINATE_INDEX)
            {
                break;
            }

            // Wait until the fence completes.
            VERIFY_OK(
                m_lastFrameFence->SetEventOnCompletion(m_activeFenceWaitIndex,
                                                       nullptr));

            // Present the last texture now that the GPU has finished rendering
            // it.
            m_swapchain->presentTexture(std::move(m_lastFrameTexture));
            m_rendererEndCallback(m_userData);

            // Notify that the fence wait & present are complete.
            {
                std::unique_lock lock(m_fenceWaitMutex);
                m_activeFenceWaitIndex = 0;
            }
            m_fenceWaitCond.notify_one();
        }
    }

    int64_t m_flutterRenderTextureId;
    FlutterWindowsSwapchain* m_swapchain;
    rive::gpu::RenderContext* m_renderContext;
    rive::rcp<rive::gpu::RenderTargetD3D> m_renderTarget;
    std::unique_ptr<rive::RiveRenderer> m_renderer;
    uint32_t m_width;
    uint32_t m_height;
    void* m_userData;

    // Data for waiting on frame fences, if supported by the hardware.
    ComPtr<ID3D11Device5> m_gpu5;
    ComPtr<ID3D11DeviceContext4> m_gpuContext4;
    ComPtr<ID3D11Fence> m_lastFrameFence;
    std::mutex m_fenceWaitMutex;
    std::condition_variable m_fenceWaitCond;
    std::thread m_fenceWaitThread;
    std::unique_ptr<FlutterWindowsTexture> m_lastFrameTexture;
    uint64_t m_lastFrameIndex = 0;
    volatile uint64_t m_activeFenceWaitIndex = 0;
    constexpr static uint64_t THREAD_TERMINATE_INDEX = -1;

    // Used as a fallback when fences aren't supported.
    ComPtr<ID3D11Query> m_fallbackCompletionQuery;
    RendererEndCallback m_rendererEndCallback;
};

PLUGIN_API void* createRiveRendererContext(
    ComPtr<ID3D11Device> gpu,
    ComPtr<ID3D11DeviceContext> gpuContext,
    bool isIntel)
{
    rive::gpu::RenderContextD3DImpl::ContextOptions contextOptions;
    contextOptions.isIntel = isIntel;
    auto context = rive::gpu::RenderContextD3DImpl::MakeContext(gpu,
                                                                gpuContext,
                                                                contextOptions);

    return (void*)(g_renderContext = context.release());
}

PLUGIN_API void destroyRiveRendererContext(void* contextPtr)
{
    rive::gpu::RenderContext* context = (rive::gpu::RenderContext*)contextPtr;
    if (context == g_renderContext)
    {
        g_renderContext = nullptr;
    }
    delete context;
}

PLUGIN_API void* createRiveRenderer(void* userData,
                                    void* riveRendererContext,
                                    int64_t renderTextureId,
                                    FlutterWindowsSwapchain* swapchain,
                                    RendererEndCallback rendererEndCallback,
                                    uint32_t width,
                                    uint32_t height)
{
    WindowsContextPLS* context =
        new WindowsContextPLS(userData,
                              (rive::gpu::RenderContext*)riveRendererContext,
                              renderTextureId,
                              swapchain,
                              width,
                              height,
                              rendererEndCallback);
    g_contexts[renderTextureId] = context;
    return context;
}

WindowsContextPLS* g_boundContext = nullptr;

PLUGIN_API void destroyRiveRenderer(void* renderer)
{
    WindowsContextPLS* pls = static_cast<WindowsContextPLS*>(renderer);
    auto itr = g_contexts.find(pls->flutterRenderTextureId());
    if (itr != g_contexts.end())
    {
        g_contexts.erase(itr);
    }
    if (g_boundContext == pls)
    {
        g_boundContext = nullptr;
    }
    delete pls;
}

EXPORT rive::Renderer* boundRenderer()
{
    if (g_boundContext == nullptr)
    {
        return nullptr;
    }
    return g_boundContext->renderer();
}

PLUGIN_API int64_t getBoundTextureId()
{
    return g_boundContext == nullptr ? -1
                                     : g_boundContext->flutterRenderTextureId();
}

EXPORT void clear(int64_t renderTextureId, bool clear, uint32_t color)
{
    WindowsContextPLS* pls = nullptr;
    auto itr = g_contexts.find(renderTextureId);
    if (itr != g_contexts.end())
    {
        g_boundContext = pls = itr->second;
        pls->begin(clear, color);
    }
    else
    {
        g_boundContext = nullptr;
    }
}

EXPORT void flush(float devicePixelRatio)
{
    if (g_boundContext != nullptr)
    {
        g_boundContext->end(devicePixelRatio);
    }
}

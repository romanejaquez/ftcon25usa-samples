#ifndef RIVE_NATIVE_PLUGIN_H_
#define RIVE_NATIVE_PLUGIN_H_

#ifndef EGL_EGL_PROTOTYPES
#define EGL_EGL_PROTOTYPES 1
#endif

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/texture_registrar.h>
#include "rive_native/external.hpp"
#include "rive_native/swapchain.hpp"

#include <dxgi1_2.h>
#include <d3d11.h>
#include <wrl.h>
#include <unordered_map>

using Microsoft::WRL::ComPtr;

class RiveNativeRenderTexture
{
public:
    RiveNativeRenderTexture(ID3D11Device* gpu,
                            void* riveRendererContext,
                            uint32_t width,
                            uint32_t height,
                            flutter::TextureRegistrar* textureRegistrar);
    ~RiveNativeRenderTexture();
    int64_t id() const { return m_id; }

    void end();
    std::mutex m_mutex;

private:
    std::unique_ptr<FlutterWindowsTexture> makeSwapchainTexture(ID3D11Device*,
                                                                UINT width,
                                                                UINT height,
                                                                bool doClear);

    std::vector<FlutterDesktopGpuSurfaceDescriptor> m_flutterSurfaceDescs;
    FlutterWindowsSwapchain m_swapchain;

    std::unique_ptr<flutter::TextureVariant> m_textureVariant;
    flutter::TextureRegistrar* m_textureRegistrar;

    int64_t m_id;

    void* m_riveRenderer;
};

class RiveNativePlugin : public flutter::Plugin
{
public:
    flutter::MethodChannel<flutter::EncodableValue>* channel() const
    {
        return m_channel.get();
    }

    flutter::TextureRegistrar* textureRegistrar() const
    {
        return m_textureRegistrar;
    }

    static void RegisterWithRegistrar(
        flutter::PluginRegistrarWindows* registrar);

    RiveNativePlugin(
        flutter::PluginRegistrarWindows* registrar,
        std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
            channel,
        flutter::TextureRegistrar* texture_registrar);

    virtual ~RiveNativePlugin();

    RiveNativePlugin(const RiveNativePlugin&) = delete;
    RiveNativePlugin& operator=(const RiveNativePlugin&) = delete;

private:
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue>& method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    // std::unique_ptr<ANGLESurfaceManager> surface_manager_;

    // std::unique_ptr<FlutterDesktopGpuSurfaceDescriptor> texture_;
    // std::unique_ptr<flutter::TextureVariant> texture_variant_;

    flutter::PluginRegistrarWindows* m_registrar;
    flutter::TextureRegistrar* m_textureRegistrar;
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> m_channel;

    ComPtr<IDXGIFactory2> m_factory;
    ComPtr<ID3D11Device> m_gpu;
    ComPtr<ID3D11DeviceContext> m_gpuContext;
    bool m_isIntelGpu;
    void* m_riveRendererContext = nullptr;

    std::unordered_map<int64_t, RiveNativeRenderTexture*> m_renderTextures;
};

#endif

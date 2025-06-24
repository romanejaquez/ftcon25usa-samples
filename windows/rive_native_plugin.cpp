#include "rive_native/rive_native_plugin.hpp"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/texture_registrar.h>
#include <cstdint>

static void onRendererEnd(void* userData)
{
    auto renderer = (RiveNativeRenderTexture*)userData;
    renderer->end();
}

RiveNativeRenderTexture::RiveNativeRenderTexture(
    ID3D11Device* gpu,
    void* riveRendererContext,
    uint32_t width,
    uint32_t height,
    flutter::TextureRegistrar* textureRegistrar) :
    m_flutterSurfaceDescs(),
    m_swapchain(
        // Since we don't have control over synchronization with the Flutter
        // compositor, create a swapchain of *FOUR* textures in order to reduce
        // the likelihood of drawing on top of a texture while it's still being
        // read.
        makeSwapchainTexture(gpu,
                             width,
                             height,
                             /*doClear=*/true), // presentingTexture
        makeSwapchainTexture(gpu,
                             width,
                             height,
                             /*doClear=*/false), // renderTextures
        makeSwapchainTexture(gpu, width, height, /*doClear=*/false),
        makeSwapchainTexture(gpu, width, height, /*doClear=*/false)),
    m_textureRegistrar(textureRegistrar)
{
    m_textureVariant =
        std::make_unique<flutter::TextureVariant>(flutter::GpuSurfaceTexture(
            kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle,
            [this](auto, auto) {
                FlutterWindowsSwapchain::PresentingTextureLock
                    presentingTextureLock(&m_swapchain);
                return &m_flutterSurfaceDescs[presentingTextureLock.texture()
                                                  ->flutterSurfaceDescIdx];
            }));

    m_id = m_textureRegistrar->RegisterTexture(m_textureVariant.get());
    m_riveRenderer = createRiveRenderer(this,
                                        riveRendererContext,
                                        m_id,
                                        &m_swapchain,
                                        &onRendererEnd,
                                        width,
                                        height);
}

std::unique_ptr<FlutterWindowsTexture> RiveNativeRenderTexture::
    makeSwapchainTexture(ID3D11Device* gpu,
                         UINT width,
                         UINT height,
                         bool doClear)
{
    D3D11_TEXTURE2D_DESC desc{};
    desc.Width = width;
    desc.Height = height;
    desc.MipLevels = 1;
    desc.ArraySize = 1;
    desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    desc.SampleDesc.Count = 1;
    desc.SampleDesc.Quality = 0;
    desc.Usage = D3D11_USAGE_DEFAULT;
    desc.BindFlags = D3D11_BIND_UNORDERED_ACCESS | D3D11_BIND_SHADER_RESOURCE |
                     D3D11_BIND_RENDER_TARGET;
    desc.CPUAccessFlags = 0;
    desc.MiscFlags = D3D11_RESOURCE_MISC_SHARED;

    auto swapchainTexture = std::make_unique<FlutterWindowsTexture>();

    const D3D11_SUBRESOURCE_DATA* initialData = nullptr;
    std::vector<UINT> pixelData;
    D3D11_SUBRESOURCE_DATA initialDataStorage;
    if (doClear)
    {
        pixelData.resize(height * width);
        memset(pixelData.data(), 0, pixelData.size() * sizeof(UINT));
        initialDataStorage.pSysMem = pixelData.data();
        initialDataStorage.SysMemPitch = width * sizeof(UINT);
        initialData = &initialDataStorage;
    }
    gpu->CreateTexture2D(
        &desc,
        initialData,
        swapchainTexture->nativeTexture.ReleaseAndGetAddressOf());

    swapchainTexture->flutterSurfaceDescIdx = m_flutterSurfaceDescs.size();
    auto& flutterSurfaceDesc =
        m_flutterSurfaceDescs.emplace_back(FlutterDesktopGpuSurfaceDescriptor{
            .struct_size = sizeof(FlutterDesktopGpuSurfaceDescriptor),
            .handle = nullptr,
            .width = width,
            .height = height,
            .visible_width = width,
            .visible_height = height,
            .format = kFlutterDesktopPixelFormatBGRA8888,
            .release_callback = [](void* release_context) {},
            .release_context = nullptr,
        });
    ComPtr<IDXGIResource> asDxgiResource;
    swapchainTexture->nativeTexture.As(&asDxgiResource);
    asDxgiResource->GetSharedHandle(&flutterSurfaceDesc.handle);
    return swapchainTexture;
}

void RiveNativeRenderTexture::end()
{
    m_textureRegistrar->MarkTextureFrameAvailable(m_id);
}

RiveNativeRenderTexture::~RiveNativeRenderTexture()
{
    destroyRiveRenderer(m_riveRenderer);
}

void RiveNativePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar)
{
    auto plugin = std::make_unique<RiveNativePlugin>(
        registrar,
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(),
            "rive_native",
            &flutter::StandardMethodCodec::GetInstance()),
        registrar->texture_registrar());
    plugin->channel()->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto& call, auto result) {
            plugin_pointer->HandleMethodCall(call, std::move(result));
        });
    registrar->AddPlugin(std::move(plugin));
}

// Dart API
bool usePLS = true;

class FlutterRenderer;
namespace rive
{
class Font;
class RenderPath;
class AudioEngine;
} // namespace rive

EXPORT void rewindRenderPath(rive::RenderPath* path);

RiveNativePlugin::RiveNativePlugin(
    flutter::PluginRegistrarWindows* registrar,
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel,
    flutter::TextureRegistrar* texture_registrar) :
    m_registrar(registrar),
    m_channel(std::move(channel)),
    m_textureRegistrar(texture_registrar)
{
    ComPtr<IDXGIFactory2> factory;
    CreateDXGIFactory(
        __uuidof(IDXGIFactory2),
        reinterpret_cast<void**>(factory.ReleaseAndGetAddressOf()));

    auto view =
        static_cast<flutter::PluginRegistrarWindows*>(registrar)->GetView();
    if (view == nullptr)
    {
        fprintf(stderr, "Rive failed to find a Flutter View.\n");
        return;
    }
    auto desiredAdapter =
        static_cast<flutter::PluginRegistrarWindows*>(registrar)
            ->GetView()
            ->GetGraphicsAdapter();
    if (desiredAdapter == nullptr)
    {
        fprintf(stderr, "Rive failed to find a Graphics Adapter.\n");
        return;
    }
    DXGI_ADAPTER_DESC desiredDesc{};
    desiredAdapter->GetDesc(&desiredDesc);

    ComPtr<IDXGIAdapter> adapter;
    DXGI_ADAPTER_DESC adapterDesc{};
    bool isIntel = false;
    for (UINT i = 0; factory->EnumAdapters(i, &adapter) != DXGI_ERROR_NOT_FOUND;
         ++i)
    {
        adapter->GetDesc(&adapterDesc);
        isIntel = adapterDesc.VendorId == 0x163C ||
                  adapterDesc.VendorId == 0x8086 ||
                  adapterDesc.VendorId == 0x8087;

        if (desiredDesc.AdapterLuid.LowPart ==
                adapterDesc.AdapterLuid.LowPart &&
            desiredDesc.AdapterLuid.HighPart ==
                adapterDesc.AdapterLuid.HighPart)
        {
            break;
        }
    }

    ComPtr<ID3D11Device> gpu;
    ComPtr<ID3D11DeviceContext> gpuContext;
    D3D_FEATURE_LEVEL featureLevels[] = {D3D_FEATURE_LEVEL_11_1};
    UINT creationFlags = 0;

    D3D11CreateDevice(adapter.Get(),
                      D3D_DRIVER_TYPE_UNKNOWN,
                      NULL,
                      creationFlags,
                      featureLevels,
                      (UINT)std::size(featureLevels),
                      D3D11_SDK_VERSION,
                      gpu.ReleaseAndGetAddressOf(),
                      NULL,
                      gpuContext.ReleaseAndGetAddressOf());
    if (gpu && gpuContext)
    {
        fprintf(stderr, "D3D device: %S\n", adapterDesc.Description);
    }

    m_factory = std::move(factory);
    m_gpu = std::move(gpu);
    m_gpuContext = std::move(gpuContext);
    m_isIntelGpu = isIntel;
    m_riveRendererContext =
        createRiveRendererContext(m_gpu, m_gpuContext, isIntel);
}

RiveNativePlugin::~RiveNativePlugin() { shutdown(); }

void RiveNativePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
{
    if (method_call.method_name().compare("createTexture") == 0)
    {
        auto args = std::get_if<flutter::EncodableMap>(method_call.arguments());
        auto widthItr = args->find(flutter::EncodableValue("width"));
        int32_t width = 0;
        if (widthItr != args->end())
        {
            width = std::get<int32_t>(widthItr->second);
        }
        else
        {
            result->Error("CreateTexture error",
                          "No width received by the native part of "
                          "RiveNative.createTexture",
                          nullptr);
            return;
        }

        auto heightItr = args->find(flutter::EncodableValue("height"));
        int32_t height = 0;
        if (heightItr != args->end())
        {
            height = std::get<int32_t>(heightItr->second);
        }
        else
        {
            result->Error("CreateTexture error",
                          "No height received by the native part of "
                          "RiveNative.createTexture",
                          nullptr);
            return;
        }

        auto renderTexture = new RiveNativeRenderTexture(m_gpu.Get(),
                                                         m_riveRendererContext,
                                                         width,
                                                         height,
                                                         m_textureRegistrar);
        m_renderTextures[renderTexture->id()] = renderTexture;

        flutter::EncodableMap map;
        map[flutter::EncodableValue("textureId")] = renderTexture->id();
        result->Success(flutter::EncodableValue(map));
    }
    else if (method_call.method_name().compare("removeTexture") == 0)
    {

        auto args = std::get_if<flutter::EncodableMap>(method_call.arguments());
        auto idItr = args->find(flutter::EncodableValue("id"));
        int64_t id = 0;
        if (idItr != args->end())
        {
            id = std::get<int64_t>(idItr->second);
        }
        else
        {
            result->Error(
                "removeTexture error",
                "no id received by the native part of RiveNative.removeTexture",
                nullptr);
            return;
        }

        auto itr = m_renderTextures.find(id);
        if (itr != m_renderTextures.end())
        {
            auto renderTexture = itr->second;
            m_renderTextures.erase(itr);
            m_textureRegistrar->UnregisterTexture(renderTexture->id());
            delete renderTexture;
        }
        result->Success();
    }
    else
    {
        result->NotImplemented();
    }
}

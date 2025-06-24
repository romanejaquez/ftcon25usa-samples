#include "rive_native/rive_binding.hpp"
#include "rive_native/external.hpp"
#include "rive/advance_flags.hpp"
#include "rive/artboard.hpp"
#include "rive/file.hpp"
#include "rive/transform_component.hpp"
#include "rive/animation/state_machine_instance.hpp"
#include "rive/animation/state_machine_input_instance.hpp"
#include "rive/animation/linear_animation_instance.hpp"
#include "rive/viewmodel/viewmodel_instance.hpp"
#include "rive/viewmodel/viewmodel_instance_number.hpp"
#include "rive/viewmodel/viewmodel_instance_boolean.hpp"
#include "rive/viewmodel/viewmodel_instance_color.hpp"
#include "rive/viewmodel/viewmodel_instance_enum.hpp"
#include "rive/viewmodel/viewmodel_instance_list.hpp"
#include "rive/viewmodel/viewmodel_instance_string.hpp"
#include "rive/viewmodel/viewmodel_instance_trigger.hpp"
#include "rive/math/transform_components.hpp"
#include "rive/node.hpp"
#include "rive/constraints/constraint.hpp"
#include "rive/bones/root_bone.hpp"
#include "rive/nested_artboard.hpp"
#include "rive/animation/state_machine_bool.hpp"
#include "rive/animation/state_machine_number.hpp"
#include "rive/animation/state_machine_trigger.hpp"
#include "rive/assets/file_asset.hpp"
#include "rive/assets/image_asset.hpp"
#include "rive/assets/font_asset.hpp"
#include "rive/assets/audio_asset.hpp"
#include "rive/text/text_value_run.hpp"
#include "rive/text/raw_text.hpp"
#include "rive/open_url_event.hpp"
#include "rive/custom_property.hpp"
#include "rive/custom_property_boolean.hpp"
#include "rive/custom_property_number.hpp"
#include "rive/custom_property_string.hpp"
#include "rive/custom_property.hpp"
#include "rive/viewmodel/runtime/viewmodel_runtime.hpp"
#include <mutex>

class WrappedArtboard;
using namespace rive;

std::mutex g_deleteMutex;

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include <emscripten/bind.h>
#include <emscripten/val.h>
#include <emscripten/html5.h>
using namespace emscripten;

static std::unordered_map<WrappedArtboard*, emscripten::val>
    _webLayoutChangedCallbacks;
static std::unordered_map<WrappedArtboard*, emscripten::val>
    _webLayoutDirtyCallbacks;
static std::unordered_map<WrappedArtboard*, emscripten::val> _webEventCallbacks;
static std::unordered_map<StateMachineInstance*, emscripten::val>
    _webInputChangedCallbacks;
static std::unordered_map<StateMachineInstance*, emscripten::val>
    _webDataBindChangedCallbacks;
#endif

#if defined(__EMSCRIPTEN__)

emscripten::val g_viewModelUpdateNumber = val::null();
emscripten::val g_viewModelUpdateBoolean = val::null();
emscripten::val g_viewModelUpdateColor = val::null();
emscripten::val g_viewModelUpdateString = val::null();
emscripten::val g_viewModelUpdateTrigger = val::null();
emscripten::val g_viewModelUpdateEnum = val::null();
using ViewModelUpdateNumber = emscripten::val;
using ViewModelUpdateBoolean = emscripten::val;
using ViewModelUpdateColor = emscripten::val;
using ViewModelUpdateString = emscripten::val;
using ViewModelUpdateTrigger = emscripten::val;
using ViewModelUpdateEnum = emscripten::val;
#else
typedef void (*ViewModelUpdateNumber)(uint64_t pointer, float value);
typedef void (*ViewModelUpdateBoolean)(uint64_t pointer, bool value);
typedef void (*ViewModelUpdateColor)(uint64_t pointer, int value);
typedef void (*ViewModelUpdateString)(uint64_t pointer, const char* value);
typedef void (*ViewModelUpdateTrigger)(uint64_t pointer, uint32_t value);
typedef void (*ViewModelUpdateEnum)(uint64_t pointer, uint32_t value);
ViewModelUpdateNumber g_viewModelUpdateNumber = nullptr;
ViewModelUpdateBoolean g_viewModelUpdateBoolean = nullptr;
ViewModelUpdateColor g_viewModelUpdateColor = nullptr;
ViewModelUpdateString g_viewModelUpdateString = nullptr;
ViewModelUpdateTrigger g_viewModelUpdateTrigger = nullptr;
ViewModelUpdateEnum g_viewModelUpdateEnum = nullptr;
#endif

using namespace rive;

typedef void (*EventCallback)(WrappedArtboard* wrapper, uint32_t);
typedef bool (*AssetLoaderCallback)(FileAsset* asset,
                                    const uint8_t* bytes,
                                    const size_t size);

#ifdef DEBUG
uint32_t g_fileCount = 0;
uint32_t g_artboardCount = 0;
uint32_t g_stateMachineCount = 0;
uint32_t g_animationCount = 0;
uint32_t g_viewModelRuntimeCount = 0;
uint32_t g_viewModelInstanceRuntimeCount = 0;
uint32_t g_viewModelInstanceValueRuntimeCount = 0;
EXPORT uint32_t debugFileCount() { return g_fileCount; }
EXPORT uint32_t debugArtboardCount() { return g_artboardCount; }
EXPORT uint32_t debugStateMachineCount() { return g_stateMachineCount; }
EXPORT uint32_t debugAnimationCount() { return g_animationCount; }
EXPORT uint32_t debugViewModelRuntimeCount() { return g_viewModelRuntimeCount; }
EXPORT uint32_t debugViewModelInstanceRuntimeCount()
{
    return g_viewModelInstanceRuntimeCount;
}
EXPORT uint32_t debugViewModelInstanceValueRuntimeCount()
{
    return g_viewModelInstanceValueRuntimeCount;
}
#endif

// Helper function to convert std::string to caller-owned C string
static const char* toCString(const std::string& str)
{
    char* result = (char*)std::malloc(str.size() + 1);
    if (result == nullptr)
    {
        return nullptr;
    }
    std::strcpy(result, str.c_str());
    return result;
}

class WrappedFile : public RefCnt<WrappedFile>
{
public:
    WrappedFile(std::unique_ptr<File>&& file) : m_file(std::move(file))
    {
#ifdef DEBUG
        g_fileCount++;
#endif
    }
#ifdef DEBUG
    ~WrappedFile() { g_fileCount--; }
#endif
    File* file() { return m_file.get(); }

private:
    std::unique_ptr<File> m_file;
};

class WrappedDataBind : public RefCnt<WrappedDataBind>
{
public:
    WrappedDataBind(DataBind* dataBind) : m_dataBind(dataBind) {}

    ~WrappedDataBind() { m_dataBind = nullptr; }

    void deleteDataBind() { m_dataBind = nullptr; }

    DataBind* dataBind() { return m_dataBind; }

private:
    DataBind* m_dataBind = nullptr;
};

// This is the same as an artboard instance but provides a render transform.
class WrappedArtboard : public RefCnt<WrappedArtboard>,
                        public NestedEventListener
{
public:
    Mat2D renderTransform;

    WrappedArtboard(std::unique_ptr<ArtboardInstance>&& artboardInstance,
                    rcp<WrappedFile> file) :
        m_artboard(std::move(artboardInstance)), m_file(file)
    {
        // Events should call back with the wrapper.
        m_artboard->callbackUserData = this;
#ifdef DEBUG
        g_artboardCount++;
#endif
    }

    ~WrappedArtboard()
    {
        // Make sure artboard is deleted before file.
        m_artboard = nullptr;
        m_file = nullptr;

#if defined(__EMSCRIPTEN__)
        _webLayoutChangedCallbacks.erase(this);
        _webLayoutDirtyCallbacks.erase(this);
        _webEventCallbacks.erase(this);
#endif

#ifdef DEBUG
        g_artboardCount--;
#endif
    }

    void notify(const std::vector<EventReport>& events,
                NestedArtboard* context) override
    {
        if (m_eventCallback == nullptr || context != nullptr)
        {
            // No callback or it came from a nested artboard, don't report up.
            return;
        }
        for (auto report : events)
        {
            uint32_t id = m_artboard->idOf(report.event());
            if (id == 0)
            {
                // Couldn't find id.
                continue;
            }
            m_eventCallback(this, id);
        }
    }

    void monitorEvents(LinearAnimationInstance* animation)
    {
        animation->addNestedEventListener(this);
    }

    void monitorEvents(StateMachineInstance* stateMachine)
    {
        stateMachine->addNestedEventListener(this);
    }

    void addDataBind(WrappedDataBind* dataBind)
    {
        m_dataBinds.push_back(dataBind);
    }

    void deleteDataBinds()
    {

        for (auto dataBind : m_dataBinds)
        {
            dataBind->deleteDataBind();
        }
        m_dataBinds.clear();
    }

    ArtboardInstance* artboard()
    {
        assert(m_artboard);
        return m_artboard.get();
    }
    EventCallback m_eventCallback = nullptr;

private:
    rcp<WrappedFile> m_file;
    std::unique_ptr<ArtboardInstance> m_artboard;
    std::vector<WrappedDataBind*> m_dataBinds;
};

class WrappedStateMachine : public RefCnt<WrappedStateMachine>
{
public:
    WrappedStateMachine(
        rcp<WrappedArtboard> artboard,
        std::unique_ptr<StateMachineInstance>&& stateMachineInstance) :
        m_wrappedArtboard(std::move(artboard)),
        m_stateMachine(std::move(stateMachineInstance))
    {
#ifdef DEBUG
        g_stateMachineCount++;
#endif
    }

#ifdef DEBUG
    ~WrappedStateMachine() { g_stateMachineCount--; }
#endif

    StateMachineInstance* stateMachine() { return m_stateMachine.get(); }

    WrappedArtboard* wrappedArtboard()
    {
        assert(m_wrappedArtboard);
        return m_wrappedArtboard.get();
    };

private:
    rcp<WrappedArtboard> m_wrappedArtboard;
    std::unique_ptr<StateMachineInstance> m_stateMachine;
};

class WrappedInput
{
public:
    WrappedInput(rcp<WrappedStateMachine> stateMachineInstance,
                 SMIInput* input) :
        m_input(input), m_wrappedMachine(stateMachineInstance)
    {}

    ~WrappedInput() {}

    SMIInput* input() { return m_input; }
    SMINumber* number()
    {
        if (m_input->inputCoreType() != StateMachineNumberBase::typeKey)
        {
            return nullptr;
        }
        return static_cast<SMINumber*>(m_input);
    }

    SMIBool* boolean()
    {
        if (m_input->inputCoreType() != StateMachineBoolBase::typeKey)
        {
            return nullptr;
        }
        return static_cast<SMIBool*>(m_input);
    }

    void fire()
    {
        if (m_input->inputCoreType() != StateMachineTriggerBase::typeKey)
        {
            return;
        }
        static_cast<SMITrigger*>(m_input)->fire();
    }

private:
    rive::SMIInput* m_input;
    rcp<WrappedStateMachine> m_wrappedMachine;
};

class WrappedEvent : public RefCnt<WrappedEvent>
{
public:
    WrappedEvent(rcp<WrappedStateMachine> stateMachineInstance, Event* event) :
        m_event(event), m_wrappedMachine(stateMachineInstance)
    {}

    ~WrappedEvent() {}

    Event* event() { return m_event; }

private:
    rive::Event* m_event;
    rcp<WrappedStateMachine> m_wrappedMachine;
};

class WrappedCustomProperty
{
public:
    WrappedCustomProperty(rcp<WrappedEvent> event,
                          CustomProperty* customProperty) :
        m_customProperty(customProperty), m_wrappedEvent(event)
    {}

    ~WrappedCustomProperty() {}

    CustomProperty* customProperty() { return m_customProperty; }

private:
    rive::CustomProperty* m_customProperty;
    rcp<WrappedEvent> m_wrappedEvent;
};

class WrappedComponent
{
public:
    WrappedComponent(rcp<WrappedArtboard> wrappedArtboard,
                     TransformComponent* component) :
        m_component(component), m_wrappedArtboard(std::move(wrappedArtboard))
    {}

    ~WrappedComponent() { fprintf(stderr, "deleting wrapped component\n"); }

    TransformComponent* component() { return m_component; }

private:
    TransformComponent* m_component;
    rcp<WrappedArtboard> m_wrappedArtboard;
};

class WrappedLinearAnimation : public RefCnt<WrappedLinearAnimation>
{
public:
    WrappedLinearAnimation(
        rcp<WrappedArtboard> artboard,
        std::unique_ptr<LinearAnimationInstance>&& linearAnimation) :
        m_wrappedArtboard(artboard),
        m_linearAnimation(std::move(linearAnimation))
    {
#ifdef DEBUG
        g_animationCount++;
#endif
    }
    ~WrappedLinearAnimation()
    {
        m_linearAnimation = nullptr;
        m_wrappedArtboard = nullptr;
#ifdef DEBUG
        g_animationCount--;
#endif
    }
    LinearAnimationInstance* animation() { return m_linearAnimation.get(); }

    WrappedArtboard* wrappedArtboard()
    {
        assert(m_wrappedArtboard);
        return m_wrappedArtboard.get();
    }

private:
    std::unique_ptr<LinearAnimationInstance> m_linearAnimation;
    rcp<WrappedArtboard> m_wrappedArtboard;
};

class WrappedDataContext : public RefCnt<WrappedDataContext>
{
public:
    WrappedDataContext(DataContext* dataContext) : m_dataContext(dataContext) {}

    ~WrappedDataContext() { m_dataContext = nullptr; }

    DataContext* dataContext() { return m_dataContext; }

private:
    DataContext* m_dataContext = nullptr;
};

class WrappedViewModelInstance : public RefCnt<WrappedViewModelInstance>
{
public:
    WrappedViewModelInstance(rcp<ViewModelInstance> instance) :
        m_instance(instance)
    {}

    rcp<ViewModelInstance> instance() { return m_instance; }

private:
    rcp<ViewModelInstance> m_instance;
};

class WrappedViewModelInstanceValue
    : public RefCnt<WrappedViewModelInstanceValue>
{
public:
    WrappedViewModelInstanceValue(ViewModelInstanceValue* instance) :
        m_instance(instance)
    {}

    ~WrappedViewModelInstanceValue() { m_instance = nullptr; }

    ViewModelInstanceValue* instance() { return m_instance; }

private:
    ViewModelInstanceValue* m_instance = nullptr;
};

#pragma region ViewModelRuntime Classes

class WrappedViewModelRuntime
{
public:
    WrappedViewModelRuntime(ViewModelRuntime* viewModelRuntime,
                            rcp<WrappedFile> file) :
        m_viewModelRuntime(viewModelRuntime), m_file(file)
    {
#ifdef DEBUG
        g_viewModelRuntimeCount++;
#endif
    }

    ~WrappedViewModelRuntime()
    {
        // Make sure viewModelRuntime is deleted before file.
        m_viewModelRuntime = nullptr;
        m_file = nullptr;

#ifdef DEBUG
        g_viewModelRuntimeCount--;
#endif
    }

    ViewModelRuntime* viewModel() { return m_viewModelRuntime; }

private:
    rcp<WrappedFile> m_file;
    ViewModelRuntime* m_viewModelRuntime;
};

class WrappedVMIRuntime : public RefCnt<WrappedVMIRuntime>
{
public:
    WrappedVMIRuntime(rcp<ViewModelInstanceRuntime> viewModelInstanceRuntime) :
        m_viewModelInstanceRuntime(viewModelInstanceRuntime)
    {
#ifdef DEBUG
        g_viewModelInstanceRuntimeCount++;
#endif
    }

    ~WrappedVMIRuntime()
    {
#ifdef DEBUG
        g_viewModelInstanceRuntimeCount--;
#endif
    }

    ViewModelInstanceRuntime* instance()
    {
        assert(m_viewModelInstanceRuntime);
        return m_viewModelInstanceRuntime.get();
    }

private:
    rcp<ViewModelInstanceRuntime> m_viewModelInstanceRuntime;
};

template <typename T = ViewModelInstanceValueRuntime>
class WrappedVMIValueRuntime
{
public:
    WrappedVMIValueRuntime(rcp<WrappedVMIRuntime> viewModelInstanceRuntime,
                           T* value) :
        m_viewModelInstanceRuntime(viewModelInstanceRuntime), m_value(value)
    {
#ifdef DEBUG
        g_viewModelInstanceValueRuntimeCount++;
#endif
    }

    ~WrappedVMIValueRuntime()
    {
#ifdef DEBUG
        g_viewModelInstanceValueRuntimeCount--;
#endif
    }

    T* instance() { return m_value; }

private:
    rcp<WrappedVMIRuntime> m_viewModelInstanceRuntime;
    T* m_value;
};

using WrappedVMINumberRuntime =
    WrappedVMIValueRuntime<ViewModelInstanceNumberRuntime>;
using WrappedVMIStringRuntime =
    WrappedVMIValueRuntime<ViewModelInstanceStringRuntime>;
using WrappedVMIBooleanRuntime =
    WrappedVMIValueRuntime<ViewModelInstanceBooleanRuntime>;
using WrappedVMIEnumRuntime =
    WrappedVMIValueRuntime<ViewModelInstanceEnumRuntime>;
using WrappedVMIColorRuntime =
    WrappedVMIValueRuntime<ViewModelInstanceColorRuntime>;
using WrappedVMITriggerRuntime =
    WrappedVMIValueRuntime<ViewModelInstanceTriggerRuntime>;

#pragma endregion

EXPORT void freeString(const char* str) { free((void*)str); }

#pragma region File

#if defined(__EMSCRIPTEN__)
EXPORT WasmPtr loadRiveFile(WasmPtr bufferPtr,
                            WasmPtr lengthPtr,
                            WasmPtr factoryPtr,
                            emscripten::val assetLoader)
{
    auto bytes = (uint8_t*)bufferPtr;
    if (bytes == nullptr)
    {
        return (WasmPtr)(File*)(0x2);
    }

    auto factory = (rive::Factory*)factoryPtr;
    auto length = (SizeType)lengthPtr;

    class FlutterFileAssetLoader : public rive::FileAssetLoader
    {
    private:
        emscripten::val m_callback;

    public:
        FlutterFileAssetLoader(emscripten::val callback) : m_callback(callback)
        {}

        bool loadContents(rive::FileAsset& asset,
                          Span<const uint8_t> inBandBytes,
                          rive::Factory* factory) override
        {
            if (!m_callback.isNull())
            {
                return m_callback((WasmPtr)(&asset),
                                  (WasmPtr)(inBandBytes.data()),
                                  inBandBytes.size())
                    .as<bool>();
            }
            return false;
        }
    };

    std::unique_ptr<File> file;
    auto loader = new FlutterFileAssetLoader(assetLoader);
    if ((file = File::import(Span(bytes, length),
                             factory == nullptr ? riveFactory() : factory,
                             nullptr, // TODO: Handle results
                             loader)))
    {
        delete loader;
        return (WasmPtr)(new WrappedFile(std::move(file)));
    }
    delete loader;
    return (WasmPtr) nullptr;
}

#else
EXPORT void* loadRiveFile(const uint8_t* bytes,
                          SizeType length,
                          rive::Factory* factory,
                          AssetLoaderCallback assetLoader)
{
    if (bytes == nullptr)
    {
        return (File*)(0x2);
    }

    class FlutterFileAssetLoader : public rive::FileAssetLoader
    {
    private:
        AssetLoaderCallback m_callback;

    public:
        FlutterFileAssetLoader(AssetLoaderCallback callback) :
            m_callback(callback)
        {}

        bool loadContents(rive::FileAsset& asset,
                          Span<const uint8_t> inBandBytes,
                          rive::Factory* factory) override
        {
            if (m_callback != nullptr)
            {
                return m_callback(&asset,
                                  inBandBytes.data(),
                                  inBandBytes.size());
            }
            return false;
        }
    };

    std::unique_ptr<File> file;
    auto loader = new FlutterFileAssetLoader(assetLoader);
    if ((file = File::import(Span(bytes, length),
                             factory == nullptr ? riveFactory() : factory,
                             nullptr, // TODO: Handle results
                             loader)))
    {
        delete loader;
        return new WrappedFile(std::move(file));
    }
    delete loader;
    return nullptr;
}
#endif

EXPORT void deleteRiveFile(WrappedFile* fileWrapper)
{
    if (fileWrapper == nullptr)
    {
        return;
    }

    std::unique_lock<std::mutex> lock(g_deleteMutex);
    fileWrapper->unref();
}

EXPORT WrappedArtboard* riveFileArtboardDefault(WrappedFile* fileWrapper,
                                                bool frameOrigin)
{
    if (fileWrapper == nullptr || fileWrapper->file()->artboardCount() == 0)
    {
        return nullptr;
    }

    auto artboard = fileWrapper->file()->artboard(0)->instance();
    if (!artboard)
    {
        return nullptr;
    }
    artboard->frameOrigin(frameOrigin);
    return new WrappedArtboard(std::move(artboard), ref_rcp(fileWrapper));
}

EXPORT WrappedArtboard* riveFileArtboardNamed(WrappedFile* fileWrapper,
                                              const char* name,
                                              bool frameOrigin)
{
    if (fileWrapper == nullptr)
    {
        return nullptr;
    }
    Artboard* artboard = fileWrapper->file()->artboard(name);
    if (artboard == nullptr)
    {
        return nullptr;
    }

    auto artboardInstance = artboard->instance();
    if (!artboardInstance)
    {
        return nullptr;
    }
    AdvanceFlags advancingFlags;
    advancingFlags |= AdvanceFlags::AdvanceNested;
    artboardInstance->frameOrigin(frameOrigin);
    artboardInstance->advance(0.0f, advancingFlags);
    return new WrappedArtboard(std::move(artboardInstance),
                               ref_rcp(fileWrapper));
}

EXPORT WrappedArtboard* riveFileArtboardByIndex(WrappedFile* fileWrapper,
                                                uint32_t index,
                                                bool frameOrigin)
{
    if (fileWrapper == nullptr)
    {
        return nullptr;
    }

    Artboard* artboard = fileWrapper->file()->artboard(index);
    if (artboard == nullptr)
    {
        return nullptr;
    }

    auto artboardInstance = artboard->instance();
    if (!artboardInstance)
    {
        return nullptr;
    }
    AdvanceFlags advancingFlags;
    advancingFlags |= AdvanceFlags::AdvanceNested;
    artboardInstance->frameOrigin(frameOrigin);
    artboardInstance->advance(0.0f, advancingFlags);
    return new WrappedArtboard(std::move(artboardInstance),
                               ref_rcp(fileWrapper));
}

#pragma endregion

#pragma region FileAsset

#if defined(__EMSCRIPTEN__)
std::string riveFileAssetName(WasmPtr fileAssetPtr)
{
    auto fileAsset = (FileAsset*)fileAssetPtr;
    if (fileAsset == nullptr)
    {
        return "";
    }

    return fileAsset->name();
}

std::string riveFileAssetFileExtension(WasmPtr fileAssetPtr)
{
    auto fileAsset = (FileAsset*)fileAssetPtr;
    if (fileAsset == nullptr)
    {
        return "";
    }
    return fileAsset->fileExtension();
}

std::string riveFileAssetCdnBaseUrl(WasmPtr fileAssetPtr)
{
    auto fileAsset = (FileAsset*)fileAssetPtr;
    if (fileAsset == nullptr)
    {
        return "";
    }

    return fileAsset->cdnBaseUrl();
}

std::string riveFileAssetCdnUuid(WasmPtr fileAssetPtr)
{
    auto fileAsset = (FileAsset*)fileAssetPtr;
    if (fileAsset == nullptr)
    {
        return "";
    }
    return fileAsset->cdnUuidStr();
}

#else

EXPORT const char* riveFileAssetName(FileAsset* fileAsset)
{
    if (fileAsset == nullptr)
    {
        return nullptr;
    }

    return fileAsset->name().c_str();
}

EXPORT const char* riveFileAssetFileExtension(FileAsset* fileAsset)
{
    if (fileAsset == nullptr)
    {
        return nullptr;
    }
    return toCString(fileAsset->fileExtension());
}

EXPORT const char* riveFileAssetCdnBaseUrl(FileAsset* fileAsset)
{
    if (fileAsset == nullptr)
    {
        return nullptr;
    }

    return fileAsset->cdnBaseUrl().c_str();
}

EXPORT const char* riveFileAssetCdnUuid(FileAsset* fileAsset)
{
    if (fileAsset == nullptr)
    {
        return nullptr;
    }
    return toCString(fileAsset->cdnUuidStr());
}

#endif

EXPORT uint32_t riveFileAssetId(FileAsset* fileAsset)
{
    if (fileAsset == nullptr)
    {
        return 0;
    }

    return fileAsset->assetId();
}

EXPORT uint16_t riveFileAssetCoreType(FileAsset* fileAsset)
{
    if (fileAsset == nullptr)
    {
        return 0;
    }
    return fileAsset->coreType();
}

EXPORT bool riveFileAssetSetRenderImage(FileAsset* fileAsset,
                                        RenderImage* renderImage)
{
    if (fileAsset == nullptr || renderImage == nullptr ||
        !fileAsset->is<ImageAsset>())
    {
        return false;
    }
    ImageAsset* imageAsset = static_cast<ImageAsset*>(fileAsset);
    imageAsset->renderImage(ref_rcp(renderImage));
    return true;
}

EXPORT bool riveFileAssetSetAudioSource(FileAsset* fileAsset,
                                        AudioSource* audioSource)
{
#ifdef WITH_RIVE_AUDIO
    if (fileAsset == nullptr || audioSource == nullptr ||
        !fileAsset->is<AudioAsset>())
    {
        return false;
    }
    AudioAsset* audioAsset = static_cast<AudioAsset*>(fileAsset);
    audioAsset->audioSource(ref_rcp(audioSource));
    return true;
#endif
    return false;
}

EXPORT bool riveFileAssetSetFont(FileAsset* fileAsset, Font* font)
{
    if (fileAsset == nullptr || font == nullptr || !fileAsset->is<FontAsset>())
    {
        return false;
    }
    FontAsset* fontAsset = static_cast<FontAsset*>(fileAsset);
    fontAsset->font(ref_rcp(font));
    return true;
}

#pragma endregion

#pragma region ViewModelRuntime
EXPORT SizeType riveFileViewModelCount(WrappedFile* fileWrapper)
{
    if (fileWrapper == nullptr)
    {
        return 0;
    }
    return fileWrapper->file()->viewModelCount();
}

EXPORT WrappedViewModelRuntime* riveFileViewModelRuntimeByIndex(
    WrappedFile* fileWrapper,
    SizeType index)
{
    if (fileWrapper == nullptr)
    {
        return nullptr;
    }
    auto vmi = fileWrapper->file()->viewModelByIndex(index);
    if (vmi == nullptr)
    {
        return nullptr;
    }
    return new WrappedViewModelRuntime(vmi, ref_rcp(fileWrapper));
}

EXPORT WrappedViewModelRuntime* riveFileViewModelRuntimeByName(
    WrappedFile* fileWrapper,
    const char* name)
{
    if (fileWrapper == nullptr)
    {
        return nullptr;
    }
    auto vmi = fileWrapper->file()->viewModelByName(name);
    if (vmi == nullptr)
    {
        return nullptr;
    }
    return new WrappedViewModelRuntime(vmi, ref_rcp(fileWrapper));
}

EXPORT WrappedViewModelRuntime* riveFileDefaultArtboardViewModelRuntime(
    WrappedFile* fileWrapper,
    WrappedArtboard* artboard)
{
    if (fileWrapper == nullptr || artboard == nullptr)
    {
        return nullptr;
    }
    auto vmi =
        fileWrapper->file()->defaultArtboardViewModel(artboard->artboard());
    if (vmi == nullptr)
    {
        return nullptr;
    }
    return new WrappedViewModelRuntime(vmi, ref_rcp(fileWrapper));
}

EXPORT SizeType
viewModelRuntimePropertyCount(WrappedViewModelRuntime* wrappedViewModel)
{
    if (wrappedViewModel == nullptr)
    {
        return 0;
    }
    return wrappedViewModel->viewModel()->propertyCount();
}

EXPORT SizeType
viewModelRuntimeInstanceCount(WrappedViewModelRuntime* wrappedViewModel)
{
    if (wrappedViewModel == nullptr)
    {
        return 0;
    }
    return wrappedViewModel->viewModel()->instanceCount();
}

EXPORT const char* viewModelRuntimeName(
    WrappedViewModelRuntime* wrappedViewModel)
{
    if (wrappedViewModel == nullptr)
    {
        return nullptr;
    }
    return wrappedViewModel->viewModel()->name().c_str();
}

EXPORT const char* vmiRuntimeName(WrappedVMIRuntime* wrappedViewModel)
{
    if (wrappedViewModel == nullptr)
    {
        return nullptr;
    }
    return wrappedViewModel->instance()->name().c_str();
}

#ifdef __EMSCRIPTEN__
emscripten::val buildProperties(std::vector<rive::PropertyData>& properties)
{
    emscripten::val jsProperties = emscripten::val::array();
    for (const auto& prop : properties)
    {
        emscripten::val jsProp = emscripten::val::object();
        jsProp.set("name", prop.name);
        int val = static_cast<int>(prop.type);
        jsProp.set("type", val);
        jsProperties.call<void>("push", jsProp);
    }
    return jsProperties;
}

emscripten::val viewModelRuntimeProperties(WasmPtr wrappedViewModelPtr)
{
    WrappedViewModelRuntime* wrappedViewModel =
        (WrappedViewModelRuntime*)wrappedViewModelPtr;
    if (wrappedViewModel == nullptr)
    {
        return emscripten::val::null();
    }
    auto props = wrappedViewModel->viewModel()->properties();

    return buildProperties(props);
}

emscripten::val vmiRuntimeProperties(WasmPtr wrappedVMIPtr)
{
    WrappedVMIRuntime* wrappedVMI = (WrappedVMIRuntime*)wrappedVMIPtr;
    if (wrappedVMI == nullptr)
    {
        return emscripten::val::null();
    }
    auto props = wrappedVMI->instance()->properties();

    return buildProperties(props);
}

emscripten::val createDataEnumObject(rive::DataEnum* dataEnum)
{
    emscripten::val dataEnumObject = emscripten::val::object();
    dataEnumObject.set("name", dataEnum->enumName());
    emscripten::val dataEnumValues = emscripten::val::array();
    for (auto& value : dataEnum->values())
    {
        auto name = value->key();
        dataEnumValues.call<void>("push", name);
    }
    dataEnumObject.set("values", dataEnumValues);
    return dataEnumObject;
}

emscripten::val fileEnums(WasmPtr wrappedFilePtr)
{
    WrappedFile* wrappedFile = (WrappedFile*)wrappedFilePtr;
    if (wrappedFile == nullptr)
    {
        return emscripten::val::null();
    }
    auto enums = wrappedFile->file()->enums();
    emscripten::val jsProperties = emscripten::val::array();
    for (auto& dataEnum : enums)
    {
        auto enumObject = createDataEnumObject(dataEnum);
        jsProperties.call<void>("push", enumObject);
    }
    return jsProperties;
}
#else

struct ViewModelPropertyDataFFI
{
    int type;
    const char* name;
};

struct ViewModelPropertyDataArray
{
    ViewModelPropertyDataFFI* data;
    int length;
};

ViewModelPropertyDataArray generateViewModelPropertyDataArray(
    std::vector<PropertyData>& props)
{
    ViewModelPropertyDataFFI* out = (ViewModelPropertyDataFFI*)malloc(
        sizeof(ViewModelPropertyDataFFI) * props.size());

    for (size_t i = 0; i < props.size(); ++i)
    {
        // The string is only valid for the duration of the
        // call. In Flutter, we would get invalid data or errors when trying to
        // access the string: return
        // viewModel->properties().at(index).name.c_str();

        // We copy the string to the heap and return a pointer to it, because
        // the string is only valid for the duration of the call. We free up the
        // memory in the `deleteViewModelPropertyDataArray` function.
        const std::string& name = props[i].name;
        char* cstr = (char*)malloc(name.size() + 1);
        std::memcpy(cstr, name.c_str(), name.size() + 1);

        out[i].type = static_cast<int>(props[i].type);
        out[i].name = cstr;
    }

    return {out, static_cast<int>(props.size())};
}

EXPORT ViewModelPropertyDataArray
viewModelRuntimeProperties(WrappedViewModelRuntime* wrappedViewModel)
{
    if (wrappedViewModel == nullptr)
    {
        return {nullptr, 0};
    }
    auto props = wrappedViewModel->viewModel()->properties();
    return generateViewModelPropertyDataArray(props);
}

EXPORT ViewModelPropertyDataArray
vmiRuntimeProperties(WrappedVMIRuntime* wrappedViewModel)
{
    if (wrappedViewModel == nullptr)
    {
        return {nullptr, 0};
    }
    auto props = wrappedViewModel->instance()->properties();
    return generateViewModelPropertyDataArray(props);
}

EXPORT void deleteViewModelPropertyDataArray(ViewModelPropertyDataArray arr)
{
    for (int i = 0; i < arr.length; i++)
    {
        free((void*)arr.data[i].name);
    }
    free(arr.data);
}

struct DataEnumFFI
{
    const char* name;
    const char** values;
    int length;
};
struct DataEnumArray
{
    DataEnumFFI* data;
    int length;
};

EXPORT DataEnumArray fileEnums(WrappedFile* wrappedFile)
{
    if (wrappedFile == nullptr)
    {
        return {nullptr, 0};
    }
    auto enums = wrappedFile->file()->enums();
    DataEnumFFI* out = (DataEnumFFI*)malloc(sizeof(DataEnumFFI) * enums.size());

    for (size_t i = 0; i < enums.size(); ++i)
    {
        auto dataEnum = enums[i];
        auto valueSize = dataEnum->values().size();
        const char** c_values = new const char*[valueSize];
        for (size_t j = 0; j < valueSize; ++j)
        {
            auto value = dataEnum->values()[j];
            c_values[j] = value->key().c_str();
        }
        out[i].name = dataEnum->enumName().c_str();
        out[i].values = c_values;
        out[i].length = static_cast<int>(valueSize);
    }
    return {out, static_cast<int>(enums.size())};
}

EXPORT void deleteDataEnumArray(DataEnumArray enums)
{
    if (enums.data == nullptr)
    {
        return;
    }

    for (int i = 0; i < enums.length; ++i)
    {
        delete[] enums.data[i].values;
    }
    free(enums.data);
}
#endif

EXPORT WrappedVMIRuntime* createVMIRuntimeFromIndex(
    WrappedViewModelRuntime* wrappedViewModel,
    SizeType index)
{
    if (wrappedViewModel == nullptr)
    {
        return nullptr;
    }
    auto vmi = wrappedViewModel->viewModel()->createInstanceFromIndex(index);
    if (vmi == nullptr)
    {
        return nullptr;
    }
    return new WrappedVMIRuntime(ref_rcp(vmi));
}

EXPORT WrappedVMIRuntime* createVMIRuntimeFromName(
    WrappedViewModelRuntime* wrappedViewModel,
    const char* name)
{
    if (wrappedViewModel == nullptr)
    {
        return nullptr;
    }
    auto vmi = wrappedViewModel->viewModel()->createInstanceFromName(name);
    if (vmi == nullptr)
    {
        return nullptr;
    }
    return new WrappedVMIRuntime(ref_rcp(vmi));
}

EXPORT WrappedVMIRuntime* createDefaultVMIRuntime(
    WrappedViewModelRuntime* wrappedViewModel)
{
    if (wrappedViewModel == nullptr)
    {
        return nullptr;
    }
    auto vmi = wrappedViewModel->viewModel()->createDefaultInstance();
    if (vmi == nullptr)
    {
        return nullptr;
    }
    return new WrappedVMIRuntime(ref_rcp(vmi));
}

EXPORT WrappedVMIRuntime* createVMIRuntime(
    WrappedViewModelRuntime* wrappedViewModel)
{
    if (wrappedViewModel == nullptr)
    {
        return nullptr;
    }
    auto vmi = wrappedViewModel->viewModel()->createInstance();
    if (vmi == nullptr)
    {
        return nullptr;
    }
    return new WrappedVMIRuntime(ref_rcp(vmi));
}

EXPORT WrappedVMIRuntime* vmiRuntimeGetViewModelProperty(
    WrappedVMIRuntime* wrappedViewModelInstance,
    const char* path)
{
    if (wrappedViewModelInstance == nullptr)
    {
        return nullptr;
    }
    auto viewModelInstance = wrappedViewModelInstance->instance();
    if (viewModelInstance == nullptr)
    {
        return nullptr;
    }
    auto vmi = viewModelInstance->propertyViewModel(path);
    if (vmi == nullptr)
    {
        return nullptr;
    }
    return new WrappedVMIRuntime(ref_rcp(vmi));
}

EXPORT WrappedVMINumberRuntime* vmiRuntimeGetNumberProperty(
    WrappedVMIRuntime* wrappedViewModelInstance,
    const char* path)
{
    if (wrappedViewModelInstance == nullptr)
    {
        return nullptr;
    }
    auto viewModelInstance = wrappedViewModelInstance->instance();
    if (viewModelInstance == nullptr)
    {
        return nullptr;
    }
    auto numberProperty = viewModelInstance->propertyNumber(path);
    if (numberProperty == nullptr)
    {
        return nullptr;
    }
    return new WrappedVMINumberRuntime(ref_rcp(wrappedViewModelInstance),
                                       numberProperty);
}

EXPORT float getVMINumberRuntimeValue(
    WrappedVMINumberRuntime* wrappedNumberProperty)
{
    if (wrappedNumberProperty == nullptr)
    {
        return 0.0f;
    }
    return wrappedNumberProperty->instance()->value();
}

EXPORT void setVMINumberRuntimeValue(
    WrappedVMINumberRuntime* wrappedNumberProperty,
    float value)
{
    if (wrappedNumberProperty == nullptr)
    {
        return;
    }
    wrappedNumberProperty->instance()->value(value);
}

EXPORT WrappedVMIStringRuntime* vmiRuntimeGetStringProperty(
    WrappedVMIRuntime* wrappedViewModelInstance,
    const char* path)
{
    if (wrappedViewModelInstance == nullptr)
    {
        return nullptr;
    }
    auto viewModelInstance = wrappedViewModelInstance->instance();
    if (viewModelInstance == nullptr)
    {
        return nullptr;
    }
    auto stringProperty = viewModelInstance->propertyString(path);
    if (stringProperty == nullptr)
    {
        return nullptr;
    }
    return new WrappedVMIStringRuntime(ref_rcp(wrappedViewModelInstance),
                                       stringProperty);
}

EXPORT const char* getVMIStringRuntimeValue(
    WrappedVMIStringRuntime* wrappedStringProperty)
{
    if (wrappedStringProperty == nullptr)
    {
        return nullptr;
    }
    return wrappedStringProperty->instance()->value().c_str();
}

EXPORT void setVMIStringRuntimeValue(
    WrappedVMIStringRuntime* wrappedStringProperty,
    const char* value)
{
    if (wrappedStringProperty == nullptr)
    {
        return;
    }
    wrappedStringProperty->instance()->value(value);
}

EXPORT WrappedVMIBooleanRuntime* vmiRuntimeGetBooleanProperty(
    WrappedVMIRuntime* wrappedViewModelInstance,
    const char* path)
{
    if (wrappedViewModelInstance == nullptr)
    {
        return nullptr;
    }
    auto viewModelInstance = wrappedViewModelInstance->instance();
    if (viewModelInstance == nullptr)
    {
        return nullptr;
    }
    auto booleanProperty = viewModelInstance->propertyBoolean(path);
    if (booleanProperty == nullptr)
    {
        return nullptr;
    }
    return new WrappedVMIBooleanRuntime(ref_rcp(wrappedViewModelInstance),
                                        booleanProperty);
}

EXPORT bool getVMIBooleanRuntimeValue(
    WrappedVMIBooleanRuntime* wrappedBooleanProperty)
{
    if (wrappedBooleanProperty == nullptr)
    {
        return false;
    }
    return wrappedBooleanProperty->instance()->value();
}

EXPORT void setVMIBooleanRuntimeValue(
    WrappedVMIBooleanRuntime* wrappedBooleanProperty,
    bool value)
{
    if (wrappedBooleanProperty == nullptr)
    {
        return;
    }
    wrappedBooleanProperty->instance()->value(value);
}

EXPORT WrappedVMIColorRuntime* vmiRuntimeGetColorProperty(
    WrappedVMIRuntime* wrappedViewModelInstance,
    const char* path)
{
    if (wrappedViewModelInstance == nullptr)
    {
        return nullptr;
    }
    auto viewModelInstance = wrappedViewModelInstance->instance();
    if (viewModelInstance == nullptr)
    {
        return nullptr;
    }
    auto colorProperty = viewModelInstance->propertyColor(path);
    if (colorProperty == nullptr)
    {
        return nullptr;
    }
    return new WrappedVMIColorRuntime(ref_rcp(wrappedViewModelInstance),
                                      colorProperty);
}

EXPORT int getVMIColorRuntimeValue(WrappedVMIColorRuntime* wrappedColorProperty)
{
    if (wrappedColorProperty == nullptr)
    {
        return 0x000000FF;
    }
    return wrappedColorProperty->instance()->value();
}

EXPORT void setVMIColorRuntimeValue(
    WrappedVMIColorRuntime* wrappedColorProperty,
    int value)
{
    if (wrappedColorProperty == nullptr)
    {
        return;
    }
    wrappedColorProperty->instance()->value(value);
}

EXPORT WrappedVMIEnumRuntime* vmiRuntimeGetEnumProperty(
    WrappedVMIRuntime* wrappedViewModelInstance,
    const char* path)
{
    if (wrappedViewModelInstance == nullptr)
    {
        return nullptr;
    }
    auto viewModelInstance = wrappedViewModelInstance->instance();
    if (viewModelInstance == nullptr)
    {
        return nullptr;
    }
    auto enumProperty = viewModelInstance->propertyEnum(path);
    if (enumProperty == nullptr)
    {
        return nullptr;
    }
    return new WrappedVMIEnumRuntime(ref_rcp(wrappedViewModelInstance),
                                     enumProperty);
}

#if defined(__EMSCRIPTEN__)
std::string getVMIEnumRuntimeValue(WasmPtr enumPropertyPtr)
{
    auto enumProperty = (WrappedVMIEnumRuntime*)enumPropertyPtr;
    if (enumProperty == nullptr)
    {
        return "";
    }
    return enumProperty->instance()->value();
}
#else
EXPORT const char* getVMIEnumRuntimeValue(
    WrappedVMIEnumRuntime* wrappedEnumProperty)
{
    if (wrappedEnumProperty == nullptr)
    {
        return nullptr;
    }
    return toCString(wrappedEnumProperty->instance()->value());
}
#endif

EXPORT void setVMIEnumRuntimeValue(WrappedVMIEnumRuntime* wrappedEnumProperty,
                                   const char* value)
{
    if (wrappedEnumProperty == nullptr)
    {
        return;
    }
    wrappedEnumProperty->instance()->value(value);
}

EXPORT WrappedVMITriggerRuntime* vmiRuntimeGetTriggerProperty(
    WrappedVMIRuntime* wrappedViewModelInstance,
    const char* path)
{
    if (wrappedViewModelInstance == nullptr)
    {
        return nullptr;
    }
    auto viewModelInstance = wrappedViewModelInstance->instance();
    if (viewModelInstance == nullptr)
    {
        return nullptr;
    }
    auto triggerProperty = viewModelInstance->propertyTrigger(path);
    if (triggerProperty == nullptr)
    {
        return nullptr;
    }
    return new WrappedVMITriggerRuntime(ref_rcp(wrappedViewModelInstance),
                                        triggerProperty);
}

EXPORT void triggerVMITriggerRuntime(
    WrappedVMITriggerRuntime* wrappedTriggerProp)
{
    if (wrappedTriggerProp == nullptr)
    {
        return;
    }
    return wrappedTriggerProp->instance()->trigger();
}

EXPORT bool vmiValueRuntimeHasChanged(
    WrappedVMIValueRuntime<ViewModelInstanceValueRuntime>* wrappedValue)
{
    if (wrappedValue == nullptr)
    {
        return false;
    }
    return wrappedValue->instance()->hasChanged();
}

EXPORT void vmiValueRuntimeClearChanges(
    WrappedVMIValueRuntime<ViewModelInstanceValueRuntime>* wrappedValue)
{
    if (wrappedValue == nullptr)
    {
        return;
    }
    return wrappedValue->instance()->clearChanges();
}

EXPORT void artboardSetVMIRuntime(WrappedArtboard* wrappedArtboard,
                                  WrappedVMIRuntime* wrappedViewModelInstance)
{
    if (wrappedViewModelInstance == nullptr)
    {
        return;
    }
    auto viewModelInstance = wrappedViewModelInstance->instance();
    if (wrappedArtboard == nullptr || viewModelInstance == nullptr)
    {
        return;
    }
    if (viewModelInstance->instance() == nullptr)
    {
        return;
    }

    wrappedArtboard->artboard()->bindViewModelInstance(
        viewModelInstance->instance());
}

EXPORT void stateMachineSetVMIRuntime(
    WrappedStateMachine* wrappedMachine,
    WrappedVMIRuntime* wrappedViewModelInstance)
{
    if (wrappedViewModelInstance == nullptr)
    {
        return;
    }
    auto viewModelInstance = wrappedViewModelInstance->instance();
    if (wrappedMachine == nullptr || viewModelInstance == nullptr ||
        viewModelInstance->instance() == nullptr)
    {
        return;
    }
    wrappedMachine->stateMachine()->bindViewModelInstance(
        viewModelInstance->instance());
}

EXPORT void deleteVMIValueRuntime(
    WrappedVMIValueRuntime<ViewModelInstanceValueRuntime>* wrappedValue)
{
    std::unique_lock<std::mutex> lock(g_deleteMutex);
    delete wrappedValue;
}

EXPORT void deleteVMIRuntime(WrappedVMIRuntime* wrappedVMIRuntime)
{
    std::unique_lock<std::mutex> lock(g_deleteMutex);
    wrappedVMIRuntime->unref();
}

EXPORT void deleteViewModelRuntime(
    WrappedViewModelRuntime* wrappedViewModelRuntime)
{
    std::unique_lock<std::mutex> lock(g_deleteMutex);
    delete wrappedViewModelRuntime;
}

#pragma endregion

EXPORT WrappedDataContext* riveDataContext(WrappedFile* fileWrapper,
                                           SizeType index,
                                           SizeType indexInstance)
{
    if (fileWrapper == nullptr)
    {
        return nullptr;
    }
    auto instance =
        fileWrapper->file()->createViewModelInstance(index, indexInstance);
    auto dataContext = new DataContext(instance);
    auto wrappedDataContext = new WrappedDataContext(dataContext);
    return wrappedDataContext;
}

EXPORT void deleteDataContext(WrappedDataContext* wrappedDataContext)
{
    std::unique_lock<std::mutex> lock(g_deleteMutex);
    wrappedDataContext->unref();
}

EXPORT WrappedViewModelInstance* riveDataContextViewModelInstance(
    WrappedDataContext* wrappedDataContext)
{
    if (wrappedDataContext == nullptr)
    {
        return nullptr;
    }
    return new WrappedViewModelInstance(
        wrappedDataContext->dataContext()->viewModelInstance());
}

EXPORT void artboardDataContextFromInstance(
    WrappedArtboard* wrappedArtboard,
    WrappedViewModelInstance* wrappedViewModelInstance,
    WrappedDataContext* wrappedDataContext)
{
    if (wrappedArtboard == nullptr || wrappedDataContext == nullptr ||
        wrappedViewModelInstance == nullptr)
    {
        return;
    }
    if (wrappedViewModelInstance->instance() == nullptr)
    {
        return;
    }

    wrappedArtboard->artboard()->bindViewModelInstance(
        wrappedViewModelInstance->instance(),
        wrappedDataContext->dataContext(),
        false);
}

EXPORT WrappedDataContext* artboardDataContext(WrappedArtboard* wrappedArtboard)
{
    if (wrappedArtboard == nullptr)
    {
        return nullptr;
    }
    auto dataContext = wrappedArtboard->artboard()->dataContext();
    return new WrappedDataContext(dataContext);
}

EXPORT void artboardInternalDataContext(WrappedArtboard* wrappedArtboard,
                                        WrappedDataContext* wrappedDataContext)
{
    if (wrappedArtboard == nullptr || wrappedDataContext == nullptr)
    {
        return;
    }
    auto dataContext = wrappedDataContext->dataContext();
    wrappedArtboard->artboard()->internalDataContext(dataContext, false);
}

EXPORT void artboardClearDataContext(WrappedArtboard* wrappedArtboard)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    wrappedArtboard->artboard()->clearDataContext();
}

EXPORT void stateMachineDataContextFromInstance(
    WrappedStateMachine* wrappedMachine,
    WrappedViewModelInstance* wrappedViewModelInstance)
{
    if (wrappedMachine == nullptr || wrappedViewModelInstance == nullptr ||
        wrappedViewModelInstance->instance() == nullptr)
    {
        return;
    }
    wrappedMachine->stateMachine()->bindViewModelInstance(
        wrappedViewModelInstance->instance());
}

EXPORT void stateMachineDataContext(WrappedStateMachine* wrappedMachine,
                                    WrappedDataContext* wrappedDataContext)
{
    if (wrappedDataContext == nullptr)
    {
        return;
    }
    auto dataContext = wrappedDataContext->dataContext();
    wrappedMachine->stateMachine()->dataContext(dataContext);
}

EXPORT WrappedViewModelInstanceValue* viewModelInstancePropertyValue(
    WrappedViewModelInstance* wrappedViewModelInstance,
    SizeType index)
{
    if (wrappedViewModelInstance == nullptr ||
        wrappedViewModelInstance->instance() == nullptr)
    {
        return nullptr;
    }
    auto instance = wrappedViewModelInstance->instance();
    auto propertyValue =
        wrappedViewModelInstance->instance()->propertyValue(index);
    return new WrappedViewModelInstanceValue(propertyValue);
}

EXPORT void deleteViewModelInstance(
    WrappedViewModelInstance* wrappedViewModelInstance)
{
    std::unique_lock<std::mutex> lock(g_deleteMutex);
    wrappedViewModelInstance->unref();
}

EXPORT void deleteViewModelInstanceValue(WrappedViewModelInstanceValue* value)
{
    std::unique_lock<std::mutex> lock(g_deleteMutex);
    value->unref();
}

EXPORT size_t artboardTotalDataBinds(WrappedArtboard* wrappedArtboard)
{
    if (wrappedArtboard == nullptr)
    {
        return 0;
    }
    return wrappedArtboard->artboard()->allDataBinds().size();
}

EXPORT void artboardCollectDataBinds(WrappedArtboard* wrappedArtboard)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    wrappedArtboard->artboard()->collectDataBinds();
}

EXPORT WrappedDataBind* artboardDataBindAt(WrappedArtboard* wrappedArtboard,
                                           SizeType index)
{
    if (wrappedArtboard == nullptr)
    {
        return nullptr;
    }
    if (index < wrappedArtboard->artboard()->allDataBinds().size())
    {
        auto wrappedDataBind = new WrappedDataBind(
            wrappedArtboard->artboard()->allDataBinds()[index]);
        wrappedArtboard->addDataBind(wrappedDataBind);
        return wrappedDataBind;
    }
    return nullptr;
}

EXPORT WrappedViewModelInstance* viewModelInstanceReferenceViewModel(
    WrappedViewModelInstanceValue* wrappedViewModelInstanceValue)
{
    if (wrappedViewModelInstanceValue == nullptr ||
        wrappedViewModelInstanceValue->instance() == nullptr)
    {
        return nullptr;
    }
    return new WrappedViewModelInstance(
        wrappedViewModelInstanceValue->instance()
            ->as<ViewModelInstanceViewModel>()
            ->referenceViewModelInstance());
}

EXPORT WrappedViewModelInstance* viewModelInstanceListItemViewModel(
    WrappedViewModelInstanceValue* wrappedViewModelInstanceValue,
    SizeType index)
{
    if (wrappedViewModelInstanceValue == nullptr ||
        wrappedViewModelInstanceValue->instance() == nullptr)
    {
        return nullptr;
    }
    auto vmList =
        wrappedViewModelInstanceValue->instance()->as<ViewModelInstanceList>();
    if (vmList != nullptr && index < vmList->listItems().size())
    {
        auto vmListItem = vmList->item(index);
        if (vmListItem != nullptr && vmListItem->viewModelInstance() != nullptr)
        {
            return new WrappedViewModelInstance(
                vmListItem->viewModelInstance());
        }
    }
    return nullptr;
}

EXPORT void setViewModelInstanceNumberValue(
    WrappedViewModelInstanceValue* wrappedViewModelInstance,
    float value)
{
    if (wrappedViewModelInstance == nullptr ||
        wrappedViewModelInstance->instance() == nullptr)
    {
        return;
    }
    auto viewModelInstanceNumber =
        wrappedViewModelInstance->instance()->as<ViewModelInstanceNumber>();
    viewModelInstanceNumber->propertyValue(value);
}

EXPORT void setViewModelInstanceTriggerValue(
    WrappedViewModelInstanceValue* wrappedViewModelInstance,
    uint32_t value)
{
    if (wrappedViewModelInstance == nullptr ||
        wrappedViewModelInstance->instance() == nullptr)
    {
        return;
    }
    auto viewModelInstanceTrigger =
        wrappedViewModelInstance->instance()->as<ViewModelInstanceTrigger>();
    viewModelInstanceTrigger->propertyValue(value);
}

EXPORT void setViewModelInstanceEnumValue(
    WrappedViewModelInstanceValue* wrappedViewModelInstance,
    uint32_t value)
{
    if (wrappedViewModelInstance == nullptr ||
        wrappedViewModelInstance->instance() == nullptr)
    {
        return;
    }
    auto viewModelInstanceEnum =
        wrappedViewModelInstance->instance()->as<ViewModelInstanceEnum>();
    viewModelInstanceEnum->propertyValue(value);
}

EXPORT void setViewModelInstanceBooleanValue(
    WrappedViewModelInstanceValue* wrappedViewModelInstance,
    bool value)
{
    if (wrappedViewModelInstance == nullptr ||
        wrappedViewModelInstance->instance() == nullptr)
    {
        return;
    }
    auto viewModelInstanceBoolean =
        wrappedViewModelInstance->instance()->as<ViewModelInstanceBoolean>();
    viewModelInstanceBoolean->propertyValue(value);
}

EXPORT void setViewModelInstanceColorValue(
    WrappedViewModelInstanceValue* wrappedViewModelInstance,
    int value)
{
    if (wrappedViewModelInstance == nullptr ||
        wrappedViewModelInstance->instance() == nullptr)
    {
        return;
    }
    auto viewModelInstanceColor =
        wrappedViewModelInstance->instance()->as<ViewModelInstanceColor>();
    viewModelInstanceColor->propertyValue(value);
}

EXPORT void setViewModelInstanceStringValue(
    WrappedViewModelInstanceValue* wrappedViewModelInstance,
    const char* value)
{
    if (wrappedViewModelInstance == nullptr ||
        wrappedViewModelInstance->instance() == nullptr)
    {
        return;
    }
    auto viewModelInstanceString =
        wrappedViewModelInstance->instance()->as<ViewModelInstanceString>();
    viewModelInstanceString->propertyValue(value);
}

EXPORT uint32_t riveDataBindDirt(WrappedDataBind* wrappedDataBind)
{
    if (wrappedDataBind == nullptr || wrappedDataBind->dataBind() == nullptr)
    {
        return 0;
    }
    return static_cast<uint32_t>(wrappedDataBind->dataBind()->dirt());
}

EXPORT void riveDataBindSetDirt(WrappedDataBind* wrappedDataBind, uint32_t dirt)
{
    if (wrappedDataBind == nullptr || wrappedDataBind->dataBind() == nullptr)
    {
        return;
    }
    wrappedDataBind->dataBind()->dirt(static_cast<ComponentDirt>(dirt));
}

EXPORT uint32_t riveDataBindFlags(WrappedDataBind* wrappedDataBind)
{
    if (wrappedDataBind == nullptr || wrappedDataBind->dataBind() == nullptr)
    {
        return 0;
    }
    return static_cast<uint32_t>(wrappedDataBind->dataBind()->flags());
}

EXPORT void riveDataBindUpdate(WrappedDataBind* wrappedDataBind, uint32_t dirt)
{
    if (wrappedDataBind == nullptr || wrappedDataBind->dataBind() == nullptr)
    {
        return;
    }
    wrappedDataBind->dataBind()->update(static_cast<ComponentDirt>(dirt));
}

EXPORT void riveDataBindUpdateSourceBinding(WrappedDataBind* wrappedDataBind)
{
    if (wrappedDataBind == nullptr || wrappedDataBind->dataBind() == nullptr)
    {
        return;
    }
    wrappedDataBind->dataBind()->updateSourceBinding();
}

EXPORT void artboardDraw(WrappedArtboard* wrappedArtboard, Renderer* renderer)
{
    if (wrappedArtboard == nullptr || renderer == nullptr)
    {
        return;
    }
    wrappedArtboard->artboard()->draw(renderer);
}

EXPORT SizeType artboardAnimationCount(WrappedArtboard* wrappedArtboard)
{
    if (wrappedArtboard == nullptr)
    {
        return 0;
    }
    return (SizeType)wrappedArtboard->artboard()->animationCount();
}

EXPORT SizeType artboardStateMachineCount(WrappedArtboard* wrappedArtboard)
{
    if (wrappedArtboard == nullptr)
    {
        return 0;
    }
    return (SizeType)wrappedArtboard->artboard()->stateMachineCount();
}

EXPORT WrappedLinearAnimation* artboardAnimationAt(
    WrappedArtboard* wrappedArtboard,
    SizeType index)
{
    if (wrappedArtboard == nullptr)
    {
        return nullptr;
    }
    std::unique_ptr<LinearAnimationInstance> animation =
        wrappedArtboard->artboard()->animationAt(index);
    if (animation)
    {
        wrappedArtboard->monitorEvents(animation.get());
        return new WrappedLinearAnimation(ref_rcp(wrappedArtboard),
                                          std::move(animation));
    }
    return nullptr;
}

EXPORT WrappedComponent* artboardComponentNamed(
    WrappedArtboard* wrappedArtboard,
    const char* name)
{
    if (wrappedArtboard == nullptr)
    {
        return nullptr;
    }
    auto component =
        wrappedArtboard->artboard()->find<TransformComponent>(name);
    if (component == nullptr)
    {
        return nullptr;
    }
    return new WrappedComponent(ref_rcp(wrappedArtboard), component);
}

EXPORT void deleteComponent(WrappedComponent* wrappedComponent)
{
    std::unique_lock<std::mutex> lock(g_deleteMutex);
    delete wrappedComponent;
}

EXPORT void componentGetWorldTransform(WrappedComponent* wrappedComponent,
                                       float* out)
{
    if (wrappedComponent == nullptr)
    {
        return;
    }
    const Mat2D& wt = wrappedComponent->component()->worldTransform();
    memcpy(out, &wt, sizeof(float) * 6);
}

EXPORT void componentSetWorldTransform(WrappedComponent* wrappedComponent,
                                       float xx,
                                       float xy,
                                       float yx,
                                       float yy,
                                       float tx,
                                       float ty)
{
    if (wrappedComponent == nullptr)
    {
        return;
    }
    Mat2D& wt = wrappedComponent->component()->mutableWorldTransform();
    wt[0] = xx;
    wt[1] = xy;
    wt[2] = yx;
    wt[3] = yy;
    wt[4] = tx;
    wt[5] = ty;
}

EXPORT void artboardGetRenderTransform(WrappedArtboard* artboard, float* out)
{
    const Mat2D& wt = artboard->renderTransform;
    memcpy(out, &wt, sizeof(float) * 6);
}

EXPORT void artboardSetRenderTransform(WrappedArtboard* artboard,
                                       float xx,
                                       float xy,
                                       float yx,
                                       float yy,
                                       float tx,
                                       float ty)
{
    Mat2D& wt = artboard->renderTransform;
    wt[0] = xx;
    wt[1] = xy;
    wt[2] = yx;
    wt[3] = yy;
    wt[4] = tx;
    wt[5] = ty;
}

EXPORT float componentGetScaleX(WrappedComponent* wrappedComponent)
{
    if (wrappedComponent == nullptr)
    {
        return 1.0f;
    }
    return wrappedComponent->component()->scaleX();
}

EXPORT void componentSetScaleX(WrappedComponent* wrappedComponent, float value)
{
    if (wrappedComponent == nullptr)
    {
        return;
    }
    wrappedComponent->component()->scaleX(value);
}

EXPORT float componentGetX(WrappedComponent* wrappedComponent)
{
    if (wrappedComponent == nullptr)
    {
        return 0.0f;
    }
    return wrappedComponent->component()->x();
}

EXPORT void componentSetX(WrappedComponent* wrappedComponent, float value)
{
    if (wrappedComponent == nullptr)
    {
        return;
    }
    if (wrappedComponent->component()->is<Node>())
    {
        Node* node = wrappedComponent->component()->as<Node>();
        node->x(value);
    }
    else if (wrappedComponent->component()->is<RootBone>())
    {
        RootBone* bone = wrappedComponent->component()->as<RootBone>();
        bone->x(value);
    }
}

EXPORT float componentGetY(WrappedComponent* wrappedComponent)
{
    if (wrappedComponent == nullptr)
    {
        return 0.0f;
    }
    return wrappedComponent->component()->y();
}

EXPORT void componentSetY(WrappedComponent* wrappedComponent, float value)
{
    if (wrappedComponent == nullptr)
    {
        return;
    }
    auto component = wrappedComponent->component();
    if (component->is<Node>())
    {
        Node* node = component->as<Node>();
        node->y(value);
    }
    else if (component->is<RootBone>())
    {
        RootBone* bone = component->as<RootBone>();
        bone->y(value);
    }
}

EXPORT float componentGetScaleY(WrappedComponent* wrappedComponent)
{
    if (wrappedComponent == nullptr)
    {
        return 1.0f;
    }
    return wrappedComponent->component()->scaleY();
}

EXPORT void componentSetScaleY(WrappedComponent* wrappedComponent, float value)
{
    if (wrappedComponent == nullptr)
    {
        return;
    }
    wrappedComponent->component()->scaleY(value);
}

EXPORT float componentGetRotation(WrappedComponent* wrappedComponent)
{
    if (wrappedComponent == nullptr)
    {
        return 0.0f;
    }
    return wrappedComponent->component()->rotation();
}

EXPORT void componentSetRotation(WrappedComponent* wrappedComponent,
                                 float value)
{
    if (wrappedComponent == nullptr)
    {
        return;
    }
    wrappedComponent->component()->rotation(value);
}

EXPORT void componentSetLocalFromWorld(WrappedComponent* wrappedComponent,
                                       float xx,
                                       float xy,
                                       float yx,
                                       float yy,
                                       float tx,
                                       float ty)
{
    if (wrappedComponent == nullptr)
    {
        return;
    }
    auto component = wrappedComponent->component();
    Mat2D world = getParentWorld(*component).invertOrIdentity() *
                  Mat2D(xx, xy, yx, yy, tx, ty);
    TransformComponents components = world.decompose();
    if (component->is<Node>())
    {
        Node* node = component->as<Node>();
        node->x(components.x());
        node->y(components.y());
    }
    else if (component->is<RootBone>())
    {
        RootBone* bone = component->as<RootBone>();
        bone->x(components.x());
        bone->y(components.y());
    }
    component->scaleX(components.scaleX());
    component->scaleX(components.scaleX());
    component->rotation(components.rotation());
}

EXPORT WrappedLinearAnimation* artboardAnimationNamed(
    WrappedArtboard* wrappedArtboard,
    const char* name)
{
    if (wrappedArtboard == nullptr)
    {
        return nullptr;
    }
    std::unique_ptr<LinearAnimationInstance> animation =
        wrappedArtboard->artboard()->animationNamed(name);
    if (animation)
    {
        wrappedArtboard->monitorEvents(animation.get());
        return new WrappedLinearAnimation(ref_rcp(wrappedArtboard),
                                          std::move(animation));
    }
    return nullptr;
}

EXPORT void artboardSetFrameOrigin(WrappedArtboard* wrappedArtboard,
                                   bool frameOrigin)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    wrappedArtboard->artboard()->frameOrigin(frameOrigin);
}

EXPORT bool artboardGetFrameOrigin(WrappedArtboard* wrappedArtboard)
{
    if (wrappedArtboard == nullptr)
    {
        return false;
    }
    return wrappedArtboard->artboard()->frameOrigin();
}
EXPORT bool animationInstanceAdvance(WrappedLinearAnimation* wrappedAnimation,
                                     float elapsedSeconds,
                                     bool nested)
{
    if (wrappedAnimation == nullptr)
    {
        return false;
    }
    return wrappedAnimation->animation()->advance(elapsedSeconds);
}
EXPORT void animationInstanceApply(WrappedLinearAnimation* wrappedAnimation,
                                   float mix)
{
    if (wrappedAnimation == nullptr)
    {
        return;
    }
    wrappedAnimation->animation()->apply(mix);
}

EXPORT bool animationInstanceAdvanceAndApply(
    WrappedLinearAnimation* wrappedAnimation,
    float elapsedSeconds)
{
    if (wrappedAnimation == nullptr)
    {
        return false;
    }
    return wrappedAnimation->animation()->advanceAndApply(elapsedSeconds);
}

EXPORT float animationInstanceGetLocalSeconds(
    WrappedLinearAnimation* wrappedAnimation,
    float seconds)
{
    if (wrappedAnimation == nullptr)
    {
        return 0.0f;
    }
    return wrappedAnimation->animation()->animation()->globalToLocalSeconds(
        seconds);
}

EXPORT float animationInstanceGetDuration(
    WrappedLinearAnimation* wrappedAnimation,
    float seconds)
{
    if (wrappedAnimation == nullptr)
    {
        return 0.0f;
    }
    return wrappedAnimation->animation()->durationSeconds();
}

EXPORT float animationInstanceGetTime(WrappedLinearAnimation* wrappedAnimation)
{
    if (wrappedAnimation == nullptr)
    {
        return 0.0f;
    }
    return wrappedAnimation->animation()->time();
}

EXPORT void animationInstanceSetTime(WrappedLinearAnimation* wrappedAnimation,
                                     float time)
{
    if (wrappedAnimation == nullptr)
    {
        return;
    }
    wrappedAnimation->animation()->time(time);
}

EXPORT void animationInstanceDelete(WrappedLinearAnimation* wrappedAnimation)
{
    if (wrappedAnimation == nullptr)
    {
        return;
    }
    std::unique_lock<std::mutex> lock(g_deleteMutex);
    wrappedAnimation->unref();
}

EXPORT void artboardAddToRenderPath(WrappedArtboard* wrappedArtboard,
                                    RenderPath* renderPath,
                                    float xx,
                                    float xy,
                                    float yx,
                                    float yy,
                                    float tx,
                                    float ty)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    wrappedArtboard->artboard()->addToRenderPath(renderPath,
                                                 Mat2D(xx, xy, yx, yy, tx, ty));
}

EXPORT void artboardBounds(WrappedArtboard* wrappedArtboard, float* out)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    AABB bounds = wrappedArtboard->artboard()->bounds();
    memcpy(out, &bounds, sizeof(float) * 4);
}

EXPORT void artboardLayoutBounds(WrappedArtboard* wrappedArtboard, float* out)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    AABB bounds = wrappedArtboard->artboard()->layoutBounds();
    memcpy(out, &bounds, sizeof(float) * 4);
}

EXPORT void* artboardTakeLayoutNode(WrappedArtboard* wrappedArtboard)
{
    if (wrappedArtboard == nullptr)
    {
        return nullptr;
    }
    return wrappedArtboard->artboard()->takeLayoutNode();
}

EXPORT void artboardSyncStyleChanges(WrappedArtboard* wrappedArtboard)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    wrappedArtboard->artboard()->syncStyleChanges();
}

EXPORT void artboardWidthOverride(WrappedArtboard* wrappedArtboard,
                                  float width,
                                  int widthUnitValue,
                                  bool isRow)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    wrappedArtboard->artboard()->widthOverride(width, widthUnitValue, isRow);
}

EXPORT void artboardHeightOverride(WrappedArtboard* wrappedArtboard,
                                   float height,
                                   int heightUnitValue,
                                   bool isRow)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    wrappedArtboard->artboard()->heightOverride(height, heightUnitValue, isRow);
}

EXPORT void artboardWidthIntrinsicallySizeOverride(
    WrappedArtboard* wrappedArtboard,
    bool intrinsic)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    wrappedArtboard->artboard()->widthIntrinsicallySizeOverride(intrinsic);
}

EXPORT void artboardHeightIntrinsicallySizeOverride(
    WrappedArtboard* wrappedArtboard,
    bool intrinsic)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    wrappedArtboard->artboard()->heightIntrinsicallySizeOverride(intrinsic);
}

EXPORT void updateLayoutBounds(WrappedArtboard* wrappedArtboard, bool animate)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    wrappedArtboard->artboard()->updateLayoutBounds(animate);
}

EXPORT void cascadeLayoutStyle(WrappedArtboard* wrappedArtboard, int direction)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    auto artboard = wrappedArtboard->artboard();
    // TODO::Pass down interpolation values
    // We may want to pass down more layout component styles, need
    // to figure out the best way to do that
    artboard->cascadeLayoutStyle(artboard->interpolation(),
                                 artboard->interpolator(),
                                 artboard->interpolationTime(),
                                 (LayoutDirection)direction);
}

EXPORT bool riveArtboardAdvance(WrappedArtboard* wrappedArtboard,
                                float seconds,
                                int flags)
{
    if (wrappedArtboard == nullptr)
    {
        return false;
    }
    return wrappedArtboard->artboard()->advanceInternal(seconds,
                                                        (AdvanceFlags)flags);
}

EXPORT float riveArtboardGetOpacity(WrappedArtboard* wrappedArtboard)
{
    if (wrappedArtboard == nullptr)
    {
        return 0.0f;
    }
    return wrappedArtboard->artboard()->opacity();
}

EXPORT bool riveArtboardUpdatePass(WrappedArtboard* wrappedArtboard)
{
    if (wrappedArtboard == nullptr)
    {
        return false;
    }
    return wrappedArtboard->artboard()->updatePass(false);
}

EXPORT bool riveArtboardHasComponentDirt(WrappedArtboard* wrappedArtboard)
{
    if (wrappedArtboard == nullptr)
    {
        return false;
    }
    return wrappedArtboard->artboard()->hasDirt(ComponentDirt::Components);
}

EXPORT void riveArtboardSetOpacity(WrappedArtboard* wrappedArtboard,
                                   float opacity)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    return wrappedArtboard->artboard()->opacity(opacity);
}

EXPORT float riveArtboardGetWidth(WrappedArtboard* wrappedArtboard)
{
    if (wrappedArtboard == nullptr)
    {
        return 0.0f;
    }
    return wrappedArtboard->artboard()->width();
}

EXPORT void riveArtboardSetWidth(WrappedArtboard* wrappedArtboard, float width)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    return wrappedArtboard->artboard()->width(width);
}

EXPORT float riveArtboardGetHeight(WrappedArtboard* wrappedArtboard)
{
    if (wrappedArtboard == nullptr)
    {
        return 0.0f;
    }
    return wrappedArtboard->artboard()->height();
}

EXPORT void riveArtboardSetHeight(WrappedArtboard* wrappedArtboard,
                                  float height)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    return wrappedArtboard->artboard()->height(height);
}

EXPORT float riveArtboardGetOriginalWidth(WrappedArtboard* wrappedArtboard)
{
    if (wrappedArtboard == nullptr)
    {
        return 0.0f;
    }
    return wrappedArtboard->artboard()->originalWidth();
}

EXPORT float riveArtboardGetOriginalHeight(WrappedArtboard* wrappedArtboard)
{
    if (wrappedArtboard == nullptr)
    {
        return 0.0f;
    }
    return wrappedArtboard->artboard()->originalHeight();
}

EXPORT WrappedStateMachine* riveArtboardStateMachineDefault(
    WrappedArtboard* wrappedArtboard)
{
    if (wrappedArtboard == nullptr)
    {
        return nullptr;
    }
    auto smi = wrappedArtboard->artboard()->defaultStateMachine();
    if (smi == nullptr)
    {
        smi = wrappedArtboard->artboard()->stateMachineAt(0);
    }
    if (smi != nullptr)
    {
        wrappedArtboard->monitorEvents(smi.get());
        return new WrappedStateMachine(ref_rcp(wrappedArtboard),
                                       std::move(smi));
    }
    return nullptr;
}

EXPORT WrappedStateMachine* riveArtboardStateMachineNamed(
    WrappedArtboard* wrappedArtboard,
    const char* name)
{
    if (wrappedArtboard == nullptr)
    {
        return nullptr;
    }
    auto smi = wrappedArtboard->artboard()->stateMachineNamed(name);
    if (smi != nullptr)
    {
        wrappedArtboard->monitorEvents(smi.get());
        return new WrappedStateMachine(ref_rcp(wrappedArtboard),
                                       std::move(smi));
    }
    return nullptr;
}

EXPORT WrappedStateMachine* riveArtboardStateMachineAt(
    WrappedArtboard* wrappedArtboard,
    SizeType index)
{
    if (wrappedArtboard == nullptr)
    {
        return nullptr;
    }

    auto smi = wrappedArtboard->artboard()->stateMachineAt(index);
    if (smi != nullptr)
    {
        wrappedArtboard->monitorEvents(smi.get());
        return new WrappedStateMachine(ref_rcp(wrappedArtboard),
                                       std::move(smi));
    }
    return nullptr;
}

EXPORT bool artboardSetText(WrappedArtboard* wrappedArtboard,
                            const char* name,
                            const char* value,
                            const char* path)
{
    if (wrappedArtboard == nullptr || name == nullptr || value == nullptr)
    {
        return false;
    }
    auto textRun = (path != nullptr)
                       ? wrappedArtboard->artboard()->getTextRun(name, path)
                       : wrappedArtboard->artboard()->find<TextValueRun>(name);
    if (textRun == nullptr)
    {
        return false;
    }
    textRun->text(value);
    return true;
}

EXPORT const char* artboardGetText(WrappedArtboard* wrappedArtboard,
                                   const char* name,
                                   const char* path)
{
    if (wrappedArtboard == nullptr || name == nullptr)
    {
        return nullptr;
    }
    auto textRun = (path != nullptr)
                       ? wrappedArtboard->artboard()->getTextRun(name, path)
                       : wrappedArtboard->artboard()->find<TextValueRun>(name);
    if (textRun == nullptr)
    {
        return nullptr;
    }
    return textRun->text().c_str();
}

EXPORT bool stateMachineInstanceAdvance(WrappedStateMachine* wrappedMachine,
                                        float elapsedSeconds,
                                        bool newFrame)
{
    if (wrappedMachine == nullptr)
    {
        return false;
    }
    return wrappedMachine->stateMachine()->advance(elapsedSeconds, newFrame);
}

EXPORT bool stateMachineInstanceAdvanceAndApply(
    WrappedStateMachine* wrappedMachine,
    float elapsedSeconds)
{
    if (wrappedMachine == nullptr)
    {
        return false;
    }
    return wrappedMachine->stateMachine()->advanceAndApply(elapsedSeconds);
}

EXPORT bool stateMachineInstanceHitTest(WrappedStateMachine* wrappedMachine,
                                        float x,
                                        float y)
{
    if (wrappedMachine == nullptr)
    {
        return false;
    }
    return wrappedMachine->stateMachine()->hitTest(Vec2D(x, y));
}

EXPORT uint8_t
stateMachineInstancePointerDown(WrappedStateMachine* wrappedMachine,
                                float x,
                                float y)
{
    if (wrappedMachine == nullptr)
    {
        return false;
    }
    return (uint8_t)wrappedMachine->stateMachine()->pointerDown(Vec2D(x, y));
}

EXPORT uint8_t
stateMachineInstancePointerExit(WrappedStateMachine* wrappedMachine,
                                float x,
                                float y)
{
    if (wrappedMachine == nullptr)
    {
        return false;
    }
    return (uint8_t)wrappedMachine->stateMachine()->pointerExit(Vec2D(x, y));
}

EXPORT uint8_t
stateMachineInstancePointerMove(WrappedStateMachine* wrappedMachine,
                                float x,
                                float y)
{
    if (wrappedMachine == nullptr)
    {
        return false;
    }
    return (uint8_t)wrappedMachine->stateMachine()->pointerMove(Vec2D(x, y));
}

EXPORT uint8_t
stateMachineInstancePointerUp(WrappedStateMachine* wrappedMachine,
                              float x,
                              float y)
{
    if (wrappedMachine == nullptr)
    {
        return false;
    }
    return (uint8_t)wrappedMachine->stateMachine()->pointerUp(Vec2D(x, y));
}

EXPORT size_t
stateMachineGetReportedEventCount(WrappedStateMachine* wrappedMachine)
{
    if (wrappedMachine == nullptr)
    {
        return 0;
    }
    return wrappedMachine->stateMachine()->reportedEventCount();
}

#ifdef __EMSCRIPTEN__
struct FlutterRuntimeReportedEvent
{
    WasmPtr event;
    float secondsDelay;
    uint16_t type;
};
struct FlutterRuntimeCustomProperty
{
    WasmPtr property;
    WasmPtr name;
    uint16_t type;
};

FlutterRuntimeReportedEvent stateMachineReportedEventAt(WasmPtr machinePtr,
                                                        const size_t index)
{
    WrappedStateMachine* wrappedMachine = (WrappedStateMachine*)machinePtr;
    if (wrappedMachine == nullptr || wrappedMachine->stateMachine() == nullptr)
    {
        return {(WasmPtr) nullptr, 0.0f, 0};
    }

    auto eventReport = wrappedMachine->stateMachine()->reportedEventAt(index);
    auto wrappedEvent =
        new WrappedEvent(ref_rcp(wrappedMachine), eventReport.event());
    return {(WasmPtr)(wrappedEvent),
            eventReport.secondsDelay(),
            eventReport.event()->coreType()};
}

EXPORT FlutterRuntimeCustomProperty getEventCustomProperty(WasmPtr eventPtr,
                                                           std::size_t index)
{
    WrappedEvent* wrappedEvent = (WrappedEvent*)eventPtr;
    if (wrappedEvent == nullptr || wrappedEvent->event() == nullptr)
    {
        return {(WasmPtr) nullptr, (WasmPtr) nullptr, 0};
    }
    Event* event = wrappedEvent->event();
    std::size_t count = 0;
    for (auto child : event->children())
    {
        if (child->is<CustomProperty>() && count++ == index)
        {
            CustomProperty* property = child->as<CustomProperty>();
            auto wrappedProperty =
                new WrappedCustomProperty(ref_rcp(wrappedEvent), property);
            return {(WasmPtr)(wrappedProperty),
                    (WasmPtr)(property->name().c_str()),
                    property->coreType()};
        }
    }
    return {(WasmPtr) nullptr, (WasmPtr) nullptr, 0};
}
#else
struct FlutterRuntimeReportedEvent
{
    WrappedEvent* event;
    float secondsDelay;
    uint16_t type;
};
struct FlutterRuntimeCustomProperty
{
    WrappedCustomProperty* property;
    const char* name;
    uint16_t type;
};

EXPORT FlutterRuntimeReportedEvent
stateMachineReportedEventAt(WrappedStateMachine* wrappedMachine,
                            const size_t index)
{
    if (wrappedMachine == nullptr || wrappedMachine->stateMachine() == nullptr)
    {
        return {nullptr, 0.0f, 0};
    }

    auto eventReport = wrappedMachine->stateMachine()->reportedEventAt(index);
    auto wrappedEvent =
        new WrappedEvent(ref_rcp(wrappedMachine), eventReport.event());
    return {wrappedEvent,
            eventReport.secondsDelay(),
            eventReport.event()->coreType()};
}

EXPORT FlutterRuntimeCustomProperty
getEventCustomProperty(WrappedEvent* wrappedEvent, std::size_t index)
{
    std::size_t count = 0;
    for (auto child : wrappedEvent->event()->children())
    {
        if (child->is<CustomProperty>() && count++ == index)
        {
            CustomProperty* property = child->as<CustomProperty>();
            auto wrappedPropety =
                new WrappedCustomProperty(ref_rcp(wrappedEvent), property);
            return {wrappedPropety,
                    property->name().c_str(),
                    property->coreType()};
        }
    }
    return {nullptr, nullptr, 0};
}
#endif

EXPORT void deleteEvent(WrappedEvent* wrappedEvent)
{
    if (wrappedEvent == nullptr)
    {
        return;
    }
    std::unique_lock<std::mutex> lock(g_deleteMutex);
    wrappedEvent->unref();
}

EXPORT void deleteCustomProperty(WrappedCustomProperty* wrappedCustomProperty)
{
    std::unique_lock<std::mutex> lock(g_deleteMutex);
    delete wrappedCustomProperty;
}

EXPORT const char* getEventName(WrappedEvent* wrappedEvent)
{
    if (wrappedEvent == nullptr)
    {
        return nullptr;
    }
    return wrappedEvent->event()->name().c_str();
}

EXPORT uint32_t getOpenUrlEventTarget(WrappedEvent* wrappedEvent)
{
    if (wrappedEvent == nullptr)
    {
        return 0;
    }
    auto openUrlEvent = static_cast<rive::OpenUrlEvent*>(wrappedEvent->event());
    if (openUrlEvent)
    {
        return openUrlEvent->targetValue();
    }
    return 0;
}

EXPORT const char* getOpenUrlEventUrl(WrappedEvent* wrappedEvent)
{
    if (wrappedEvent == nullptr)
    {
        return nullptr;
    }
    auto openUrlEvent = static_cast<rive::OpenUrlEvent*>(wrappedEvent->event());
    if (openUrlEvent)
    {
        return openUrlEvent->url().c_str();
    }
    return nullptr;
}

EXPORT std::size_t getEventCustomPropertyCount(WrappedEvent* wrappedEvent)
{
    if (wrappedEvent == nullptr || wrappedEvent->event() == nullptr)
    {
        return 0;
    }
    std::size_t count = 0;
    for (auto child : wrappedEvent->event()->children())
    {
        if (child->is<CustomProperty>())
        {
            count++;
        }
    }
    return count;
}

EXPORT float getCustomPropertyNumber(WrappedCustomProperty* wrappedProperty)
{
    if (wrappedProperty == nullptr)
    {
        return 0.0f;
    }
    auto property = wrappedProperty->customProperty();
    if (property->is<CustomPropertyNumber>())
    {
        return property->as<CustomPropertyNumber>()->propertyValue();
    }
    return 0.0f;
}

EXPORT bool getCustomPropertyBoolean(WrappedCustomProperty* wrappedProperty)
{
    if (wrappedProperty == nullptr)
    {
        return false;
    }
    auto property = wrappedProperty->customProperty();
    if (property->is<CustomPropertyBoolean>())
    {
        return property->as<CustomPropertyBoolean>()->propertyValue();
    }
    return false;
}

EXPORT const char* getCustomPropertyString(
    WrappedCustomProperty* wrappedProperty)
{
    if (wrappedProperty == nullptr)
    {
        return nullptr;
    }
    auto property = wrappedProperty->customProperty();
    if (property->is<CustomPropertyString>())
    {
        return property->as<CustomPropertyString>()->propertyValue().c_str();
    }
    return nullptr;
}

#if defined(__EMSCRIPTEN__)
static void _webLayoutChanged(void* artboardPtr)
{
    auto artboard = static_cast<WrappedArtboard*>(artboardPtr);
    auto itr = _webLayoutChangedCallbacks.find(artboard);
    if (itr != _webLayoutChangedCallbacks.end())
    {
        itr->second();
    }
}

static void _webLayoutDirty(void* artboardPtr)
{
    auto artboard = static_cast<WrappedArtboard*>(artboardPtr);
    auto itr = _webLayoutDirtyCallbacks.find(artboard);
    if (itr != _webLayoutDirtyCallbacks.end())
    {
        itr->second();
    }
}

static void _webEvent(WrappedArtboard* artboard, uint32_t id)
{
    auto itr = _webEventCallbacks.find(artboard);
    if (itr != _webEventCallbacks.end())
    {
        itr->second(id);
    }
}

static void _webInputChanged(StateMachineInstance* stateMachine, uint64_t index)
{
    auto itr = _webInputChangedCallbacks.find(stateMachine);
    if (itr != _webInputChangedCallbacks.end())
    {
        itr->second((uint32_t)index);
    }
}

static void _webDataBindChanged()
{
    for (auto it : _webDataBindChangedCallbacks)
    {
        it.second();
    }
}

EXPORT void setArtboardLayoutChangedCallback(
    WasmPtr artboardPtr,
    emscripten::val layoutChangedCallback)
{
    auto wrappedArtboard = (WrappedArtboard*)artboardPtr;
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    if (layoutChangedCallback.isNull())
    {
        _webLayoutChangedCallbacks.erase(wrappedArtboard);
        wrappedArtboard->artboard()->onLayoutChanged(nullptr);
    }
    else
    {
        _webLayoutChangedCallbacks[wrappedArtboard] = layoutChangedCallback;
        wrappedArtboard->artboard()->onLayoutChanged(_webLayoutChanged);
    }
}

EXPORT void setArtboardLayoutDirtyCallback(WasmPtr artboardPtr,
                                           emscripten::val layoutDirtyCallback)
{
    auto wrappedArtboard = (WrappedArtboard*)artboardPtr;
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    if (layoutDirtyCallback.isNull())
    {
        _webLayoutDirtyCallbacks.erase(wrappedArtboard);
        wrappedArtboard->artboard()->onLayoutDirty(nullptr);
    }
    else
    {
        _webLayoutDirtyCallbacks[wrappedArtboard] = layoutDirtyCallback;
        wrappedArtboard->artboard()->onLayoutDirty(_webLayoutDirty);
    }
}

EXPORT void setArtboardEventCallback(WasmPtr artboardPtr,
                                     emscripten::val eventCallback)
{
    auto wrappedArtboard = (WrappedArtboard*)artboardPtr;
    if (wrappedArtboard == nullptr)
    {
        return;
    }

    if (eventCallback.isNull())
    {
        _webEventCallbacks.erase(wrappedArtboard);
        wrappedArtboard->m_eventCallback = nullptr;
    }
    else
    {
        _webEventCallbacks[wrappedArtboard] = eventCallback;
        wrappedArtboard->m_eventCallback = _webEvent;
    }
}

EXPORT void setStateMachineInputChangedCallback(WasmPtr smiPtr,
                                                emscripten::val changedCallback)
{
    auto wrappedMachine = (WrappedStateMachine*)smiPtr;
    if (wrappedMachine == nullptr)
    {
        return;
    }
    auto smi = wrappedMachine->stateMachine();
    if (changedCallback.isNull())
    {
        _webInputChangedCallbacks.erase(smi);
        smi->onInputChanged(nullptr);
    }
    else
    {
        _webInputChangedCallbacks[smi] = changedCallback;
        smi->onInputChanged(_webInputChanged);
    }
}

static void setStateMachineDataBindChangedCallback(
    WasmPtr smiPtr,
    emscripten::val changedCallback)
{
    auto wrappedMachine = (WrappedStateMachine*)smiPtr;
    if (wrappedMachine == nullptr)
    {
        return;
    }
    auto smi = wrappedMachine->stateMachine();
    if (changedCallback.isNull())
    {
        _webDataBindChangedCallbacks.erase(smi);
        smi->onDataBindChanged(nullptr);
    }
    else
    {
        _webDataBindChangedCallbacks[smi] = changedCallback;
        smi->onDataBindChanged(_webDataBindChanged);
    }
}
#else
EXPORT void setArtboardEventCallback(WrappedArtboard* wrappedArtboard,
                                     EventCallback eventCallback)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    wrappedArtboard->m_eventCallback = eventCallback;
}

EXPORT void setArtboardLayoutChangedCallback(
    WrappedArtboard* wrappedArtboard,
    ArtboardCallback layoutChangedCallback)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    wrappedArtboard->artboard()->onLayoutChanged(layoutChangedCallback);
}

EXPORT void setArtboardLayoutDirtyCallback(WrappedArtboard* wrappedArtboard,
                                           ArtboardCallback layoutDirtyCallback)
{
    if (wrappedArtboard == nullptr)
    {
        return;
    }
    wrappedArtboard->artboard()->onLayoutDirty(layoutDirtyCallback);
}

EXPORT void setStateMachineInputChangedCallback(
    WrappedStateMachine* wrappedMachine,
    InputChanged changedCallback)
{
    if (wrappedMachine == nullptr)
    {
        return;
    }
    wrappedMachine->stateMachine()->onInputChanged(changedCallback);
}

EXPORT void setStateMachineDataBindChangedCallback(
    WrappedStateMachine* wrappedMachine,
    DataBindChanged changedCallback)
{
    if (wrappedMachine == nullptr)
    {
        return;
    }
    wrappedMachine->stateMachine()->onDataBindChanged(changedCallback);
}
#endif

static void vmiNumberCallback(ViewModelInstanceNumber* vmi, float value)
{
    if (!CALLBACK_VALID(g_viewModelUpdateNumber))
    {
        return;
    }
    auto pointer = reinterpret_cast<std::uintptr_t>(vmi);
    g_viewModelUpdateNumber(pointer, value);
}

static void vmiBooleanCallback(ViewModelInstanceBoolean* vmi, bool value)
{
    if (!CALLBACK_VALID(g_viewModelUpdateBoolean))
    {
        return;
    }
    auto pointer = reinterpret_cast<std::uintptr_t>(vmi);
    g_viewModelUpdateBoolean(pointer, value);
}

static void vmiColorCallback(ViewModelInstanceColor* vmi, int value)
{
    if (!CALLBACK_VALID(g_viewModelUpdateColor))
    {
        return;
    }
    auto pointer = reinterpret_cast<std::uintptr_t>(vmi);
    g_viewModelUpdateColor(pointer, value);
}

static void vmiStringCallback(ViewModelInstanceString* vmi, const char* value)
{
    if (!CALLBACK_VALID(g_viewModelUpdateString))
    {
        return;
    }
    auto pointer = reinterpret_cast<std::uintptr_t>(vmi);
#if defined(__EMSCRIPTEN__)
    g_viewModelUpdateString(pointer, std::string(value));
#else
    g_viewModelUpdateString(pointer, value);
#endif
}

static void vmiTriggerCallback(ViewModelInstanceTrigger* vmi, uint32_t value)
{
    if (!CALLBACK_VALID(g_viewModelUpdateTrigger))
    {
        return;
    }
    auto pointer = reinterpret_cast<std::uintptr_t>(vmi);
    g_viewModelUpdateTrigger(pointer, value);
}

static void vmiEnumCallback(ViewModelInstanceEnum* vmi, uint32_t value)
{
    if (!CALLBACK_VALID(g_viewModelUpdateEnum))
    {
        return;
    }
    auto pointer = reinterpret_cast<std::uintptr_t>(vmi);
    g_viewModelUpdateEnum(pointer, value);
}

EXPORT ViewModelInstanceNumber* setViewModelInstanceNumberCallback(
    WrappedViewModelInstanceValue* wrappedViewModelInstance)
{
    if (wrappedViewModelInstance == nullptr ||
        wrappedViewModelInstance->instance() == nullptr)
    {
        return nullptr;
    }
    ViewModelInstanceNumber* viewModelInstanceNumber =
        wrappedViewModelInstance->instance()->as<ViewModelInstanceNumber>();
    viewModelInstanceNumber->onChanged(vmiNumberCallback);
    return viewModelInstanceNumber;
}

EXPORT ViewModelInstanceBoolean* setViewModelInstanceBooleanCallback(
    WrappedViewModelInstanceValue* wrappedViewModelInstance)
{
    if (wrappedViewModelInstance == nullptr ||
        wrappedViewModelInstance->instance() == nullptr)
    {
        return nullptr;
    }
    ViewModelInstanceBoolean* viewModelInstanceBoolean =
        wrappedViewModelInstance->instance()->as<ViewModelInstanceBoolean>();
    viewModelInstanceBoolean->onChanged(vmiBooleanCallback);
    return viewModelInstanceBoolean;
}

EXPORT ViewModelInstanceColor* setViewModelInstanceColorCallback(
    WrappedViewModelInstanceValue* wrappedViewModelInstance)
{
    if (wrappedViewModelInstance == nullptr ||
        wrappedViewModelInstance->instance() == nullptr)
    {
        return nullptr;
    }
    ViewModelInstanceColor* viewModelInstanceColor =
        wrappedViewModelInstance->instance()->as<ViewModelInstanceColor>();
    viewModelInstanceColor->onChanged(vmiColorCallback);
    return viewModelInstanceColor;
}

EXPORT ViewModelInstanceString* setViewModelInstanceStringCallback(
    WrappedViewModelInstanceValue* wrappedViewModelInstance)
{
    if (wrappedViewModelInstance == nullptr ||
        wrappedViewModelInstance->instance() == nullptr)
    {
        return nullptr;
    }
    ViewModelInstanceString* viewModelInstanceString =
        wrappedViewModelInstance->instance()->as<ViewModelInstanceString>();
    viewModelInstanceString->onChanged(vmiStringCallback);
    return viewModelInstanceString;
}

EXPORT ViewModelInstanceTrigger* setViewModelInstanceTriggerCallback(
    WrappedViewModelInstanceValue* wrappedViewModelInstance)
{
    if (wrappedViewModelInstance == nullptr ||
        wrappedViewModelInstance->instance() == nullptr)
    {
        return nullptr;
    }
    ViewModelInstanceTrigger* viewModelInstanceTrigger =
        wrappedViewModelInstance->instance()->as<ViewModelInstanceTrigger>();
    viewModelInstanceTrigger->onChanged(vmiTriggerCallback);
    return viewModelInstanceTrigger;
}

EXPORT void setViewModelInstanceTriggerAdvanced(
    WrappedViewModelInstanceValue* wrappedViewModelInstance)
{
    if (wrappedViewModelInstance == nullptr ||
        wrappedViewModelInstance == nullptr ||
        wrappedViewModelInstance->instance() == nullptr)
    {
        return;
    }
    ViewModelInstanceTrigger* viewModelInstanceTrigger =
        wrappedViewModelInstance->instance()->as<ViewModelInstanceTrigger>();
    viewModelInstanceTrigger->advanced();
}

EXPORT ViewModelInstanceEnum* setViewModelInstanceEnumCallback(
    WrappedViewModelInstanceValue* wrappedViewModelInstance)
{
    if (wrappedViewModelInstance == nullptr ||
        wrappedViewModelInstance->instance() == nullptr)
    {
        return nullptr;
    }
    ViewModelInstanceEnum* viewModelInstanceEnum =
        wrappedViewModelInstance->instance()->as<ViewModelInstanceEnum>();
    viewModelInstanceEnum->onChanged(vmiEnumCallback);
    return viewModelInstanceEnum;
}

EXPORT void deleteArtboardInstance(WrappedArtboard* artboardInstance)
{
    if (artboardInstance == nullptr)
    {
        return;
    }
    std::unique_lock<std::mutex> lock(g_deleteMutex);
    artboardInstance->deleteDataBinds();
    artboardInstance->unref();
}

EXPORT void deleteStateMachineInstance(WrappedStateMachine* wrappedMachine)
{
    if (wrappedMachine == nullptr)
    {
        return;
    }
    std::unique_lock<std::mutex> lock(g_deleteMutex);
#if defined(__EMSCRIPTEN__)
    _webInputChangedCallbacks.erase(wrappedMachine->stateMachine());
#endif
    wrappedMachine->unref();
}

EXPORT WrappedInput* stateMachineInput(WrappedStateMachine* wrappedMachine,
                                       SizeType index)
{
    if (wrappedMachine == nullptr)
    {
        return nullptr;
    }
    auto input = wrappedMachine->stateMachine()->input((size_t)index);
    if (input == nullptr)
    {
        return nullptr;
    }
    return new WrappedInput(ref_rcp(wrappedMachine), input);
}

EXPORT const char* stateMachineInputName(WrappedInput* wrappedInput)
{
    if (wrappedInput == nullptr)
    {
        return nullptr;
    }
    return wrappedInput->input()->name().c_str();
}

EXPORT uint16_t stateMachineInputType(WrappedInput* wrappedInput)
{
    if (wrappedInput == nullptr)
    {
        return 0;
    }
    return wrappedInput->input()->inputCoreType();
}

EXPORT WrappedInput* stateMachineInstanceNumber(
    WrappedStateMachine* wrappedMachine,
    const char* name,
    const char* path)
{
    if (wrappedMachine == nullptr || name == nullptr)
    {
        return nullptr;
    }
    auto number =
        (path != nullptr)
            ? wrappedMachine->wrappedArtboard()->artboard()->getNumber(name,
                                                                       path)
            : wrappedMachine->stateMachine()->getNumber(name);
    if (number == nullptr)
    {
        return nullptr;
    }
    return new WrappedInput(ref_rcp(wrappedMachine), number);
}

EXPORT bool stateMachineInstanceDone(WrappedStateMachine* wrappedMachine)
{
    if (wrappedMachine == nullptr)
    {
        return false;
    }
    return !wrappedMachine->stateMachine()->needsAdvance();
}

EXPORT float getNumberValue(WrappedInput* wrappedInput)
{
    if (wrappedInput == nullptr)
    {
        return 0.0f;
    }
    auto number = wrappedInput->number();
    if (number == nullptr)
    {
        return 0.0f;
    }
    return number->value();
}

EXPORT void setNumberValue(WrappedInput* wrappedInput, float value)
{
    if (wrappedInput == nullptr)
    {
        return;
    }
    auto number = wrappedInput->number();
    if (number == nullptr)
    {
        return;
    }
    number->value(value);
}

EXPORT WrappedInput* stateMachineInstanceBoolean(
    WrappedStateMachine* wrappedMachine,
    const char* name,
    const char* path)
{
    if (wrappedMachine == nullptr || name == nullptr)
    {
        return nullptr;
    }
    auto boolean =
        (path != nullptr)
            ? wrappedMachine->wrappedArtboard()->artboard()->getBool(name, path)
            : wrappedMachine->stateMachine()->getBool(name);
    if (boolean == nullptr)
    {
        return nullptr;
    }
    return new WrappedInput(ref_rcp(wrappedMachine), boolean);
}

EXPORT bool getBooleanValue(WrappedInput* wrappedInput)
{
    if (wrappedInput == nullptr)
    {
        return false;
    }
    auto boolean = wrappedInput->boolean();
    if (boolean == nullptr)
    {
        return false;
    }
    return boolean->value();
}

EXPORT void setBooleanValue(WrappedInput* wrappedInput, bool value)
{
    if (wrappedInput == nullptr)
    {
        return;
    }
    auto boolean = wrappedInput->boolean();
    if (boolean == nullptr)
    {
        return;
    }
    boolean->value(value);
}

EXPORT WrappedInput* stateMachineInstanceTrigger(
    WrappedStateMachine* wrappedMachine,
    const char* name,
    const char* path)
{
    if (wrappedMachine == nullptr || name == nullptr)
    {
        return nullptr;
    }
    auto trigger =
        (path != nullptr)
            ? wrappedMachine->wrappedArtboard()->artboard()->getTrigger(name,
                                                                        path)
            : wrappedMachine->stateMachine()->getTrigger(name);
    if (trigger == nullptr)
    {
        return nullptr;
    }
    return new WrappedInput(ref_rcp(wrappedMachine), trigger);
}

EXPORT void fireTrigger(WrappedInput* wrappedInput)
{
    if (wrappedInput == nullptr)
    {
        return;
    }
    wrappedInput->fire();
}

EXPORT void deleteInput(WrappedInput* wrappedInput)
{
    std::unique_lock<std::mutex> lock(g_deleteMutex);
    delete wrappedInput;
}

/// Factory callbacks to allow native to create and destroy Flutter
/// resources.
EXPORT void initBindingCallbacks(ViewModelUpdateNumber viewModelUpdateNumber,
                                 ViewModelUpdateBoolean viewModelUpdateBoolean,
                                 ViewModelUpdateColor viewModelUpdateColor,
                                 ViewModelUpdateString viewModelUpdateString,
                                 ViewModelUpdateTrigger viewModelUpdateTrigger,
                                 ViewModelUpdateEnum viewModelUpdateEnum)
{
    g_viewModelUpdateNumber = viewModelUpdateNumber;
    g_viewModelUpdateBoolean = viewModelUpdateBoolean;
    g_viewModelUpdateColor = viewModelUpdateColor;
    g_viewModelUpdateString = viewModelUpdateString;
    g_viewModelUpdateTrigger = viewModelUpdateTrigger;
    g_viewModelUpdateEnum = viewModelUpdateEnum;
}

#ifdef WITH_RIVE_WORKER
#include <condition_variable>
#include <deque>
#include <thread>

struct Work
{
    rcp<WrappedStateMachine> smi;
    bool done;
};

class RiveWorker
{
private:
    static const int threadCount = 6;
    static RiveWorker* sm_instance;
    static bool sm_exiting;
    std::vector<Work> m_work;
    std::condition_variable m_haveWork;
    std::condition_variable m_didSomeWork;
    std::vector<std::thread> m_workThreads;
    std::mutex m_mutex;
    float m_elapsedSeconds;
    uint64_t m_workIndex = 0;
    uint64_t m_completed = 0;
    uint64_t m_toComplete = 0;

    RiveWorker()
    {
        std::atexit(atExit);
        for (int i = 0; i < threadCount; i++)
        {
            m_workThreads.emplace_back(std::thread(staticWorkThread, this));
        }
    }

    void workThread()
    {
        while (!sm_exiting)
        {
            Work* work = nullptr;
            {
                std::unique_lock<std::mutex> lock(m_mutex);
                if (m_workIndex < m_work.size())
                {
                    work = &m_work[m_workIndex++];
                }
                else
                {
                    m_haveWork.wait_for(lock, std::chrono::milliseconds(100));
                }
            }
            if (work != nullptr)
            {
                work->smi->stateMachine()->advanceAndApply(m_elapsedSeconds);
                std::unique_lock<std::mutex> lock(m_mutex);
                work->done = true;
                m_completed++;
            }
            m_didSomeWork.notify_all();
        }
    }

    static void staticWorkThread(void* w)
    {
        RiveWorker* worker = static_cast<RiveWorker*>(w);
        worker->workThread();
    }

    static void atExit() { sm_exiting = true; }

public:
    static RiveWorker* get()
    {
        if (sm_instance == nullptr)
        {
            sm_instance = new RiveWorker();
        }

        return sm_instance;
    }

    void add(float elapsedSeconds, WrappedStateMachine** smi, uint64_t count)
    {
        {
            std::unique_lock<std::mutex> lock(m_mutex);
            m_elapsedSeconds = elapsedSeconds;
            m_toComplete = count;
            m_completed = 0;
            m_workIndex = 0;
            m_work.clear();
            for (uint64_t i = 0; i < count; i++)
            {
                m_work.push_back({ref_rcp(smi[i]), false});
            }
        }
        m_haveWork.notify_all();
    }

    void complete(
        std::function<void(rcp<WrappedStateMachine>)> callback = nullptr)
    {
        int completedIndex = 0;
        while (!sm_exiting)
        {
            // Keep rendering artboards that are done.
            std::unique_lock<std::mutex> lock(m_mutex);
            if (callback != nullptr)
            {
                // Any artboards ready to draw?
                if (completedIndex < m_toComplete &&
                    m_work[completedIndex].done)
                {
                    // While locked, count how many we can draw unlocked.
                    uint64_t completedFrom = completedIndex;
                    while (++completedIndex < m_toComplete &&
                           m_work[completedIndex].done)
                    {
                        // Intentionally empty.
                    }
                    lock.unlock();
                    while (completedFrom < completedIndex)
                    {
                        callback(m_work[completedFrom].smi);
                        completedFrom++;
                    }
                    continue;
                }
            }
            if (m_toComplete == m_completed)
            {
                break;
            }
            m_didSomeWork.wait_for(lock, std::chrono::milliseconds(100));
        }
    }
};

RiveWorker* RiveWorker::sm_instance = nullptr;
bool RiveWorker::sm_exiting = false;
#endif

EXPORT void stateMachineInstanceBatchAdvance(WrappedStateMachine** smi,
                                             SizeType count,
                                             float elapsedSeconds)
{
#ifdef WITH_RIVE_WORKER
    RiveWorker* worker = RiveWorker::get();
    worker->add(elapsedSeconds, smi, count);
    worker->complete();
#else
    for (int i = 0; i < count; i++)
    {
        smi[i]->stateMachine()->advanceAndApply(elapsedSeconds);
    }
#endif
}

EXPORT void stateMachineInstanceBatchAdvanceAndRender(WrappedStateMachine** smi,
                                                      SizeType count,
                                                      float elapsedSeconds,
                                                      Renderer* renderer)
{
    if (renderer == nullptr)
    {
        return;
    }
#ifdef WITH_RIVE_WORKER
    RiveWorker* worker = RiveWorker::get();
    worker->add(elapsedSeconds, smi, count);
    worker->complete([&](rcp<WrappedStateMachine> smi) {
        WrappedArtboard* wrappedArtboard = static_cast<WrappedArtboard*>(
            smi->stateMachine()->artboard()->callbackUserData);
        renderer->save();
        renderer->transform(wrappedArtboard->renderTransform);
        wrappedArtboard->artboard()->draw(renderer);
        renderer->restore();
    });
#else
    for (int i = 0; i < count; i++)
    {
        smi[i]->stateMachine()->advanceAndApply(elapsedSeconds);
        WrappedArtboard* wrappedArtboard = static_cast<WrappedArtboard*>(
            smi[i]->stateMachine()->artboard()->callbackUserData);
        renderer->save();
        renderer->transform(wrappedArtboard->renderTransform);
        wrappedArtboard->artboard()->draw(renderer);
        renderer->restore();
    }
    return;
#endif
}

EXPORT void wasmStateMachineInstanceBatchAdvance(uint32_t wasmPtr,
                                                 uint32_t count,
                                                 float elapsedSeconds)
{
    WrappedStateMachine** smi =
        reinterpret_cast<WrappedStateMachine**>(wasmPtr);
    stateMachineInstanceBatchAdvance(smi, count, elapsedSeconds);
}

EXPORT void wasmStateMachineInstanceBatchAdvanceAndRender(uint32_t wasmPtr,
                                                          uint32_t count,
                                                          float elapsedSeconds,
                                                          Renderer* renderer)
{
    WrappedStateMachine** smi =
        reinterpret_cast<WrappedStateMachine**>(wasmPtr);
    stateMachineInstanceBatchAdvanceAndRender(smi,
                                              count,
                                              elapsedSeconds,
                                              renderer);
}

static TextValueRun* artboardFindRun(Artboard* artboard, const char* name)
{
    TextValueRun* run = artboard->find<TextValueRun>(name);
    if (run != nullptr)
    {
        return run;
    }
    for (NestedArtboard* nestedArtboard : artboard->nestedArtboards())
    {
        run = artboardFindRun(nestedArtboard->artboard(), name);
        if (run != nullptr)
        {
            return run;
        }
    }
    return nullptr;
}

EXPORT RawText* makeRawText(Factory* factory) { return new RawText(factory); }

EXPORT void deleteRawText(RawText* rawText) { delete rawText; }

EXPORT void rawTextAppend(RawText* rawText,
                          const char* text,
                          RenderPaint* paint,
                          Font* font,
                          float size,
                          float lineHeight,
                          float letterSpacing)
{
    if (rawText == nullptr)
    {
        return;
    }
    std::string textString = text;
    rawText->append(textString,
                    ref_rcp(paint),
                    ref_rcp(font),
                    size,
                    lineHeight,
                    letterSpacing);
}

EXPORT void rawTextClear(RawText* rawText)
{
    if (rawText == nullptr)
    {
        return;
    }
    rawText->clear();
}

EXPORT bool rawTextIsEmpty(RawText* rawText)
{
    if (rawText == nullptr)
    {
        return true;
    }
    return rawText->empty();
}

EXPORT uint8_t rawTextGetSizing(RawText* rawText)
{
    if (rawText == nullptr)
    {
        return 0;
    }
    return (uint8_t)rawText->sizing();
}

EXPORT void rawTextSetSizing(RawText* rawText, uint8_t sizing)
{
    if (rawText == nullptr)
    {
        return;
    }
    rawText->sizing((TextSizing)sizing);
}

EXPORT uint8_t rawTextGetOverflow(RawText* rawText)
{
    if (rawText == nullptr)
    {
        return 0;
    }
    return (uint8_t)rawText->overflow();
}

EXPORT void rawTextSetOverflow(RawText* rawText, uint8_t overflow)
{
    if (rawText == nullptr)
    {
        return;
    }
    rawText->overflow((TextOverflow)overflow);
}

EXPORT uint8_t rawTextGetAlign(RawText* rawText)
{
    if (rawText == nullptr)
    {
        return 0;
    }
    return (uint8_t)rawText->align();
}

EXPORT void rawTextSetAlign(RawText* rawText, uint8_t align)
{
    if (rawText == nullptr)
    {
        return;
    }
    rawText->align((TextAlign)align);
}

EXPORT float rawTextGetMaxWidth(RawText* rawText)
{
    if (rawText == nullptr)
    {
        return 0;
    }
    return rawText->maxWidth();
}

EXPORT void rawTextSetMaxWidth(RawText* rawText, float maxWidth)
{
    if (rawText == nullptr)
    {
        return;
    }
    rawText->maxWidth(maxWidth);
}

EXPORT float rawTextGetMaxHeight(RawText* rawText)
{
    if (rawText == nullptr)
    {
        return 0;
    }
    return rawText->maxHeight();
}

EXPORT void rawTextSetMaxHeight(RawText* rawText, float maxHeight)
{
    if (rawText == nullptr)
    {
        return;
    }
    rawText->maxHeight(maxHeight);
}

EXPORT float rawTextGetParagraphSpacing(RawText* rawText)
{
    if (rawText == nullptr)
    {
        return 0;
    }
    return rawText->paragraphSpacing();
}

EXPORT void rawTextSetParagraphSpacing(RawText* rawText, float paragraphSpacing)
{
    if (rawText == nullptr)
    {
        return;
    }
    rawText->paragraphSpacing(paragraphSpacing);
}

EXPORT void rawTextBounds(RawText* rawText, float* out)
{
    if (rawText == nullptr)
    {
        return;
    }
    AABB bounds = rawText->bounds();
    memcpy(out, &bounds, sizeof(float) * 4);
}

EXPORT void rawTextRender(RawText* rawText,
                          Renderer* renderer,
                          RenderPaint* renderPaint)
{
    if (rawText == nullptr || renderer == nullptr)
    {
        return;
    }
    // null render paint is allowed
    rawText->render(renderer, ref_rcp(renderPaint));
}

#ifdef __EMSCRIPTEN__
EMSCRIPTEN_BINDINGS(RiveBinding)
{
    function("loadRiveFile", &loadRiveFile, allow_raw_pointers());
    emscripten::function("riveFileAssetName",
                         &riveFileAssetName,
                         allow_raw_pointers());
    emscripten::function("riveFileAssetFileExtension",
                         &riveFileAssetFileExtension,
                         allow_raw_pointers());
    emscripten::function("riveFileAssetCdnBaseUrl",
                         &riveFileAssetCdnBaseUrl,
                         allow_raw_pointers());
    emscripten::function("riveFileAssetCdnUuid",
                         &riveFileAssetCdnUuid,
                         allow_raw_pointers());
    function("stateMachineReportedEventAt", &stateMachineReportedEventAt);
    function("viewModelRuntimeProperties", &viewModelRuntimeProperties);
    function("fileEnums", &fileEnums);
    function("vmiRuntimeProperties", &vmiRuntimeProperties);
    function("getEventCustomProperty", &getEventCustomProperty);
    emscripten::function("getVMIEnumRuntimeValue",
                         &getVMIEnumRuntimeValue,
                         allow_raw_pointers());
    function("setArtboardLayoutChangedCallback",
             &setArtboardLayoutChangedCallback);
    function("setArtboardLayoutDirtyCallback", &setArtboardLayoutDirtyCallback);
    function("setStateMachineInputChangedCallback",
             &setStateMachineInputChangedCallback);
    function("setArtboardEventCallback", &setArtboardEventCallback);
    function("setStateMachineDataBindChangedCallback",
             &setStateMachineDataBindChangedCallback);
    function("initBindingCallbacks", &initBindingCallbacks);

    value_object<FlutterRuntimeReportedEvent>("FlutterRuntimeReportedEvent")
        .field("event", &FlutterRuntimeReportedEvent::event)
        .field("secondsDelay", &FlutterRuntimeReportedEvent::secondsDelay)
        .field("type", &FlutterRuntimeReportedEvent::type);

    value_object<FlutterRuntimeCustomProperty>("FlutterRuntimeCustomProperty")
        .field("property", &FlutterRuntimeCustomProperty::property)
        .field("name", &FlutterRuntimeCustomProperty::name)
        .field("type", &FlutterRuntimeCustomProperty::type);
}
#endif
#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include <emscripten/bind.h>
#include <emscripten/val.h>
#include <stdint.h>
#include "rive/audio/audio_engine.hpp"
#include "rive/audio/audio_reader.hpp"
#include "rive/audio/audio_sound.hpp"
#include "rive/audio/audio_source.hpp"
#ifdef __EMSCRIPTEN_PTHREADS__
#include "audio_decode_worker.hpp"
#endif

#include <stdio.h>
#include <cstdint>

using namespace emscripten;

using WasmPtr = uint32_t;
#ifdef __EMSCRIPTEN_PTHREADS__
rive::AudioDecodeWorker g_decodeWorker;
bool rive::AudioDecodeWorker::sm_exiting = false;
#endif

WasmPtr makeAudioEngine(uint32_t numChannels, uint32_t sampleRate)
{
    return (WasmPtr)rive::AudioEngine::Make(numChannels, sampleRate).release();
}

uint32_t engineTime(WasmPtr enginePtr)
{
    rive::AudioEngine* engine = (rive::AudioEngine*)enginePtr;
    if (engine == nullptr)
    {
        return 0;
    }
    return engine->timeInFrames();
}

void engineInitLevelMonitor(WasmPtr enginePtr)
{
    rive::AudioEngine* engine = (rive::AudioEngine*)enginePtr;
    if (engine == nullptr)
    {
        return;
    }
    engine->initLevelMonitor();
}

float engineLevel(WasmPtr enginePtr, uint32_t channel)
{
    rive::AudioEngine* engine = (rive::AudioEngine*)enginePtr;
    if (engine == nullptr)
    {
        return 0.0f;
    }
    return engine->level(channel);
}

uint32_t audioSourceNumChannels(WasmPtr sourcePtr)
{
    rive::AudioSource* source = (rive::AudioSource*)sourcePtr;
    if (source == nullptr)
    {
        return 0;
    }
    return source->channels();
}

uint32_t audioSourceSampleRate(WasmPtr sourcePtr)
{
    rive::AudioSource* source = (rive::AudioSource*)sourcePtr;
    if (source == nullptr)
    {
        return 0;
    }
    return source->sampleRate();
}

uint32_t audioSourceFormat(WasmPtr sourcePtr)
{
    rive::AudioSource* source = (rive::AudioSource*)sourcePtr;
    if (source == nullptr)
    {
        return 0;
    }
    return (uint32_t)source->format();
}

uint32_t numChannels(WasmPtr enginePtr)
{
    rive::AudioEngine* engine = (rive::AudioEngine*)enginePtr;
    if (engine == nullptr)
    {
        return 0;
    }
    return engine->channels();
}

uint32_t sampleRate(WasmPtr enginePtr)
{
    rive::AudioEngine* engine = (rive::AudioEngine*)enginePtr;
    if (engine == nullptr)
    {
        return 0;
    }
    return engine->sampleRate();
}

void unrefAudioEngine(WasmPtr enginePtr)
{
    rive::AudioEngine* engine = (rive::AudioEngine*)enginePtr;
    if (engine == nullptr)
    {
        return;
    }
    engine->unref();
}

WasmPtr makeAudioSourceBuffer(uint32_t byteSize)
{
    return (WasmPtr) new rive::SimpleArray<uint8_t>((size_t)byteSize);
}

WasmPtr simpleArrayData(WasmPtr simpleArrayPtr)
{
    rive::SimpleArray<uint8_t>* simpleArray =
        (rive::SimpleArray<uint8_t>*)simpleArrayPtr;
    if (simpleArray == nullptr)
    {
        return 0;
    }
    return (WasmPtr)simpleArray->data();
}

#ifdef DEBUG
uint32_t simpleArraySize(WasmPtr simpleArrayPtr)
{
    rive::SimpleArray<uint8_t>* simpleArray =
        (rive::SimpleArray<uint8_t>*)simpleArrayPtr;
    if (simpleArray == nullptr)
    {
        return 0;
    }
    return (uint32_t)simpleArray->size();
}
#endif

WasmPtr makeAudioSource(WasmPtr sourceBytesPtr)
{
    rive::SimpleArray<uint8_t>* sourceBytes =
        (rive::SimpleArray<uint8_t>*)sourceBytesPtr;
    if (sourceBytes == nullptr)
    {
        return (WasmPtr) nullptr;
    }

    return (WasmPtr) new rive::AudioSource(*sourceBytes);
}

struct SamplesSpan
{
    WasmPtr data;
    uint32_t count;
};

#ifdef __EMSCRIPTEN_PTHREADS__
WasmPtr makeAudioReader(WasmPtr sourcePtr,
                        uint32_t channels,
                        uint32_t sampleRate)
{
    rive::AudioSource* source = (rive::AudioSource*)sourcePtr;
    if (source == nullptr)
    {
        return (WasmPtr) nullptr;
    }

    auto reader = source->makeReader(channels, sampleRate);
    if (reader == nullptr)
    {
        return (WasmPtr) nullptr;
    }

    return (WasmPtr)g_decodeWorker.add(reader).release();
}

SamplesSpan audioReaderRead(WasmPtr workPtr)
{
    rive::DecodeWork* decodeWork = (rive::DecodeWork*)workPtr;
    if (decodeWork == nullptr || !decodeWork->isDone())
    {
        return {(WasmPtr) nullptr, 0};
    }

    auto frames = decodeWork->frames();
    return {(WasmPtr)frames.data(), (uint32_t)frames.count()};
}
#else
// No pthread support so we'll fake it...
namespace rive
{
class DecodeWork : public RefCnt<DecodeWork>
{
public:
    DecodeWork(rcp<AudioReader> audioReader) :
        m_audioReader(std::move(audioReader)), m_lengthInFrames(0)
    {}

    AudioReader* audioReader() { return m_audioReader.get(); }
    std::vector<float>& frames() { return m_frames; }
    uint64_t lengthInFrames() { return m_lengthInFrames; }
    void lengthInFrames(uint64_t value) { m_lengthInFrames = value; }

private:
    rcp<AudioReader> m_audioReader;
    std::vector<float> m_frames;
    uint64_t m_lengthInFrames;
};
} // namespace rive

WasmPtr makeAudioReader(WasmPtr sourcePtr,
                        uint32_t channels,
                        uint32_t sampleRate)
{
    rive::AudioSource* source = (rive::AudioSource*)sourcePtr;
    if (source == nullptr)
    {
        return (WasmPtr) nullptr;
    }

    auto reader = source->makeReader(channels, sampleRate);
    if (reader == nullptr)
    {
        return (WasmPtr) nullptr;
    }

    return (WasmPtr) new rive::DecodeWork(reader);
}

SamplesSpan audioReaderRead(WasmPtr workPtr)
{
    rive::DecodeWork* decodeWork = (rive::DecodeWork*)workPtr;
    if (decodeWork == nullptr)
    {
        return {(WasmPtr) nullptr, 0};
    }
    auto reader = decodeWork->audioReader();
    // 1 second at a time?
    auto readSize = (int)reader->sampleRate();
    auto readSpan = decodeWork->audioReader()->read(readSize);
    std::vector<float>& frames = decodeWork->frames();
    frames.insert(frames.end(), readSpan.begin(), readSpan.end());
    if (readSpan.size() == readSize * reader->channels())
    {
        // Not done yet.
        return {(WasmPtr) nullptr, 0};
    }
    // done.
    decodeWork->lengthInFrames((uint64_t)(frames.size() / reader->channels()));
    return {(WasmPtr)frames.data(), (uint32_t)frames.size()};
}

#endif

WasmPtr makeBufferedAudioSource(WasmPtr decodeWorkPtr,
                                uint32_t channels,
                                uint32_t sampleRate)
{
    rive::DecodeWork* decodeWork = (rive::DecodeWork*)decodeWorkPtr;
    if (decodeWork == nullptr)
    {
        return (WasmPtr) nullptr;
    }
    return (WasmPtr) new rive::AudioSource(decodeWork->frames(),
                                           channels,
                                           sampleRate);
}

SamplesSpan bufferedAudioSamples(WasmPtr audioSourcePtr)
{
    rive::AudioSource* audioSource = (rive::AudioSource*)audioSourcePtr;
    if (audioSource == nullptr)
    {
        return {(WasmPtr) nullptr, 0};
    }
    auto samples = audioSource->bufferedSamples();
    return {(WasmPtr)samples.data(), samples.size()};
}

void unrefAudioReader(WasmPtr decodeWorkPtr)
{
    rive::DecodeWork* decodeWork = (rive::DecodeWork*)decodeWorkPtr;
    if (decodeWork != nullptr)
    {
        decodeWork->unref();
    }
}

void unrefAudioSource(WasmPtr sourcePtr)
{
    rive::AudioSource* audioSource = (rive::AudioSource*)sourcePtr;
    if (audioSource != nullptr)
    {
        audioSource->unref();
    }
}

void stopAudioSound(WasmPtr soundPtr, uint32_t fadeTimeInFrames)
{
    rive::AudioSound* sound = (rive::AudioSound*)soundPtr;
    if (sound == nullptr)
    {
        return;
    }
    sound->stop(fadeTimeInFrames);
}

float getSoundVolume(WasmPtr soundPtr)
{
    rive::AudioSound* sound = (rive::AudioSound*)soundPtr;
    if (sound == nullptr)
    {
        return 0.0f;
    }
    return sound->volume();
}

bool getSoundCompleted(WasmPtr soundPtr)
{
    rive::AudioSound* sound = (rive::AudioSound*)soundPtr;
    if (sound == nullptr)
    {
        return true;
    }
    return sound->completed();
}

void setSoundVolume(WasmPtr soundPtr, float volume)
{
    rive::AudioSound* sound = (rive::AudioSound*)soundPtr;
    if (sound == nullptr)
    {
        return;
    }
    sound->volume(volume);
}

void unrefAudioSound(WasmPtr soundPtr)
{
    rive::AudioSound* sound = (rive::AudioSound*)soundPtr;
    if (sound == nullptr)
    {
        return;
    }
    sound->unref();
}

WasmPtr playAudioSource(WasmPtr sourcePtr,
                        WasmPtr enginePtr,
                        uint32_t engineStartTime,
                        uint32_t engineEndTime,
                        uint32_t soundStartTime)
{
    rive::AudioEngine* engine = (rive::AudioEngine*)enginePtr;
    if (engine == nullptr)
    {
        return (WasmPtr) nullptr;
    }
    rive::AudioSource* audioSource = (rive::AudioSource*)sourcePtr;
    if (audioSource == nullptr)
    {
        return (WasmPtr) nullptr;
    }

    rive::rcp<rive::AudioSource> rcAudioSource =
        rive::rcp<rive::AudioSource>(audioSource);
    rcAudioSource->ref();

    return (WasmPtr)engine
        ->play(rcAudioSource, engineStartTime, engineEndTime, soundStartTime)
        .release();
}

EMSCRIPTEN_BINDINGS(RiveAudio)
{
    value_object<SamplesSpan>("SamplesSpan")
        .field("data", &SamplesSpan::data)
        .field("count", &SamplesSpan::count);

    function("makeAudioEngine", &makeAudioEngine);
    function("engineTime", &engineTime);
    function("engineInitLevelMonitor", &engineInitLevelMonitor);
    function("engineLevel", &engineLevel);
    function("numChannels", &numChannels);
    function("sampleRate", &sampleRate);
    function("audioSourceNumChannels", &audioSourceNumChannels);
    function("audioSourceSampleRate", &audioSourceSampleRate);
    function("audioSourceFormat", &audioSourceFormat);
    function("unrefAudioEngine", &unrefAudioEngine);
    function("makeBufferedAudioSource", &makeBufferedAudioSource);
    function("bufferedAudioSamples", &bufferedAudioSamples);
    function("makeAudioSourceBuffer", &makeAudioSourceBuffer);
    function("makeAudioSource", &makeAudioSource);
    function("simpleArrayData", &simpleArrayData);
#ifdef DEBUG
    function("simpleArraySize", &simpleArraySize);
#endif
    function("makeAudioReader", &makeAudioReader);
    function("unrefAudioSource", &unrefAudioSource);
    function("unrefAudioReader", &unrefAudioReader);
    function("playAudioSource", &playAudioSource);
    function("audioReaderRead", &audioReaderRead);
    function("stopAudioSound", &stopAudioSound);
    function("getSoundVolume", &getSoundVolume);
    function("getSoundCompleted", &getSoundCompleted);
    function("setSoundVolume", &setSoundVolume);
    function("unrefAudioSound", &unrefAudioSound);
}
#else
#include "rive/audio/audio_engine.hpp"
#include "rive/audio/audio_reader.hpp"
#include "rive/audio/audio_sound.hpp"
#include "rive/audio/audio_source.hpp"
#include "rive/audio/audio_format.hpp"
#include "rive/audio/audio_format.hpp"
#include "audio_decode_worker.hpp"
#include <stdio.h>
#include <cstdint>

#if defined(_MSC_VER)
#define EXPORT extern "C" __declspec(dllexport)
#else
#define EXPORT                                                                 \
    extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif

#ifdef WITH_RIVE_AUDIO
rive::AudioDecodeWorker* g_decodeWorker;
static rive::AudioDecodeWorker* decodeWorker()
{
    if (g_decodeWorker == nullptr)
    {
        g_decodeWorker = new rive::AudioDecodeWorker();
    }
    return g_decodeWorker;
}
bool rive::AudioDecodeWorker::sm_exiting = false;
#endif

EXPORT rive::AudioEngine* makeAudioEngine(uint32_t numChannels,
                                          uint32_t sampleRate)
{
#ifdef WITH_RIVE_AUDIO
    return rive::AudioEngine::Make(numChannels, sampleRate).release();
#else
    return nullptr;
#endif
}

EXPORT uint64_t engineTime(rive::AudioEngine* engine)
{
#ifdef WITH_RIVE_AUDIO
    if (engine == nullptr)
    {
        return 0;
    }
    return engine->timeInFrames();
#else
    return 0;
#endif
}

EXPORT void engineInitLevelMonitor(rive::AudioEngine* engine)
{
#ifdef WITH_RIVE_AUDIO
    if (engine == nullptr)
    {
        return;
    }
    engine->initLevelMonitor();
#endif
}

EXPORT float engineLevel(rive::AudioEngine* engine, uint32_t channel)
{
#ifdef WITH_RIVE_AUDIO
    if (engine == nullptr)
    {
        return 0.0f;
    }
    return engine->level(channel);
#else
    return 0.0f;
#endif
}

EXPORT uint32_t numChannels(rive::AudioEngine* engine)
{
#ifdef WITH_RIVE_AUDIO
    if (engine == nullptr)
    {
        return 0;
    }
    return engine->channels();
#else
    return 0;
#endif
}

EXPORT uint32_t sampleRate(rive::AudioEngine* engine)
{
#ifdef WITH_RIVE_AUDIO
    if (engine == nullptr)
    {
        return 0;
    }
    return engine->sampleRate();
#else
    return 0;
#endif
}

EXPORT uint32_t audioSourceNumChannels(rive::AudioSource* source)
{
#ifdef WITH_RIVE_AUDIO
    if (source == nullptr)
    {
        return 0;
    }
    return source->channels();
#else
    return 0;
#endif
}

EXPORT uint32_t audioSourceFormat(rive::AudioSource* source)
{
#ifdef WITH_RIVE_AUDIO
    if (source == nullptr)
    {
        return 0;
    }
    return (uint32_t)source->format();
#else
    return 0;
#endif
}

EXPORT uint32_t audioSourceSampleRate(rive::AudioSource* source)
{
    if (source == nullptr)
    {
        return 0;
    }
    return source->sampleRate();
}

EXPORT void unrefAudioEngine(rive::AudioEngine* engine)
{
#ifdef WITH_RIVE_AUDIO
    if (engine == nullptr)
    {
        return;
    }
    engine->unref();
#endif
}

EXPORT void unrefAudioSound(rive::AudioSound* sound)
{
#ifdef WITH_RIVE_AUDIO
    if (sound == nullptr)
    {
        return;
    }
    sound->unref();
#endif
}

EXPORT rive::SimpleArray<uint8_t>* makeAudioSourceBuffer(uint64_t byteSize)
{
    return new rive::SimpleArray<uint8_t>((size_t)byteSize);
}

EXPORT rive::AudioSource* makeAudioSource(
    rive::SimpleArray<uint8_t>* sourceBytes)
{
#ifdef WITH_RIVE_AUDIO
    if (sourceBytes == nullptr)
    {
        return nullptr;
    }

    return new rive::AudioSource(*sourceBytes);
#else
    return nullptr;
#endif
}

EXPORT rive::DecodeWork* makeAudioReader(rive::AudioSource* source,
                                         uint32_t channels,
                                         uint32_t sampleRate)
{
#ifdef WITH_RIVE_AUDIO
    if (source == nullptr)
    {
        return nullptr;
    }

    auto reader = source->makeReader(channels, sampleRate);
    if (reader == nullptr)
    {
        return nullptr;
    }
    return decodeWorker()->add(reader).release();
#else
    return nullptr;
#endif
}

struct SamplesSpan
{
    float* data;
    uint64_t count;
};
EXPORT SamplesSpan audioReaderRead(rive::DecodeWork* decodeWork)
{
#ifdef WITH_RIVE_AUDIO
    if (decodeWork == nullptr || !decodeWork->isDone())
    {
        return {nullptr, 0};
    }

    auto frames = decodeWork->frames();
    return {frames.data(), (uint64_t)frames.size()};
#else
    return {nullptr, 0};
#endif
}

EXPORT rive::AudioSource* makeBufferedAudioSource(rive::DecodeWork* decodeWork,
                                                  uint32_t channels,
                                                  uint32_t sampleRate)
{
#ifdef WITH_RIVE_AUDIO
    if (decodeWork == nullptr)
    {
        return nullptr;
    }
    return new rive::AudioSource(decodeWork->frames(), channels, sampleRate);
#else
    return nullptr;
#endif
}

EXPORT SamplesSpan bufferedAudioSamples(rive::AudioSource* audioSource)
{
    auto samples = audioSource->bufferedSamples();
    return {samples.data(), samples.size()};
}

EXPORT void unrefAudioSource(rive::AudioSource* audioSource)
{
#ifdef WITH_RIVE_AUDIO
    audioSource->unref();
#endif
}

EXPORT void unrefAudioReader(rive::DecodeWork* decodeWork)
{
#ifdef WITH_RIVE_AUDIO
    decodeWork->unref();
#endif
}

EXPORT void stopAudioSound(rive::AudioSound* sound, uint64_t fadeTimeInFrames)
{
#ifdef WITH_RIVE_AUDIO
    if (sound == nullptr)
    {
        return;
    }
    sound->stop(fadeTimeInFrames);
#endif
}

EXPORT float getSoundVolume(rive::AudioSound* sound)
{
#ifdef WITH_RIVE_AUDIO
    if (sound == nullptr)
    {
        return 0.0f;
    }
    return sound->volume();
#else
    return 0.0f;
#endif
}

EXPORT bool getSoundCompleted(rive::AudioSound* sound)
{
#ifdef WITH_RIVE_AUDIO
    if (sound == nullptr)
    {
        return true;
    }
    return sound->completed();
#else
    return 0.0f;
#endif
}

EXPORT void setSoundVolume(rive::AudioSound* sound, float volume)
{
#ifdef WITH_RIVE_AUDIO
    if (sound == nullptr)
    {
        return;
    }
    sound->volume(volume);
#endif
}

EXPORT rive::AudioSound* playAudioSource(rive::AudioSource* audioSource,
                                         rive::AudioEngine* engine,
                                         uint64_t engineStartTime,
                                         uint64_t engineEndTime,
                                         uint64_t soundStartTime)
{
#ifdef WITH_RIVE_AUDIO
    rive::rcp<rive::AudioSource> rcSource =
        rive::rcp<rive::AudioSource>(audioSource);
    rcSource->ref();
    return engine
        ->play(rcSource, engineStartTime, engineEndTime, soundStartTime)
        .release();
#else
    return nullptr;
#endif
}

EXPORT uint64_t audioReaderLength(rive::DecodeWork* decodeWork)
{
#ifdef WITH_RIVE_AUDIO
    if (decodeWork == nullptr)
    {
        return 0;
    }
    return decodeWork->lengthInFrames();
#else
    return 0;
#endif
}
#endif
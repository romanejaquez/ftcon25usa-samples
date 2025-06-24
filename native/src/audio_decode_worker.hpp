#ifndef _RIVE_AUDIO_DECODE_WORKER_HPP_
#define _RIVE_AUDIO_DECODE_WORKER_HPP_

#ifdef WITH_RIVE_AUDIO
#include "rive/audio/audio_reader.hpp"
#include <condition_variable>
#include <mutex>
#include <thread>
#include <deque>
#include <vector>
#include <cstdlib>

namespace rive
{
class AudioDecodeWorker;
class DecodeWork : public RefCnt<DecodeWork>
{
    friend class AudioDecodeWorker;

public:
    DecodeWork(rcp<AudioReader> audioReader) :
        m_audioReader(std::move(audioReader)),
        m_isDone(false),
        m_lengthInFrames(0)
    {}
    bool isDone() const { return m_isDone.load(); }

    AudioReader* audioReader() { return m_audioReader.get(); }
    Span<float> frames() { return m_frames; }
    uint64_t lengthInFrames() { return m_lengthInFrames; }

private:
    rcp<AudioReader> m_audioReader;
    std::atomic<bool> m_isDone;
    Span<float> m_frames;
    uint64_t m_lengthInFrames;
};

class AudioDecodeWorker
{
public:
    AudioDecodeWorker()
    {
        std::atexit(atExit);
        for (int i = 0; i < threadCount; i++)
        {
            m_workThreads.emplace_back(std::thread(staticWorkThread, this));
        }
    }

private:
    void workThread()
    {
        while (!sm_exiting)
        {
            std::unique_lock<std::mutex> lock(m_mutex);
            if (!m_work.empty())
            {
                rcp<DecodeWork> work = m_work.front();
                m_work.pop_front();
                lock.unlock();

                uint64_t length = work->m_audioReader->lengthInFrames();
                work->m_lengthInFrames = length;
                work->m_frames = work->m_audioReader->read(length);
                work->m_isDone.store(true);
            }
            else
            {
                m_haveWork.wait_for(lock, std::chrono::milliseconds(100));
            }
        }
    }

    static void staticWorkThread(void* w)
    {
        AudioDecodeWorker* worker = static_cast<AudioDecodeWorker*>(w);
        worker->workThread();
    }

public:
    rcp<DecodeWork> add(rcp<AudioReader> reader)
    {
        rcp<DecodeWork> work(new DecodeWork(reader));

        {
            std::unique_lock<std::mutex> lock(m_mutex);
            m_work.push_back(work);
        }
        m_haveWork.notify_all();
        return work;
    }

private:
    static const int threadCount = 6;
    std::vector<std::thread> m_workThreads;
    std::deque<rcp<DecodeWork>> m_work;
    std::condition_variable m_haveWork;
    std::mutex m_mutex;
    static bool sm_exiting;

private:
    static void atExit() { AudioDecodeWorker::sm_exiting = true; }
};
} // namespace rive
#else

namespace rive
{
class AudioDecodeWorker;
class DecodeWork;
} // namespace rive
#endif
#endif
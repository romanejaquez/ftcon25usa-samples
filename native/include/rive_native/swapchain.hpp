#ifndef _RIVE_SWAPCHAIN_HPP
#define _RIVE_SWAPCHAIN_HPP

#include <deque>
#include <mutex>
#include <condition_variable>

template <typename T> class Swapchain
{
public:
    template <typename... RenderTextures>
    Swapchain(T&& presentingTexture, RenderTextures&&... renderTextures) :
        m_presentingTexture(std::move(presentingTexture))
    {
        initRenderTextures(std::forward<RenderTextures>(renderTextures)...);
    }

    T acquireRenderTexture()
    {
        std::unique_lock lock(m_mutex);
        while (m_renderTextures.empty())
        {
            m_cond.wait(lock);
        }
        T ret = std::move(m_renderTextures.front());
        m_renderTextures.pop_front();
        return ret;
    }

    void presentTexture(T&& texture)
    {
        {
            std::lock_guard lock(m_mutex);
            m_renderTextures.push_back(std::move(m_presentingTexture));
            m_presentingTexture = std::move(texture);
        }
        m_cond.notify_all();
    }

    // Used to access the presentingTexture with a lock on the mutex.
    class PresentingTextureLock
    {
    public:
        PresentingTextureLock(Swapchain* thisPtr) : m_this(thisPtr)
        {
            m_this->m_mutex.lock();
        }
        const T& texture() { return m_this->m_presentingTexture; }
        ~PresentingTextureLock() { m_this->m_mutex.unlock(); }

    private:
        Swapchain* m_this;
    };

private:
    template <typename... RenderTextures>
    void initRenderTextures(T&& renderTexture,
                            RenderTextures&&... renderTextures)
    {
        m_renderTextures.push_back(std::move(renderTexture));
        initRenderTextures(std::forward<RenderTextures>(renderTextures)...);
    }

    void initRenderTextures(T&& renderTexture)
    {
        m_renderTextures.push_back(std::move(renderTexture));
    }

    std::mutex m_mutex;
    std::condition_variable m_cond;
    T m_presentingTexture;
    std::deque<T> m_renderTextures;
};

#endif

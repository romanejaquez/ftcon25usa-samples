#ifndef _RIVE_READ_WRITE_RING_HPP
#define _RIVE_READ_WRITE_RING_HPP
#include <cstdint>
#include <mutex>
class ReadWriteRing
{
public:
    static constexpr uint32_t ringSize = 3;

    ReadWriteRing();
    uint32_t nextWrite();
    uint32_t currentWrite();
    uint32_t nextRead();
    uint32_t currentRead();

private:
    std::mutex m_mutex;
    uint32_t m_size;
    uint32_t m_read;
    uint32_t m_write;
};

#endif
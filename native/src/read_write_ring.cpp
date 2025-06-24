#include "rive_native/read_write_ring.hpp"
#include <stdio.h>

ReadWriteRing::ReadWriteRing() : m_size(ringSize), m_read(0), m_write(0) {}

uint32_t ReadWriteRing::nextWrite()
{
    m_mutex.lock();
    m_write = (m_write + 1) % m_size;
    m_mutex.unlock();
    return m_write;
}
uint32_t ReadWriteRing::currentWrite()
{
    m_mutex.lock();
    uint32_t value = m_write;
    m_mutex.unlock();
    return value;
}
uint32_t ReadWriteRing::nextRead()
{
    m_mutex.lock();
    m_read = (m_read + 1) % m_size;
    m_mutex.unlock();
    return m_read;
}
uint32_t ReadWriteRing::currentRead()
{
    m_mutex.lock();
    uint32_t value = m_read;
    m_mutex.unlock();
    return value;
}

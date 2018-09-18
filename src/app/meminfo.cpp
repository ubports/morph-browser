/*
 * Copyright 2016 Canonical Ltd.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "meminfo.h"

// Qt
#include <QtCore/QByteArray>
#include <QtCore/QFile>
#include <QtCore/QRegExp>
#include <QtCore/QString>
#include <QtCore/QtGlobal>

MemInfo::MemInfo(QObject* parent)
    : QObject(parent)
    , m_total(0)
    , m_free(0)
{
    // Default interval: 5000 ms
    m_timer.setInterval(5000);
    connect(&m_timer, SIGNAL(timeout()), SLOT(update()));
    // Active by default
    m_timer.start();
}

MemInfo::~MemInfo()
{}

const bool MemInfo::active() const
{
    return m_timer.isActive();
}

void MemInfo::setActive(bool active)
{
    if (active != m_timer.isActive()) {
        if (active) {
            m_timer.start();
        } else {
            m_timer.stop();
        }
        Q_EMIT activeChanged();
    }
}

const int MemInfo::interval() const
{
    return m_timer.interval();
}

void MemInfo::setInterval(int interval)
{
    if (interval != m_timer.interval()) {
        m_timer.setInterval(interval);
        Q_EMIT intervalChanged();
    }
}

const int MemInfo::total() const
{
    return m_total;
}

const int MemInfo::free() const
{
    return m_free;
}

void MemInfo::update()
{
#if defined(Q_OS_LINUX)
    // Inspired by glibtop_get_mem_s()
    QFile meminfo(QStringLiteral("/proc/meminfo"));
    if (!meminfo.open(QIODevice::ReadOnly)) {
        return;
    }
    static QRegExp memTotalRegexp(QStringLiteral("MemTotal:\\s*(\\d+) kB\\n"));
    static QRegExp memFreeRegexp(QStringLiteral("MemFree:\\s*(\\d+) kB\\n"));
    static QRegExp buffersRegexp(QStringLiteral("Buffers:\\s*(\\d+) kB\\n"));
    static QRegExp cachedRegexp(QStringLiteral("Cached:\\s*(\\d+) kB\\n"));
    int parsedTotal = -1;
    int parsedFree = -1;
    int parsedBuffers = -1;
    int parsedCached = -1;
    while ((parsedTotal == -1) || (parsedFree == -1) ||
           (parsedBuffers == -1) || (parsedCached == -1)) {
        QByteArray line = meminfo.readLine();
        if (line.isEmpty()) {
            break;
        }
        if (memTotalRegexp.exactMatch(line)) {
            parsedTotal = memTotalRegexp.cap(1).toInt();
        } else if (memFreeRegexp.exactMatch(line)) {
            parsedFree = memFreeRegexp.cap(1).toInt();
        } else if (buffersRegexp.exactMatch(line)) {
            parsedBuffers = buffersRegexp.cap(1).toInt();
        } else if (cachedRegexp.exactMatch(line)) {
            parsedCached = cachedRegexp.cap(1).toInt();
        }
    }
    meminfo.close();
    if ((parsedTotal != -1) && (parsedFree != -1) &&
        (parsedBuffers != -1) && (parsedCached != -1)) {
        bool totalUpdated = false;
        if (parsedTotal != m_total) {
            m_total = parsedTotal;
            totalUpdated = true;
        }
        bool freeUpdated = false;
        int newFree = parsedFree + parsedCached + parsedBuffers;
        if (newFree != m_free) {
            m_free = newFree;
            freeUpdated = true;
        }
        if (totalUpdated) {
            Q_EMIT totalChanged();
        }
        if (freeUpdated) {
            Q_EMIT freeChanged();
        }
    }
#endif // Q_OS_LINUX
}

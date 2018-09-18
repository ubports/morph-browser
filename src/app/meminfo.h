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

#ifndef __MEMINFO_H__
#define __MEMINFO_H__

// Qt
#include <QtCore/QObject>
#include <QtCore/QTimer>

class MemInfo : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(int interval READ interval WRITE setInterval NOTIFY intervalChanged)

    // Expressed in kB
    Q_PROPERTY(int total READ total NOTIFY totalChanged)
    Q_PROPERTY(int free READ free NOTIFY freeChanged)

public:
    MemInfo(QObject* parent=nullptr);
    ~MemInfo();

    const bool active() const;
    void setActive(bool active);

    const int interval() const;
    void setInterval(int interval);

    const int total() const;
    const int free() const;

Q_SIGNALS:
    void activeChanged() const;
    void intervalChanged() const;
    void totalChanged() const;
    void freeChanged() const;

private Q_SLOTS:
    void update();

private:
    QTimer m_timer;
    int m_total;
    int m_free;
};

#endif // __MEMINFO_H__

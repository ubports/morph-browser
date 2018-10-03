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

#ifndef __SINGLE_INSTANCE_MANAGER_H__
#define __SINGLE_INSTANCE_MANAGER_H__

// Qt
#include <QtCore/QObject>
#include <QtNetwork/QLocalServer>

class QString;
class QStringList;

class SingleInstanceManager : public QObject
{
    Q_OBJECT

public:
    SingleInstanceManager(QObject* parent=nullptr);

    bool run(const QStringList& arguments, const QString& appId);

Q_SIGNALS:
    void newInstanceLaunched(const QStringList& arguments) const;

private Q_SLOTS:
    void onNewInstanceConnected();
    void onReadyRead();
    void onDisconnected();

private:
    QLocalServer m_server;
    bool listen(const QString& name);
};

#endif // __SINGLE_INSTANCE_MANAGER__

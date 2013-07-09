/*
 * Copyright 2013 Canonical Ltd.
 *
 * This file is part of webbrowser-app.
 *
 * webbrowser-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * webbrowser-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "history-hostlist-model.h"
#include "history-model.h"
#include "history-host-model.h"
#include "history-timeframe-model.h"

// Qt
#include <QtCore/QSet>
#include <QtCore/QStringList>

/*!
    \class HistoryHostListModel
    \brief List model that exposes history entries grouped by host

    HistoryHostListModel is a list model that exposes history entries from a
    HistoryTimeframeModel grouped by host. Each item in the list has two roles:
    'host' for the host name, and 'entries' for the corresponding
    HistoryHostModel that contains all entries in this group.
*/
HistoryHostListModel::HistoryHostListModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_sourceModel(0)
{
}

HistoryHostListModel::~HistoryHostListModel()
{
    clearHosts();
}

QHash<int, QByteArray> HistoryHostListModel::roleNames() const
{
    static QHash<int, QByteArray> roles;
    if (roles.isEmpty()) {
        roles[Host] = "host";
        roles[Entries] = "entries";
    }
    return roles;
}

int HistoryHostListModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_hosts.count();
}

QVariant HistoryHostListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    int row = index.row();
    if ((row < 0) || (row >= m_hosts.count())) {
        return QVariant();
    }
    const QString& host = m_hosts.keys().at(row);
    switch (role) {
    case Host:
        return host;
    case Entries:
        return QVariant::fromValue(m_hosts.value(host));
    default:
        return QVariant();
    }
}

HistoryTimeframeModel* HistoryHostListModel::sourceModel() const
{
    return m_sourceModel;
}

void HistoryHostListModel::setSourceModel(HistoryTimeframeModel* sourceModel)
{
    if (sourceModel != m_sourceModel) {
        beginResetModel();
        if (m_sourceModel != 0) {
            m_sourceModel->disconnect(this);
        }
        clearHosts();
        m_sourceModel = sourceModel;
        populateModel();
        if (m_sourceModel != 0) {
            connect(m_sourceModel, SIGNAL(rowsInserted(const QModelIndex&, int, int)),
                    SLOT(onRowsInserted(const QModelIndex&, int, int)));
            connect(m_sourceModel, SIGNAL(rowsRemoved(const QModelIndex&, int, int)),
                    SLOT(onRowsRemoved(const QModelIndex&, int, int)));
            connect(m_sourceModel, SIGNAL(modelReset()), SLOT(onModelReset()));
        }
        endResetModel();
        Q_EMIT sourceModelChanged();
    }
}

void HistoryHostListModel::clearHosts()
{
    Q_FOREACH(const QString& host, m_hosts.keys()) {
        delete m_hosts.take(host);
    }
}

void HistoryHostListModel::populateModel()
{
    if (m_sourceModel != 0) {
        int count = m_sourceModel->rowCount();
        for (int i = 0; i < count; ++i) {
            QString host = getHostFromSourceModel(m_sourceModel->index(i, 0));
            if (!m_hosts.contains(host)) {
                insertNewHost(host);
            }
        }
    }
}

void HistoryHostListModel::onRowsInserted(const QModelIndex& parent, int start, int end)
{
    for (int i = start; i <= end; ++i) {
        QString host = getHostFromSourceModel(m_sourceModel->index(i, 0, parent));
        if (!m_hosts.contains(host)) {
            QStringList hosts = m_hosts.keys();
            int insertAt = 0;
            while (insertAt < hosts.count()) {
                if (host.compare(hosts.at(insertAt)) < 0) {
                    break;
                }
                ++insertAt;
            }
            beginInsertRows(QModelIndex(), insertAt, insertAt);
            insertNewHost(host);
            endInsertRows();
        }
    }
}

void HistoryHostListModel::onRowsRemoved(const QModelIndex& parent, int start, int end)
{
    Q_UNUSED(parent);
    Q_UNUSED(start);
    Q_UNUSED(end);
    QSet<QString> newHosts;
    int count = m_sourceModel->rowCount();
    for (int i = 0; i < count; ++i) {
        newHosts.insert(getHostFromSourceModel(m_sourceModel->index(i, 0)));
    }
    QSet<QString> removed = QSet<QString>::fromList(m_hosts.keys());
    removed.subtract(newHosts);
    Q_FOREACH(const QString& host, removed) {
        int removeAt = m_hosts.keys().indexOf(host);
        beginRemoveRows(QModelIndex(), removeAt, removeAt);
        delete m_hosts.take(host);
        endRemoveRows();
    }
}

void HistoryHostListModel::onModelReset()
{
    beginResetModel();
    clearHosts();
    populateModel();
    endResetModel();
}

void HistoryHostListModel::insertNewHost(const QString& host)
{
    HistoryHostModel* model = new HistoryHostModel(this);
    model->setSourceModel(m_sourceModel);
    QString key = host.isNull() ? "" : host;
    model->setHost(key);
    m_hosts.insert(key, model);
}

QString HistoryHostListModel::getHostFromSourceModel(const QModelIndex& index) const
{
    return m_sourceModel->data(index, HistoryModel::Url).toUrl().host().toLower();
}

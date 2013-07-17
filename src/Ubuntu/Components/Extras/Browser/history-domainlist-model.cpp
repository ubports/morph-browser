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

#include "domain-utils.h"
#include "history-domain-model.h"
#include "history-domainlist-model.h"
#include "history-model.h"
#include "history-timeframe-model.h"
#include "webthumbnail-utils.h"

// Qt
#include <QtCore/QSet>
#include <QtCore/QStringList>

/*!
    \class HistoryDomainListModel
    \brief List model that exposes history entries grouped by domain name

    HistoryDomainListModel is a list model that exposes history entries from a
    HistoryTimeframeModel grouped by domain name. Each item in the list has
    three roles: 'domain' for the domain name, 'thumbnail' for a thumbnail
    picture of a page corresponding to this domain name, and 'entries' for the
    corresponding HistoryDomainModel that contains all entries in this group.
*/
HistoryDomainListModel::HistoryDomainListModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_sourceModel(0)
{
}

HistoryDomainListModel::~HistoryDomainListModel()
{
    clearDomains();
}

QHash<int, QByteArray> HistoryDomainListModel::roleNames() const
{
    static QHash<int, QByteArray> roles;
    if (roles.isEmpty()) {
        roles[Domain] = "domain";
        roles[Thumbnail] = "thumbnail";
        roles[Entries] = "entries";
    }
    return roles;
}

int HistoryDomainListModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_domains.count();
}

QVariant HistoryDomainListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    int row = index.row();
    if ((row < 0) || (row >= m_domains.count())) {
        return QVariant();
    }
    const QString& domain = m_domains.keys().at(row);
    switch (role) {
    case Domain:
        return domain;
    case Thumbnail:
    {
        // Iterate over all the entries, and return the first valid thumbnail.
        HistoryDomainModel* entries = m_domains.value(domain);
        int count = entries->rowCount();
        for (int i = 0; i < count; ++i) {
            QUrl url = entries->data(entries->index(i, 0), HistoryModel::Url).toUrl();
            QFileInfo thumbnailFile = WebThumbnailUtils::thumbnailFile(url);
            if (thumbnailFile.exists()) {
                return thumbnailFile.absoluteFilePath();
            }
        }
        return QUrl();
    }
    case Entries:
        return QVariant::fromValue(m_domains.value(domain));
    default:
        return QVariant();
    }
}

HistoryTimeframeModel* HistoryDomainListModel::sourceModel() const
{
    return m_sourceModel;
}

void HistoryDomainListModel::setSourceModel(HistoryTimeframeModel* sourceModel)
{
    if (sourceModel != m_sourceModel) {
        beginResetModel();
        if (m_sourceModel != 0) {
            m_sourceModel->disconnect(this);
        }
        clearDomains();
        m_sourceModel = sourceModel;
        populateModel();
        if (m_sourceModel != 0) {
            connect(m_sourceModel, SIGNAL(rowsInserted(const QModelIndex&, int, int)),
                    SLOT(onRowsInserted(const QModelIndex&, int, int)));
            connect(m_sourceModel, SIGNAL(rowsRemoved(const QModelIndex&, int, int)),
                    SLOT(onRowsRemoved(const QModelIndex&, int, int)));
            connect(m_sourceModel, SIGNAL(layoutChanged(const QList<QPersistentModelIndex>&, QAbstractItemModel::LayoutChangeHint)),
                    SLOT(onLayoutChanged(const QList<QPersistentModelIndex>&, QAbstractItemModel::LayoutChangeHint)));
            connect(m_sourceModel, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)),
                    SLOT(onDataChanged(QModelIndex,QModelIndex,QVector<int>)));
            connect(m_sourceModel, SIGNAL(modelReset()), SLOT(onModelReset()));
        }
        endResetModel();
        Q_EMIT sourceModelChanged();
    }
}

void HistoryDomainListModel::clearDomains()
{
    Q_FOREACH(const QString& domain, m_domains.keys()) {
        delete m_domains.take(domain);
    }
}

void HistoryDomainListModel::populateModel()
{
    if (m_sourceModel != 0) {
        int count = m_sourceModel->rowCount();
        for (int i = 0; i < count; ++i) {
            QString domain = getDomainFromSourceModel(m_sourceModel->index(i, 0));
            if (!m_domains.contains(domain)) {
                insertNewDomain(domain);
            }
        }
    }
}

void HistoryDomainListModel::onRowsInserted(const QModelIndex& parent, int start, int end)
{
    QStringList updated;
    for (int i = start; i <= end; ++i) {
        QString domain = getDomainFromSourceModel(m_sourceModel->index(i, 0, parent));
        if (!m_domains.contains(domain)) {
            QStringList domains = m_domains.keys();
            int insertAt = 0;
            while (insertAt < domains.count()) {
                if (domain.compare(domains.at(insertAt)) < 0) {
                    break;
                }
                ++insertAt;
            }
            beginInsertRows(QModelIndex(), insertAt, insertAt);
            insertNewDomain(domain);
            endInsertRows();
        } else {
            updated.append(domain);
        }
    }
    QVector<int> updatedRoles = QVector<int>() << Thumbnail << Entries;
    QStringList domains = m_domains.keys();
    Q_FOREACH(const QString& domain, updated) {
        QModelIndex index = this->index(domains.indexOf(domain), 0);
        Q_EMIT dataChanged(index, index, updatedRoles);
    }
}

void HistoryDomainListModel::onRowsRemoved(const QModelIndex& parent, int start, int end)
{
    Q_UNUSED(parent);
    Q_UNUSED(start);
    Q_UNUSED(end);
    QSet<QString> newDomains;
    int count = m_sourceModel->rowCount();
    for (int i = 0; i < count; ++i) {
        newDomains.insert(getDomainFromSourceModel(m_sourceModel->index(i, 0)));
    }
    QSet<QString> removed = QSet<QString>::fromList(m_domains.keys());
    removed.subtract(newDomains);
    Q_FOREACH(const QString& domain, removed) {
        int removeAt = m_domains.keys().indexOf(domain);
        beginRemoveRows(QModelIndex(), removeAt, removeAt);
        delete m_domains.take(domain);
        endRemoveRows();
    }
    // XXX: unfortunately there is no way to get a list of domains that had some
    // (but not all) entries removed. To ensure the views are correctly updated,
    // let’s emit the signal for all entries, even those that haven’t changed.
    Q_EMIT dataChanged(this->index(0, 0), this->index(rowCount() - 1, 0),
                       QVector<int>() << Thumbnail << Entries);
}

void HistoryDomainListModel::onLayoutChanged(const QList<QPersistentModelIndex>& parents, QAbstractItemModel::LayoutChangeHint hint)
{
    Q_UNUSED(parents);
    Q_UNUSED(hint);
    Q_EMIT dataChanged(this->index(0, 0), this->index(rowCount() - 1, 0),
                       QVector<int>() << Thumbnail << Entries);
}

void HistoryDomainListModel::onDataChanged(const QModelIndex& topLeft, const QModelIndex& bottomRight, const QVector<int>& roles)
{
    Q_UNUSED(roles);
    int start = topLeft.row();
    int end = bottomRight.row();
    QSet<QString> changed;
    for (int i = start; i <= end; ++i) {
        changed.insert(getDomainFromSourceModel(m_sourceModel->index(i, 0)));
    }
    Q_FOREACH(const QString& domain, changed) {
        QModelIndex index = this->index(m_domains.keys().indexOf(domain), 0);
        Q_EMIT dataChanged(index, index, QVector<int>() << Thumbnail << Entries);
    }
}

void HistoryDomainListModel::onModelReset()
{
    beginResetModel();
    clearDomains();
    populateModel();
    endResetModel();
}

void HistoryDomainListModel::insertNewDomain(const QString& domain)
{
    HistoryDomainModel* model = new HistoryDomainModel(this);
    model->setSourceModel(m_sourceModel);
    model->setDomain(domain);
    m_domains.insert(domain, model);
}

QString HistoryDomainListModel::getDomainFromSourceModel(const QModelIndex& index) const
{
    QUrl url = m_sourceModel->data(index, HistoryModel::Url).toUrl();
    return DomainUtils::extractTopLevelDomainName(url).toLower();
}

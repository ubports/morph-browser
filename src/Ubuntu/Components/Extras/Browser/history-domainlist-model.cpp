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
        roles[LastVisit] = "lastVisit";
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
    const QString domain = m_domains.keys().at(index.row());
    HistoryDomainModel* entries = m_domains.value(domain);

    switch (role) {
    case Domain:
        return domain;
    case LastVisit:
    {
        // At this point, entries might not have been filtered yet,
        // so the first entry is not guaranteed to be the one we want.
        int count = entries->rowCount();
        for (int i = 0; i < count; ++i) {
            if (entries->sourceEntryMatchesDomain(i, QModelIndex())) {
                return entries->data(entries->index(i, 0), HistoryModel::LastVisit).toDateTime();
            }
        }
        return QDateTime();
    }
    case Thumbnail:
        return entries->thumbnail();
    case Entries:
        return QVariant::fromValue(entries);
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
            connect(m_sourceModel, SIGNAL(modelReset()), SLOT(onModelReset()));
            connect(m_sourceModel, SIGNAL(layoutChanged(QList<QPersistentModelIndex>, QAbstractItemModel::LayoutChangeHint)),
                    SLOT(onModelReset()));
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
        }
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
    connect(model, SIGNAL(rowsInserted(QModelIndex, int, int)),
            SLOT(onDomainRowsInserted(QModelIndex, int, int)));
    connect(model, SIGNAL(rowsRemoved(QModelIndex, int, int)),
            SLOT(onDomainRowsRemoved(QModelIndex, int, int)));
    connect(model, SIGNAL(rowsMoved(QModelIndex, int, int, QModelIndex, int)),
            SLOT(onDomainRowsMoved(QModelIndex, int, int, QModelIndex, int)));
    connect(model, SIGNAL(layoutChanged(QList<QPersistentModelIndex>, QAbstractItemModel::LayoutChangeHint)),
            SLOT(onDomainLayoutChanged(QList<QPersistentModelIndex>, QAbstractItemModel::LayoutChangeHint)));
    connect(model, SIGNAL(dataChanged(QModelIndex, QModelIndex)),
            SLOT(onDomainDataChanged(QModelIndex, QModelIndex)));
    connect(model, SIGNAL(modelReset()), SLOT(onDomainModelReset()));
    connect(model, SIGNAL(thumbnailChanged()), SLOT(onDomainThumbnailChanged()));
    m_domains.insert(domain, model);
}

QString HistoryDomainListModel::getDomainFromSourceModel(const QModelIndex& index) const
{
    QUrl url = m_sourceModel->data(index, HistoryModel::Url).toUrl();
    return DomainUtils::extractTopLevelDomainName(url).toLower();
}

void HistoryDomainListModel::onDomainRowsInserted(const QModelIndex& parent, int start, int end)
{
    Q_UNUSED(parent);
    Q_UNUSED(start);
    Q_UNUSED(end);
    HistoryDomainModel* model = qobject_cast<HistoryDomainModel*>(sender());
    if (model != 0) {
        emitDataChanged(model->domain());
    }
}

void HistoryDomainListModel::onDomainRowsRemoved(const QModelIndex& parent, int start, int end)
{
    Q_UNUSED(parent);
    Q_UNUSED(start);
    Q_UNUSED(end);
    HistoryDomainModel* model = qobject_cast<HistoryDomainModel*>(sender());
    if (model != 0) {
        const QString& domain = model->domain();
        if (model->rowCount() == 0) {
            int removeAt = m_domains.keys().indexOf(domain);
            beginRemoveRows(QModelIndex(), removeAt, removeAt);
            delete m_domains.take(domain);
            endRemoveRows();
        } else {
            emitDataChanged(domain);
        }
    }
}

void HistoryDomainListModel::onDomainRowsMoved(const QModelIndex& sourceParent, int sourceStart, int sourceEnd, const QModelIndex& destinationParent, int destinationRow)
{
    HistoryDomainModel* model = qobject_cast<HistoryDomainModel*>(sender());
    if (model != 0) {
        emitDataChanged(model->domain());
    }
}

void HistoryDomainListModel::onDomainLayoutChanged(const QList<QPersistentModelIndex>& parents, QAbstractItemModel::LayoutChangeHint hint)
{
    Q_UNUSED(parents);
    Q_UNUSED(hint);
    HistoryDomainModel* model = qobject_cast<HistoryDomainModel*>(sender());
    if (model != 0) {
        emitDataChanged(model->domain());
    }
}

void HistoryDomainListModel::onDomainDataChanged(const QModelIndex& topLeft, const QModelIndex& bottomRight)
{
    Q_UNUSED(topLeft);
    Q_UNUSED(bottomRight);
    HistoryDomainModel* model = qobject_cast<HistoryDomainModel*>(sender());
    if (model != 0) {
        emitDataChanged(model->domain());
    }
}

void HistoryDomainListModel::onDomainModelReset()
{
    HistoryDomainModel* model = qobject_cast<HistoryDomainModel*>(sender());
    if (model != 0) {
        emitDataChanged(model->domain());
    }
}

void HistoryDomainListModel::onDomainThumbnailChanged()
{
    HistoryDomainModel* model = qobject_cast<HistoryDomainModel*>(sender());
    if (model != 0) {
        emitDataChanged(model->domain());
    }
}

void HistoryDomainListModel::emitDataChanged(const QString& domain)
{
    int i = m_domains.keys().indexOf(domain);
    if (i != -1) {
        QModelIndex index = this->index(i, 0);
        Q_EMIT dataChanged(index, index, QVector<int>() << LastVisit << Thumbnail << Entries);
    }
}

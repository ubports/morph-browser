/*
 * Copyright 2015 Canonical Ltd.
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

#include "history-lastvisitdate-model.h"
#include "history-lastvisitdatelist-model.h"
#include "history-model.h"
#include "history-timeframe-model.h"

// Qt
#include <QtCore/QStringList>

/*!
    \class HistoryLastVisitDateListModel
    \brief List model that exposes history entries grouped by last visit date

    HistoryLastVisitiDateListModel is a list model that exposes history entries
    from a HistoryTimeframeModel grouped by last visit date. Each item in the
    list has two roles: 'lastVisitDate' for the date of the last visit of
    entries, and 'entries' for the corresponding HistoryLastVisitDateModel that
    contains all entries in this group.
*/
HistoryLastVisitDateListModel::HistoryLastVisitDateListModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_sourceModel(0)
{
}

HistoryLastVisitDateListModel::~HistoryLastVisitDateListModel()
{
    clearLastVisitDates();
}

QHash<int, QByteArray> HistoryLastVisitDateListModel::roleNames() const
{
    static QHash<int, QByteArray> roles;
    if (roles.isEmpty()) {
        roles[LastVisitDate] = "lastVisitDate";
        roles[Entries] = "entries";
    }
    return roles;
}

int HistoryLastVisitDateListModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_lastVisitDates.count();
}

QVariant HistoryLastVisitDateListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    const QDate lastVisitDate = m_orderedDates.at(index.row());
    HistoryLastVisitDateModel* entries = m_lastVisitDates.value(lastVisitDate);

    switch (role) {
    case LastVisitDate:
        return lastVisitDate;
    case Entries:
        return QVariant::fromValue(entries);
    default:
        return QVariant();
    }
}

HistoryTimeframeModel* HistoryLastVisitDateListModel::sourceModel() const
{
    return m_sourceModel;
}

void HistoryLastVisitDateListModel::setSourceModel(HistoryTimeframeModel* sourceModel)
{
    if (sourceModel != m_sourceModel) {
        beginResetModel();
        if (m_sourceModel != 0) {
            m_sourceModel->disconnect(this);
        }
        clearLastVisitDates();
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

void HistoryLastVisitDateListModel::clearLastVisitDates()
{
    m_orderedDates.clear();
    Q_FOREACH(const QDate& lastVisitDate, m_lastVisitDates.keys()) {
        delete m_lastVisitDates.take(lastVisitDate);
    }
}

void HistoryLastVisitDateListModel::populateModel()
{
    if (m_sourceModel != 0) {
        int count = m_sourceModel->rowCount();
        for (int i = 0; i < count; ++i) {
            QDate lastVisitDate = getLastVisitDateFromSourceModel(m_sourceModel->index(i, 0));
            if (!m_lastVisitDates.contains(lastVisitDate)) {
                insertNewLastVisitDate(lastVisitDate);
            }
        }
    }
}

void HistoryLastVisitDateListModel::onRowsInserted(const QModelIndex& parent, int start, int end)
{
    for (int i = start; i <= end; ++i) {
        QDate lastVisitDate = getLastVisitDateFromSourceModel(m_sourceModel->index(i, 0, parent));
        if (!m_lastVisitDates.contains(lastVisitDate)) {
            int insertAt = 0;
            while (insertAt < m_orderedDates.count()) {
                if (lastVisitDate > m_orderedDates.at(insertAt)) {
                    break;
                }
                ++insertAt;
            }
            beginInsertRows(QModelIndex(), insertAt, insertAt);
            insertNewLastVisitDate(lastVisitDate);
            endInsertRows();
        }
    }
}

void HistoryLastVisitDateListModel::onModelReset()
{
    beginResetModel();
    clearLastVisitDates();
    populateModel();
    endResetModel();
}

void HistoryLastVisitDateListModel::insertNewLastVisitDate(const QDate& lastVisitDate)
{
    HistoryLastVisitDateModel* model = new HistoryLastVisitDateModel(this);
    model->setSourceModel(m_sourceModel);
    model->setLastVisitDate(lastVisitDate);
    connect(model, SIGNAL(rowsInserted(QModelIndex, int, int)), SLOT(onLastVisitDateDataChanged()));
    connect(model, SIGNAL(rowsRemoved(QModelIndex, int, int)), SLOT(onLastVisitDateRowsRemoved(QModelIndex, int, int)));
    connect(model, SIGNAL(rowsMoved(QModelIndex, int, int, QModelIndex, int)), SLOT(onLastVisitDateDataChanged()));
    connect(model, SIGNAL(layoutChanged(QList<QPersistentModelIndex>, QAbstractItemModel::LayoutChangeHint)),
            SLOT(onLastVisitDateDataChanged()));
    connect(model, SIGNAL(dataChanged(QModelIndex, QModelIndex)), SLOT(onLastVisitDateDataChanged()));
    connect(model, SIGNAL(modelReset()), SLOT(onLastVisitDateDataChanged()));
    connect(model, SIGNAL(lastVisitDateChanged()), SLOT(onLastVisitDateDataChanged()));
    int insertAt = 0;
    while (insertAt < m_orderedDates.count()) {
        if (lastVisitDate > m_orderedDates.at(insertAt)) {
            break;
        }
        ++insertAt;
    }
    m_orderedDates.insert(insertAt, lastVisitDate);
    m_lastVisitDates.insert(lastVisitDate, model);
}

QDate HistoryLastVisitDateListModel::getLastVisitDateFromSourceModel(const QModelIndex& index) const
{
    return m_sourceModel->data(index, HistoryModel::LastVisitDate).toDate();
}

void HistoryLastVisitDateListModel::onLastVisitDateRowsRemoved(const QModelIndex& parent, int start, int end)
{
    Q_UNUSED(parent);
    Q_UNUSED(start);
    Q_UNUSED(end);
    HistoryLastVisitDateModel* model = qobject_cast<HistoryLastVisitDateModel*>(sender());
    if (model != 0) {
        const QDate& lastVisitDate = model->lastVisitDate();
        if (model->rowCount() == 0) {
            int removeAt = m_orderedDates.indexOf(lastVisitDate);
            beginRemoveRows(QModelIndex(), removeAt, removeAt);
            delete m_lastVisitDates.take(lastVisitDate);
            endRemoveRows();
        } else {
            emitDataChanged(lastVisitDate);
        }
    }
}

void HistoryLastVisitDateListModel::onLastVisitDateDataChanged()
{
    HistoryLastVisitDateModel* model = qobject_cast<HistoryLastVisitDateModel*>(sender());
    if (model != 0) {
        emitDataChanged(model->lastVisitDate());
    }
}

void HistoryLastVisitDateListModel::emitDataChanged(const QDate& lastVisitDate)
{
    int i = m_orderedDates.indexOf(lastVisitDate);
    if (i != -1) {
        QModelIndex index = this->index(i, 0);
        Q_EMIT dataChanged(index, index, QVector<int>() << Entries);
    }
}

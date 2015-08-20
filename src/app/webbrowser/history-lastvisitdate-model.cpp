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
#include "history-model.h"
#include "history-timeframe-model.h"

// Qt
#include <QtCore/QDebug>
#include <QtCore/QUrl>

/*!
    \class HistoryLastVisitDateModel
    \brief Proxy model that filters the contents of a model based on last
           visit date

    HistoryLastVisitDateModel is a proxy model that filters the contents
    of any QAbstractItemModel-derived model based on a role called
    "lastVisitDate".

    An entry in the history model matches if the last visit date equals
    the filter visit date.

    When no visit date is set, all entries match. If the model does not have
    the "lastVisitDate" role, then no entries are returned if a filter visit
    date is set, otherwise all entries match.
*/
HistoryLastVisitDateModel::HistoryLastVisitDateModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
}

QVariant HistoryLastVisitDateModel::sourceModel() const
{
    QAbstractItemModel* model = QSortFilterProxyModel::sourceModel();
    return (model) ? QVariant::fromValue(model) : QVariant();
}

void HistoryLastVisitDateModel::setSourceModel(QVariant sourceModel)
{
    QAbstractItemModel* newSourceModel = qvariant_cast<QAbstractItemModel*>(sourceModel);
    if (sourceModel.isValid() && newSourceModel == 0) {
        qWarning() << "Only QAbstractItemModel-derived instances are allowed as"
                   << "source models";
    }

    if (newSourceModel != QSortFilterProxyModel::sourceModel()) {
        beginResetModel();

        QAbstractItemModel* currentModel = QSortFilterProxyModel::sourceModel();
        if (currentModel != 0) {
            currentModel->disconnect(this);
        }
        QSortFilterProxyModel::setSourceModel(newSourceModel);
        updateSourceModelRole();

        if (newSourceModel != 0) {
            connect(newSourceModel, SIGNAL(modelReset()), SLOT(updateSourceModelRole()));
            connect(newSourceModel, SIGNAL(layoutChanged(QList<QPersistentModelIndex>, QAbstractItemModel::LayoutChangeHint)),
                    SLOT(updateSourceModelRole()));
        }

        endResetModel();
        Q_EMIT sourceModelChanged();
    }
}

const QDate& HistoryLastVisitDateModel::lastVisitDate() const
{
    return m_lastVisitDate;
}

void HistoryLastVisitDateModel::setLastVisitDate(const QDate& lastVisitDate)
{
    if (lastVisitDate != m_lastVisitDate) {
        m_lastVisitDate = lastVisitDate;
        invalidate();
        Q_EMIT lastVisitDateChanged();
    }
}

QVariantMap HistoryLastVisitDateModel::get(int i) const
{
    QVariantMap item;
    QHash<int, QByteArray> roles = roleNames();

    QModelIndex modelIndex = index(i, 0);
    if (modelIndex.isValid()) {
        Q_FOREACH(int role, roles.keys()) {
            QString roleName = QString::fromUtf8(roles.value(role));
            item.insert(roleName, data(modelIndex, role));
        }
    }
    return item;
}

bool HistoryLastVisitDateModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    if (m_lastVisitDate.isNull()) {
        return true;
    }

    if (m_sourceModelRole == -1) {
        return false;
    }

    QAbstractItemModel* model = QSortFilterProxyModel::sourceModel();
    if (model) {
        QModelIndex index = model->index(source_row, 0, source_parent);
        return m_lastVisitDate == model->data(index, m_sourceModelRole).toDate();
    } else {
        return false;
    }
}

void HistoryLastVisitDateModel::updateSourceModelRole()
{
    QAbstractItemModel* sourceModel = QSortFilterProxyModel::sourceModel();
    if (sourceModel && sourceModel->roleNames().count() > 0) {
        m_sourceModelRole = sourceModel->roleNames().key("lastVisitDate", -1);
        if (m_sourceModelRole == -1) {
            qWarning() << "No results will be returned because the sourceModel"
                       << "does not have a role named \"lastVisitDate\"";
        }
    }
}

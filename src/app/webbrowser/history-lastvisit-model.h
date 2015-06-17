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

#ifndef __HISTORY_LASTVISIT_MODEL_H__
#define __HISTORY_LASTVISIT_MODEL_H__

// Qt
#include <QtCore/QDateTime>
#include <QtCore/QSortFilterProxyModel>
#include <QtCore/QString>
#include <QtCore/QUrl>

class HistoryTimeframeModel;

class HistoryLastVisitModel : public QSortFilterProxyModel
{
    Q_OBJECT

    Q_PROPERTY(HistoryTimeframeModel* sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)
    Q_PROPERTY(QDateTime lastVisit READ lastVisit WRITE setLastVisit NOTIFY lastVisitChanged)

public:
    HistoryLastVisitModel(QObject* parent=0);

    HistoryTimeframeModel* sourceModel() const;
    void setSourceModel(HistoryTimeframeModel* sourceModel);

    const QDateTime& lastVisit() const;
    void setLastVisit(const QDateTime& lastVisit);

Q_SIGNALS:
    void sourceModelChanged() const;
    void lastVisitChanged() const;

protected:
    // reimplemented from QSortFilterProxyModel
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const;

private:
    QDateTime m_lastVisit;
};

#endif // __HISTORY_LASTVISIT_MODEL_H__

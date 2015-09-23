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

#ifndef __HISTORY_TIMEFRAME_MODEL_H__
#define __HISTORY_TIMEFRAME_MODEL_H__

// Qt
#include <QtCore/QDateTime>
#include <QtCore/QSortFilterProxyModel>

class HistoryModel;

class HistoryTimeframeModel : public QSortFilterProxyModel
{
    Q_OBJECT

    Q_PROPERTY(HistoryModel* sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)
    Q_PROPERTY(QDateTime start READ start WRITE setStart NOTIFY startChanged)
    Q_PROPERTY(QDateTime end READ end WRITE setEnd NOTIFY endChanged)

public:
    HistoryTimeframeModel(QObject* parent=0);

    HistoryModel* sourceModel() const;
    void setSourceModel(HistoryModel* sourceModel);

    const QDateTime& start() const;
    void setStart(const QDateTime& start);

    const QDateTime& end() const;
    void setEnd(const QDateTime& end);

Q_SIGNALS:
    void sourceModelChanged() const;
    void startChanged() const;
    void endChanged() const;

protected:
    // reimplemented from QSortFilterProxyModel
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const;
    QHash<int, QByteArray> roleNames() const;

private:
    QDateTime m_start;
    QDateTime m_end;
};

#endif // __HISTORY_TIMEFRAME_MODEL_H__

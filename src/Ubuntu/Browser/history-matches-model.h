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

#ifndef __HISTORY_MATCHES_MODEL_H__
#define __HISTORY_MATCHES_MODEL_H__

// Qt
#include <QtCore/QSortFilterProxyModel>
#include <QtCore/QString>
#include <QtCore/QStringList>

class HistoryModel;

class HistoryMatchesModel : public QSortFilterProxyModel
{
    Q_OBJECT

    Q_PROPERTY(HistoryModel* sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)
    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged)
    Q_PROPERTY(QStringList terms READ terms NOTIFY termsChanged)

public:
    HistoryMatchesModel(QObject* parent=0);

    HistoryModel* sourceModel() const;
    void setSourceModel(HistoryModel* sourceModel);

    const QString& query() const;
    void setQuery(const QString& query);

    const QStringList& terms() const;

Q_SIGNALS:
    void sourceModelChanged() const;
    void queryChanged() const;
    void termsChanged() const;

protected:
    // reimplemented from QSortFilterProxyModel
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const;

private:
    QString m_query;
    QStringList m_terms;
};

#endif // __HISTORY_MATCHES_MODEL_H__

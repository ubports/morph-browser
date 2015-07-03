/*
 * Copyright 2013-2015 Canonical Ltd.
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

#ifndef __HISTORY_DOMAINLIST_CHRONOLOGICAL_MODEL_H__
#define __HISTORY_DOMAINLIST_CHRONOLOGICAL_MODEL_H__

// Qt
#include <QtCore/QSortFilterProxyModel>
#include <QtCore/QString>

class HistoryDomainListModel;

class HistoryDomainListChronologicalModel : public QSortFilterProxyModel
{
    Q_OBJECT

    Q_PROPERTY(HistoryDomainListModel* sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)

public:
    HistoryDomainListChronologicalModel(QObject* parent=0);

    HistoryDomainListModel* sourceModel() const;
    void setSourceModel(HistoryDomainListModel* sourceModel);

    Q_INVOKABLE QString get(int index) const;

Q_SIGNALS:
    void sourceModelChanged() const;
};

#endif // __HISTORY_DOMAINLIST_CHRONOLOGICAL_MODEL_H__

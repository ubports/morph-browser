/*
 * Copyright 2019 Chris Clime
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

#ifndef DOMAINSETTINGS_SORTED_MODEL_H
#define DOMAINSETTINGS_SORTED_MODEL_H

#include <QSortFilterProxyModel>

class DomainSettingsSortedModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QAbstractItemModel* model READ sourceModel WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(Qt::SortOrder sortOrder READ sortOrder WRITE setSortOrder NOTIFY sortOrderChanged)

public:
     explicit DomainSettingsSortedModel(QObject *parent = nullptr);
     void setModel(QAbstractItemModel *model);
     int count();
     void setSortOrder(Qt::SortOrder  order);

Q_SIGNALS:
    void countChanged();
    void modelChanged();
    void sortOrderChanged();

protected:
     bool lessThan(const QModelIndex &left, const QModelIndex &right) const;

};

#endif

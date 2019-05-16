/*
 * Copyright 2019 ubports
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

#include "domain-settings-sorted-model.h"

DomainSettingsSortedModel::DomainSettingsSortedModel(QObject *parent):
                   QSortFilterProxyModel(parent)
{
}

/*!
 * \qmlproperty QAbstractItemModel SortFilterModel::model
 *
 * The source model to sort and/ or filter.
 */
void DomainSettingsSortedModel::setModel(QAbstractItemModel *itemModel)
{
    if (itemModel == nullptr) {
        return;
    }

    if (itemModel != sourceModel()) {
        if (sourceModel() != nullptr) {
            sourceModel()->disconnect(this);
        }

        setSourceModel(itemModel);

        Q_EMIT modelChanged();
    }
}

void DomainSettingsSortedModel::setSortOrder( Qt::SortOrder order ) {
    bool orderChanged = this->sortOrder() != order;
    this->sort(this->sortRole(),order);
    if( orderChanged ) {
        Q_EMIT sortOrderChanged();
    }
}

int DomainSettingsSortedModel::count()
{
    return rowCount();
}

bool DomainSettingsSortedModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    QObject* leftData = left.data(Qt::InitialSortOrderRole).value<QObject*>();
    QObject* rightData = right.data(Qt::InitialSortOrderRole).value<QObject*>();

    QString leftDomain = leftData->property("domain").toString();
    QString leftDomainWithoutSubdomain = leftData->property("domainWithoutSubdomain").toString();
    QString rightDomain = rightData->property("domain").toString();
    QString rightDomainWithoutSubdomain = rightData->property("domainWithoutSubdomain").toString();

    // same domain -> different subdomains
    if (leftDomainWithoutSubdomain == rightDomainWithoutSubdomain)
    {
        return (leftDomain.localeAwareCompare(rightDomain) < 0);
    }

    // sort by domainWithoutSubdomain
    return (leftDomainWithoutSubdomain.localeAwareCompare(rightDomainWithoutSubdomain) < 0);
}

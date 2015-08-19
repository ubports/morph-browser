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

#include "text-search-filter-model.h"

#include <QtCore/QDebug>
#include <QtCore/QSet>

/*!
    \class TextSearchFilterModel
    \brief Proxy model that filters the contents of a model based on a list of
           keywords applied to multiple fields.

    TextSearchFilterModel is a proxy model that filters the contents of a
    model based on a list of terms string that is applied to multiple user
    defined fields (matching role names in the source model).

    An item in the source model is returned by this model if all the search
    terms are contained in any of the item's fields (i.e. given two search
    terms, if one is found in a field and the other in a different field, then
    the item will be returned, but it will not be returned if only one is found)
*/
TextSearchFilterModel::TextSearchFilterModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
}

QVariant TextSearchFilterModel::sourceModel() const
{
    QAbstractItemModel* source = QSortFilterProxyModel::sourceModel();
    return (source) ? QVariant::fromValue(source) : QVariant();
}

void TextSearchFilterModel::setSourceModel(QVariant sourceModel)
{
    QAbstractItemModel* currentSource = QSortFilterProxyModel::sourceModel();
    QAbstractItemModel* newSource = qvariant_cast<QAbstractItemModel*>(sourceModel);
    if (newSource != currentSource) {
        updateSearchRoles(newSource);
        QSortFilterProxyModel::setSourceModel(newSource);
        Q_EMIT sourceModelChanged();
        Q_EMIT countChanged();
    }
}

void TextSearchFilterModel::setTerms(const QStringList& terms)
{
    if (terms != m_terms) {
        m_terms = terms;
        invalidateFilter();
        Q_EMIT termsChanged();
        Q_EMIT countChanged();
    }
}

const QStringList& TextSearchFilterModel::terms() const
{
    return m_terms;
}

void TextSearchFilterModel::setSearchFields(const QStringList& searchFields)
{
    if (searchFields != m_searchFields) {
        m_searchFields = searchFields;
        updateSearchRoles(QSortFilterProxyModel::sourceModel());
        invalidateFilter();
        Q_EMIT searchFieldsChanged();
        Q_EMIT countChanged();
    }
}

const QStringList& TextSearchFilterModel::searchFields() const
{
    return m_searchFields;
}

void TextSearchFilterModel::updateSearchRoles(const QAbstractItemModel* model) {
    m_searchRoles.clear();
    if (model) {
        Q_FOREACH(const QString& field, m_searchFields) {
            int role = model->roleNames().key(field.toUtf8(), -1);
            if (role != -1) {
                m_searchRoles.append(role);
            } else {
                qWarning() << "Source model does not have role matching field:" << field;
            }
        }
    }
}

bool TextSearchFilterModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    if (m_terms.isEmpty() || m_searchFields.isEmpty()) {
        return false;
    }

    QAbstractItemModel* source = QSortFilterProxyModel::sourceModel();
    QModelIndex index = source->index(source_row, 0, source_parent);

    QSet<QString> foundTerms;
    int searchTermsCount = QSet<QString>::fromList(m_terms).count();

    Q_FOREACH(int role, m_searchRoles) {
        QString value = source->data(index, role).toString();
        Q_FOREACH (const QString& term, m_terms) {
            if (value.contains(term, Qt::CaseInsensitive)) {
                foundTerms.insert(term);
            }
            if (foundTerms.count() == searchTermsCount) {
                return true;
            }
        }
    }
    return false;
}

int TextSearchFilterModel::count() const
{
    return rowCount();
}

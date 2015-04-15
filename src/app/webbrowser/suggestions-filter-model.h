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

#ifndef SUGGESTIONSFILTERMODEL_H
#define SUGGESTIONSFILTERMODEL_H

// Qt
#include <QtCore/QAbstractItemModel>
#include <QtCore/QList>
#include <QtCore/QSortFilterProxyModel>
#include <QtCore/QString>
#include <QtCore/QStringList>
#include <QtCore/QVariant>

class SuggestionsFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT

    Q_PROPERTY(QVariant sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)
    Q_PROPERTY(QStringList terms READ terms WRITE setTerms NOTIFY termsChanged)
    Q_PROPERTY(QStringList searchFields READ searchFields WRITE setSearchFields NOTIFY searchFieldsChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    SuggestionsFilterModel(QObject* parent=0);

    QVariant sourceModel() const;
    void setSourceModel(QVariant sourceModel);

    int count() const;
    Q_INVOKABLE QVariantMap get(int index) const;

    const QStringList& terms() const;
    void setTerms(const QStringList&);

    const QStringList& searchFields() const;
    void setSearchFields(const QStringList&);

Q_SIGNALS:
    void sourceModelChanged() const;
    void termsChanged() const;
    void searchFieldsChanged() const;
    void countChanged() const;

protected:
    // reimplemented from QSortFilterProxyModel
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const;
    void updateSearchRoles(const QAbstractItemModel* model);

private:
    QStringList m_terms;
    QStringList m_searchFields;
    QList<int> m_searchRoles;
};


#endif // SUGGESTIONSFILTERMODEL_H

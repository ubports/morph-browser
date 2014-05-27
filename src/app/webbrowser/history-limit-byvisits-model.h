/*
 * Copyright 2014 Canonical Ltd.
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

#ifndef __HISTORY_LIMIT_BYVISITS_MODEL_H__
#define __HISTORY_LIMIT_BYVISITS_MODEL_H__

// Qt
#include <QtCore/QIdentityProxyModel>

class HistoryByVisitsModel;

class HistoryLimitByVisitsModel : public QIdentityProxyModel
{
    Q_OBJECT

    Q_PROPERTY(HistoryByVisitsModel* sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)
    Q_PROPERTY(int limit READ limit WRITE setLimit NOTIFY limitChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    HistoryLimitByVisitsModel(QObject* parent=0);

    HistoryByVisitsModel* sourceModel() const;
    void setSourceModel(HistoryByVisitsModel* sourceModel);

    int limit() const;
    void setLimit(int limit);

    int rowCount(const QModelIndex &parent = QModelIndex()) const;

Q_SIGNALS:
    void sourceModelChanged() const;
    void limitChanged() const;
    void totalCountChanged();
    void countChanged();

private Q_SLOTS:
    void sourceRowsAboutToBeInserted(const QModelIndex &parent, int start, int
end);
    void sourceRowsAboutToBeRemoved(const QModelIndex &parent, int start, int
end);
    void sourceRowsInserted(const QModelIndex &parent, int start, int end);
    void sourceRowsRemoved(const QModelIndex &parent, int start, int end);

private:
    int m_limit;
    bool m_sourceInserting;
    bool m_sourceRemoving;
    int m_dataChangedBegin;
    int m_dataChangedEnd;
};

#endif // __HISTORY_LIMIT_BYVISITS_MODEL_H__

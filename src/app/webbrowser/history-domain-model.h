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

#ifndef __HISTORY_DOMAIN_MODEL_H__
#define __HISTORY_DOMAIN_MODEL_H__

// Qt
#include <QtCore/QDateTime>
#include <QtCore/QSortFilterProxyModel>
#include <QtCore/QString>
#include <QtCore/QUrl>

class HistoryTimeframeModel;

class HistoryDomainModel : public QSortFilterProxyModel
{
    Q_OBJECT

    Q_PROPERTY(HistoryTimeframeModel* sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)
    Q_PROPERTY(QString domain READ domain WRITE setDomain NOTIFY domainChanged)
    Q_PROPERTY(QDateTime lastVisit READ lastVisit NOTIFY lastVisitChanged)
    Q_PROPERTY(QString lastVisitedTitle READ lastVisitedTitle NOTIFY lastVisitedTitleChanged)
    Q_PROPERTY(QUrl lastVisitedIcon READ lastVisitedIcon NOTIFY lastVisitedIconChanged)

public:
    HistoryDomainModel(QObject* parent=0);

    HistoryTimeframeModel* sourceModel() const;
    void setSourceModel(HistoryTimeframeModel* sourceModel);

    const QString& domain() const;
    void setDomain(const QString& domain);

    const QDateTime& lastVisit() const;
    const QString& lastVisitedTitle() const;
    const QUrl& lastVisitedIcon() const;

Q_SIGNALS:
    void sourceModelChanged() const;
    void domainChanged() const;
    void lastVisitChanged() const;
    void lastVisitedTitleChanged() const;
    void lastVisitedIconChanged() const;

protected:
    // reimplemented from QSortFilterProxyModel
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const;

private:
    QString m_domain;
    QDateTime m_lastVisit;
    QString m_lastVisitedTitle;
    QUrl m_lastVisitedIcon;

private Q_SLOTS:
    void onModelChanged();
};

#endif // __HISTORY_DOMAIN_MODEL_H__

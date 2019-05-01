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

#ifndef __DOMAIN_SETTINGS_MODEL_H__
#define __DOMAIN_SETTINGS_MODEL_H__

#include <QAbstractListModel>
#include <QString>
#include <QtSql/QSqlDatabase>

class DomainSettingsModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(QString databasePath READ databasePath WRITE setDatabasePath NOTIFY databasePathChanged)
    //Q_PROPERTY(int count READ rowCount NOTIFY rowCountChanged)

    Q_ENUMS(Roles)

public:
    DomainSettingsModel(QObject* parent=0);
    ~DomainSettingsModel();

    enum Roles {
        Domain = Qt::UserRole + 1,
        AllowCustomUrlSchemes,
        AllowLocation,
        UserAgent,
        ZoomFactor
    };

    // reimplemented from QAbstractListModel
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex& parent=QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role) const;
    void fetchMore(const QModelIndex &parent = QModelIndex());

    const QString databasePath() const;
    void setDatabasePath(const QString& path);

    Q_INVOKABLE bool contains(const QString& domain) const;
    Q_INVOKABLE bool areCustomUrlSchemesAllowed(const QString& domain);
    Q_INVOKABLE void allowCustomUrlSchemes(const QString& domain, bool allow);
    Q_INVOKABLE bool isLocationAllowed(const QString& domain) const;
    Q_INVOKABLE void allowLocation(const QString& domain, bool allow);
    Q_INVOKABLE QString getUserAgent(const QString& domain) const;
    Q_INVOKABLE void setUserAgent(const QString& domain, QString userAgent);
    Q_INVOKABLE double getZoomFactor(const QString& domain) const;
    Q_INVOKABLE void setZoomFactor(const QString& domain, double zoomFactor);

Q_SIGNALS:
    void databasePathChanged() const;
    void rowCountChanged();

private:
    QSqlDatabase m_database;
    int m_numRows;
    int m_fetchedCount;
    bool m_canFetchMore;

    struct DomainSetting {
        QString domain;
        bool allowCustomUrlSchemes;
        bool allowLocation;
        QString userAgent;
        double zoomFactor;
    };

    QList<DomainSetting> m_entries;

    void resetDatabase(const QString& databaseName);
    void createOrAlterDatabaseSchema();
    void insertEntry(const QString& domain);
    void removeEntry(const QString& domain);
    void removeObsoleteEntries();
    int getIndexForDomain(const QString& domain) const;
};

#endif

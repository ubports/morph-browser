/*
 * Copyright 2020 UBports Foundation
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
    Q_PROPERTY(int count READ rowCount NOTIFY rowCountChanged)
    Q_PROPERTY(double defaultZoomFactor READ defaultZoomFactor WRITE setDefaultZoomFactor)

    Q_ENUMS(AllowLocationPreference)
    Q_ENUMS(NotificationsPreference)
    Q_ENUMS(Roles)

public:
    DomainSettingsModel(QObject* parent=0);
    ~DomainSettingsModel();

    enum AllowLocationPreference {
     AskForLocationAccess = 0,
     AllowLocationAccess = 1,
     DenyLocationAccess = 2
    };

    enum NotificationsPreference {
     AskForNotificationsAccess = 0,
     AllowNotificationsAccess = 1,
     DenyNotificationsAccess = 2
    };

    enum Roles {
        Domain = Qt::UserRole + 1,
        DomainWithoutSubdomain,
        AllowCustomUrlSchemes,
        AllowLocation,
        AllowNotifications,
        UserAgentId,
        ZoomFactor
    };

    // reimplemented from QAbstractListModel
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex& parent=QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role) const;

    const QString databasePath() const;
    void setDatabasePath(const QString& path);

    double defaultZoomFactor() const;
    void setDefaultZoomFactor(double defaultZoomFactor);
    
    Q_INVOKABLE bool contains(const QString& domain) const;
    Q_INVOKABLE void deleteAndResetDataBase();
    Q_INVOKABLE bool areCustomUrlSchemesAllowed(const QString& domain);
    Q_INVOKABLE void allowCustomUrlSchemes(const QString& domain, bool allow, bool incognito);
    Q_INVOKABLE AllowLocationPreference getLocationPreference(const QString& domain) const;
    Q_INVOKABLE void setLocationPreference(const QString& domain, AllowLocationPreference preference);
    Q_INVOKABLE NotificationsPreference getNotificationsPreference(const QString& domain) const;
    Q_INVOKABLE void setNotificationsPreference(const QString& domain, NotificationsPreference, bool incognito);
    Q_INVOKABLE int getUserAgentId(const QString& domain) const;
    Q_INVOKABLE void setUserAgentId(const QString& domain, int userAgentId);
    Q_INVOKABLE void removeUserAgentIdFromAllDomains(int userAgentId);
    Q_INVOKABLE double getZoomFactor(const QString& domain) const;
    Q_INVOKABLE void setZoomFactor(const QString& domain, double zoomFactor);
    Q_INVOKABLE void insertEntry(const QString& domain, bool incognito);
    Q_INVOKABLE void removeEntry(const QString& domain);

Q_SIGNALS:
    void databasePathChanged() const;
    void rowCountChanged();
    void domainZoomFactorChanged(const QString& domain);

private:
    QSqlDatabase m_database;
    double m_defaultZoomFactor;

    struct DomainSetting {
        QString domain;
        QString domainWithoutSubdomain;
        bool allowCustomUrlSchemes;
        AllowLocationPreference allowLocation;
        NotificationsPreference allowNotifications;
        int userAgentId;
        double zoomFactor;
    };

    QList<DomainSetting> m_entries;

    void resetDatabase(const QString& databaseName);
    void createOrAlterDatabaseSchema();
    void populateFromDatabase();
    void removeObsoleteEntries();
    int getIndexForDomain(const QString& domain) const;
};

#endif

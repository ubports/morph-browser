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

class DomainSettingsModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString databasePath READ databasePath WRITE setDatabasePath NOTIFY databasePathChanged)
    //Q_PROPERTY(int count READ rowCount NOTIFY rowCountChanged)

    Q_ENUMS(Roles)

public:
    DomainSettingsModel();
    ~DomainSettingsModel();

    enum Roles {
        Domain,
        AllowCustomUrlSchemes,
        AllowLocation,
        UserAgent,
        ZoomFactor
    };

    const QString databasePath() const;
    void setDatabasePath(const QString& path);

    Q_INVOKABLE bool contains(const QString& domain) const;
    Q_INVOKABLE bool areCustomUrlSchemesAllowed(const QString& domain);
    Q_INVOKABLE void allowCustomUrlSchemes(const QString& domain, bool allow);
    Q_INVOKABLE void allowLocation(const QString& domain, bool allow);
    Q_INVOKABLE void setUserAgent(const QString& domain, QString userAgent);
    Q_INVOKABLE void setZoomFactor(const QString& domain, double zoomFactor);

Q_SIGNALS:
    void databasePathChanged() const;
    //void rowCountChanged();

private:
    QSqlDatabase m_database;
    int m_numRows;

    void resetDatabase(const QString& databaseName);
    void createOrAlterDatabaseSchema();
    void insertEntry(const QString& domain);
    void removeEntry(const QString& domain);
};

#endif

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

#ifndef __USER_AGENTS_MODEL_H__
#define __USER_AGENTS_MODEL_H__

#include <QAbstractListModel>
#include <QString>
#include <QtSql/QSqlDatabase>

class UserAgentsModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(QString databasePath READ databasePath WRITE setDatabasePath NOTIFY databasePathChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY rowCountChanged)

    Q_ENUMS(Roles)

public:
    UserAgentsModel(QObject* parent=0);
    ~UserAgentsModel();

    enum Roles {
        Id = Qt::UserRole + 1,
        Name,
        UserAgentString
    };

    // reimplemented from QAbstractListModel
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex& parent=QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role) const;

    const QString databasePath() const;
    void setDatabasePath(const QString& path);
    
    Q_INVOKABLE bool contains(const QString& userAgentName) const;
    Q_INVOKABLE void deleteAndResetDataBase();
    Q_INVOKABLE void insertEntry(const QString& userAgentName, const QString& userAgentString = "");
    Q_INVOKABLE void removeEntry(int userAgentId);
    Q_INVOKABLE void setUserAgentName(int userAgentId, const QString& userAgentName);
    Q_INVOKABLE QString getUserAgentString(int userAgentId) const;
    Q_INVOKABLE void setUserAgentString(int userAgentId, const QString& userAgentString);

Q_SIGNALS:
    void databasePathChanged() const;
    void rowCountChanged();

private:
    QSqlDatabase m_database;
    double m_defaultZoomFactor;

    struct UserAgent {
        int id;
        QString name;
        QString userAgentString;
    };

    QList<UserAgent> m_entries;

    void resetDatabase(const QString& databaseName);
    void createOrAlterDatabaseSchema();
    void populateFromDatabase();
    int getIndexForUserAgentId(int userAgentId) const;
    int getIndexForUserAgentName(const QString& userAgentName) const;
};

#endif

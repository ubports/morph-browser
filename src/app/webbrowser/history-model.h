/*
 * Copyright 2013-2016 Canonical Ltd.
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

#ifndef __HISTORY_MODEL_H__
#define __HISTORY_MODEL_H__

// Qt
#include <QtCore/QAbstractListModel>
#include <QtCore/QDateTime>
#include <QtCore/QList>
#include <QtCore/QPair>
#include <QtCore/QQueue>
#include <QtCore/QReadWriteLock>
#include <QtCore/QSet>
#include <QtCore/QString>
#include <QtCore/QThread>
#include <QtCore/QUrl>
#include <QtCore/QVariant>
#include <QtSql/QSqlDatabase>

class QTimer;

class DbWorker;

class HistoryModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(QString databasePath READ databasePath WRITE setDatabasePath NOTIFY databasePathChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY rowCountChanged)

    Q_ENUMS(Roles)

public:
    HistoryModel(QObject* parent=0);
    ~HistoryModel();

    enum Roles {
        Url = Qt::UserRole + 1,
        Domain,
        Title,
        Icon,
        Visits,
        LastVisit,
        LastVisitDate,
        LastVisitDateString,
        Hidden,
    };

    // reimplemented from QAbstractListModel
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex& parent=QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role) const;

    const QString databasePath() const;
    void setDatabasePath(const QString& path);

    Q_INVOKABLE int add(const QUrl& url, const QString& title, const QUrl& icon);
    Q_INVOKABLE bool update(const QUrl& url, const QString& title, const QUrl& icon);
    Q_INVOKABLE void removeEntryByUrl(const QUrl& url);
    Q_INVOKABLE void removeEntriesByDate(const QDate& date);
    Q_INVOKABLE void removeEntriesByDomain(const QString& domain);
    Q_INVOKABLE void clearAll();
    Q_INVOKABLE void hide(const QUrl& url);
    Q_INVOKABLE void unHide(const QUrl& url);
    Q_INVOKABLE QVariantMap get(int index) const;

Q_SIGNALS:
    void databasePathChanged() const;
    void rowCountChanged();
    void loaded() const;

protected:
    struct HistoryEntry {
        QUrl url;
        QString domain;
        QString title;
        QUrl icon;
        uint visits;
        QDateTime lastVisit;
        bool hidden;
    };
    QList<HistoryEntry> m_entries;
    int getEntryIndex(const QUrl& url) const;
    void updateExistingEntryInDatabase(const HistoryEntry& entry);

private Q_SLOTS:
    void onHiddenEntryFetched(const QUrl& url);
    void onEntryFetched(const QUrl& url, const QString& domain, const QString& title,
                        const QUrl& icon, int visits, const QDateTime& lastVisit);

private:
    QString m_databasePath;
    QSet<QUrl> m_hiddenEntries;

    void resetDatabase(const QString& databaseName);
    void removeByIndex(int index);
    void insertNewEntryInDatabase(const HistoryEntry& entry);
    void insertNewEntryInHiddenDatabase(const QUrl& url);
    void removeEntryFromDatabaseByUrl(const QUrl& url);
    void removeEntryFromHiddenDatabaseByUrl(const QUrl& url);
    void removeEntriesFromDatabaseByDate(const QDate& date);
    void removeEntriesFromDatabaseByDomain(const QString& domain);
    void clearDatabase();

    QThread m_dbWorkerThread;
    DbWorker* m_dbWorker;
};

class DbWorker : public QObject {
    Q_OBJECT

    Q_ENUMS(Operation)

public:
    DbWorker();
    ~DbWorker();

    enum Operation {
        InsertNewEntry,
        InsertNewHiddenEntry,
        UpdateExistingEntry,
        RemoveEntryByUrl,
        RemoveHiddenEntryByUrl,
        RemoveEntriesByDate,
        RemoveEntriesByDomain,
        Clear,
    };

Q_SIGNALS:
    void resetDatabase(const QString& databaseName);
    void fetchEntries();
    void hiddenEntryFetched(const QUrl& url);
    void entryFetched(const QUrl& url, const QString& domain, const QString& title,
                      const QUrl& icon, int visits, const QDateTime& lastVisit);
    void loaded();
    void enqueue(Operation operation, QVariantList values);

private Q_SLOTS:
    void doResetDatabase(const QString& databaseName);
    void doCreateOrAlterDatabaseSchema();
    void doFetchEntries();
    void doEnqueue(Operation operation, QVariantList values);
    void doFlush();

private:
    QSqlDatabase m_database;
    QReadWriteLock m_lock;
    QQueue<QPair<Operation, QVariantList>> m_pending;
    QTimer* m_flush;
};

#endif // __HISTORY_MODEL_H__

/*
 * Copyright 2014-2015 Canonical Ltd.
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

// Qt
#include <QtCore/QAbstractListModel>
#include <QtCore/QStringList>
#include <QtTest/QSignalSpy>
#include <QtTest/QtTest>

// local
#include "limit-proxy-model.h"

class SimpleListModel : public QAbstractListModel {
    Q_OBJECT

public:
    enum Roles {
        Index = Qt::UserRole + 1,
        String
    };

    QHash<int, QByteArray> roleNames() const
    {
        static QHash<int, QByteArray> roles;
        if (roles.isEmpty()) {
            roles[Index] = "index";
            roles[String] = "string";
        }
        return roles;
    }

    int rowCount(const QModelIndex& parent=QModelIndex()) const
    {
        return m_strings.count();
    }

    QVariant data(const QModelIndex& index, int role) const
    {
        if (!index.isValid()) {
            return QVariant();
        }
        switch (role) {
        case Index:
            return index.row();
        case String:
            return m_strings.at(index.row());
        default:
            return QVariant();
        }
    }

    void append(const QStringList& strings)
    {
        int index = m_strings.count();
        beginInsertRows(QModelIndex(), index, index + strings.count() - 1);
        m_strings << strings;
        endInsertRows();
    }

    void remove(int index)
    {
        beginRemoveRows(QModelIndex(), index, index);
        m_strings.removeAt(index);
        endRemoveRows();
    }

private:
    QStringList m_strings;
};

class LimitProxyModelTests : public QObject
{
    Q_OBJECT

private:
    SimpleListModel* strings;
    LimitProxyModel* model;

private Q_SLOTS:
    void init()
    {
        strings = new SimpleListModel;
        model = new LimitProxyModel;
        model->setSourceModel(strings);
    }

    void cleanup()
    {
        delete model;
        delete strings;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldLimitBeInitiallyMinusOne()
    {
        QCOMPARE(model->limit(), -1);
    }

    void shouldNotifyWhenChangingSourceModel()
    {
        QSignalSpy spy(model, SIGNAL(sourceModelChanged()));
        model->setSourceModel(strings);
        QVERIFY(spy.isEmpty());
        QStringListModel strings2;
        model->setSourceModel(&strings2);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->sourceModel(), &strings2);
        model->setSourceModel(0);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(model->sourceModel(), (QAbstractItemModel*) 0);
    }

    void shouldLimitEntriesWithLimitSetBeforePopulating()
    {
        model->setLimit(2);
        strings->append({"a", "b", "c"});
        QCOMPARE(model->rowCount(), 2);
        QCOMPARE(model->unlimitedRowCount(), 3);
    }

    void shouldLimitEntriesWithLimitSetAfterPopulating()
    {
        strings->append({"a", "b", "c"});
        model->setLimit(2);
        QCOMPARE(model->rowCount(), 2);
        QCOMPARE(model->unlimitedRowCount(), 3);
    }

    void shouldNotLimitEntriesIfLimitIsMinusOne()
    {
        model->setLimit(-1);
        strings->append({"a", "b", "c"});
        QCOMPARE(model->unlimitedRowCount(), 3);
        QCOMPARE(model->rowCount(), model->unlimitedRowCount());
    }

    void shouldNotLimitEntriesIfLimitIsGreaterThanRowCount()
    {
        model->setLimit(4);
        strings->append({"a", "b", "c"});
        QCOMPARE(model->unlimitedRowCount(), 3);
        QCOMPARE(model->rowCount(), model->unlimitedRowCount());
    }

    void shouldUpdateRowCountAndNotifyAfterAnEntryIsRemoved()
    {
        model->setLimit(2);
        strings->append({"a", "b", "c", "d"});

        QSignalSpy spyChanged(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));
        QSignalSpy spyRemoved(model, SIGNAL(rowsRemoved(QModelIndex, int, int)));

        strings->remove(0);
        QCOMPARE(spyChanged.count(), 1);
        QVERIFY(spyRemoved.isEmpty());

        QCOMPARE(model->data(model->index(0, 0), SimpleListModel::String).toString(), QString("b"));
        QCOMPARE(model->data(model->index(1, 0), SimpleListModel::String).toString(), QString("c"));

        QCOMPARE(model->unlimitedRowCount(), 3);
        QCOMPARE(model->rowCount(), 2);
    }

    void shouldGetItemWithCorrectValues()
    {
        strings->append({"a"});
        QVariantMap item = model->get(0);
        QHash<int, QByteArray> roles = model->roleNames();
        QCOMPARE(roles.count(), item.count());
        Q_FOREACH(int role, roles.keys()) {
            QString roleName = QString::fromUtf8(roles.value(role));
            QCOMPARE(model->data(model->index(0, 0), role), item.value(roleName));
        }
    }

    void shouldReturnEmptyItemIfGetOutOfBounds()
    {
        QVariantMap item = model->get(1);
        QVERIFY(item.isEmpty());
    }

};

QTEST_MAIN(LimitProxyModelTests)
#include "tst_LimitProxyModelTests.moc"

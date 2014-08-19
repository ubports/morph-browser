/*
 * Copyright 2013-2014 Canonical Ltd.
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
#include <QtQml/QQmlComponent>
#include <QtQml/QQmlEngine>
#include <QtQml/QQmlProperty>
#include <QtQuick/QQuickItem>
#include <QtTest/QSignalSpy>
#include <QtTest/QtTest>

// local
#include "tabs-model.h"

class TabsModelTests : public QObject
{
    Q_OBJECT

private:
    TabsModel* model;

    QQuickItem* createTab()
    {
        QQmlEngine engine;
        QQmlComponent component(&engine);
        QByteArray data("import QtQuick 2.0\nItem {\nproperty url url\n"
                        "property string title\nproperty url icon\n}");
        component.setData(data, QUrl());
        QObject* object = component.create();
        object->setParent(this);
        QQuickItem* item = qobject_cast<QQuickItem*>(object);
        return item;
    }

private Q_SLOTS:
    void init()
    {
        model = new TabsModel;
    }

    void cleanup()
    {
        delete model;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(model->rowCount(), 0);
        QCOMPARE(model->currentTab(), (QObject*) 0);
    }

    void shouldExposeRoleNames()
    {
        QList<QByteArray> roleNames = model->roleNames().values();
        QVERIFY(roleNames.contains("url"));
        QVERIFY(roleNames.contains("title"));
        QVERIFY(roleNames.contains("icon"));
        QVERIFY(roleNames.contains("tab"));
    }

    void shouldNotAllowSettingTheIndexToAnInvalidValue()
    {
        model->setCurrent(0);
        QCOMPARE(model->currentTab(), (QObject*) 0);
        model->setCurrent(2);
        QCOMPARE(model->currentTab(), (QObject*) 0);
        model->setCurrent(-2);
        QCOMPARE(model->currentTab(), (QObject*) 0);
    }

    void shouldNotAddNullTab()
    {
        QCOMPARE(model->add(0), -1);
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldReturnIndexWhenAddingTab()
    {
        for(int i = 0; i < 3; ++i) {
            QCOMPARE(model->add(createTab()), i);
        }
    }

    void shouldUpdateCountWhenAddingTab()
    {
        QSignalSpy spy(model, SIGNAL(countChanged()));
        model->add(createTab());
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->rowCount(), 1);
    }

    void shouldUpdateCountWhenRemovingTab()
    {
        model->add(createTab());
        QSignalSpy spy(model, SIGNAL(countChanged()));
        model->remove(0);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldNotAllowRemovingAtInvalidIndex()
    {
        QCOMPARE(model->remove(0), (QObject*) 0);
        QCOMPARE(model->remove(2), (QObject*) 0);
        QCOMPARE(model->remove(-2), (QObject*) 0);
    }

    void shouldReturnTabWhenRemoving()
    {
        QQuickItem* tab = createTab();
        model->add(tab);
        QObject* removed = model->remove(0);
        QCOMPARE(removed, tab);
    }

    void shouldNotChangeCurrentTabWhenAddingUnlessModelWasEmpty()
    {
        QSignalSpy spy(model, SIGNAL(currentTabChanged()));
        QQuickItem* tab = createTab();
        model->add(tab);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->currentTab(), tab);
        model->add(createTab());
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->currentTab(), tab);
    }

    void shouldNotDeleteTabWhenRemoving()
    {
        QQuickItem* tab = createTab();
        model->add(tab);
        model->remove(0);
        QCOMPARE(tab->parent(), this);
    }

    void shouldNotifyWhenAddingTab()
    {
        QSignalSpy spy(model, SIGNAL(rowsInserted(const QModelIndex&, int, int)));
        for(int i = 0; i < 3; ++i) {
            model->add(createTab());
            QCOMPARE(spy.count(), 1);
            QList<QVariant> args = spy.takeFirst();
            QCOMPARE(args.at(1).toInt(), i);
            QCOMPARE(args.at(2).toInt(), i);
        }
    }

    void shouldNotifyWhenRemovingTab()
    {
        QSignalSpy spy(model, SIGNAL(rowsRemoved(const QModelIndex&, int, int)));
        for(int i = 0; i < 5; ++i) {
            model->add(createTab());
        }
        model->remove(3);
        QCOMPARE(spy.count(), 1);
        QList<QVariant> args = spy.takeFirst();
        QCOMPARE(args.at(1).toInt(), 3);
        QCOMPARE(args.at(2).toInt(), 3);
        for(int i = 3; i >= 0; --i) {
            model->remove(i);
            QCOMPARE(spy.count(), 1);
            args = spy.takeFirst();
            QCOMPARE(args.at(1).toInt(), i);
            QCOMPARE(args.at(2).toInt(), i);
        }
    }

    void shouldNotifyWhenTabPropertiesChange()
    {
        qRegisterMetaType<QVector<int> >();
        QSignalSpy spy(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));
        QQuickItem* tab = createTab();
        model->add(tab);

        QQmlProperty(tab, "url").write(QUrl("http://ubuntu.com"));
        QCOMPARE(spy.count(), 1);
        QList<QVariant> args = spy.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 0);
        QCOMPARE(args.at(1).toModelIndex().row(), 0);
        QVector<int> roles = args.at(2).value<QVector<int> >();
        QCOMPARE(roles.size(), 1);
        QVERIFY(roles.contains(TabsModel::Url));

        QQmlProperty(tab, "title").write(QString("Lorem Ipsum"));
        QCOMPARE(spy.count(), 1);
        args = spy.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 0);
        QCOMPARE(args.at(1).toModelIndex().row(), 0);
        roles = args.at(2).value<QVector<int> >();
        QCOMPARE(roles.size(), 1);
        QVERIFY(roles.contains(TabsModel::Title));

        QQmlProperty(tab, "icon").write(QUrl("image://webicon/123"));
        QCOMPARE(spy.count(), 1);
        args = spy.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 0);
        QCOMPARE(args.at(1).toModelIndex().row(), 0);
        roles = args.at(2).value<QVector<int> >();
        QCOMPARE(roles.size(), 1);
        QVERIFY(roles.contains(TabsModel::Icon));
    }

    void shouldUpdateCurrentTabWhenSettingCurrent()
    {
        QQuickItem* tab1 = createTab();
        model->add(tab1);
        QSignalSpy spy(model, SIGNAL(currentTabChanged()));
        model->setCurrent(0);
        QCOMPARE(spy.count(), 0);
        QCOMPARE(model->currentTab(), tab1);
        QQuickItem* tab2 = createTab();
        model->add(tab2);
        model->setCurrent(1);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->currentTab(), tab2);
    }

    void shouldUpdateCurrentTabWhenRemoving()
    {
        QSignalSpy spy(model, SIGNAL(currentTabChanged()));

        // Adding a tab to an empty model should update the current tab.
        // Removing the last tab from the model should update it too.
        model->add(createTab());
        model->remove(0);
        QCOMPARE(spy.count(), 2);

        // When removing a tab after the current one,
        // the current tab shouldn’t change.
        QQuickItem* tab1 = createTab();
        model->add(tab1);
        model->add(createTab());
        spy.clear();
        model->remove(1);
        QCOMPARE(model->currentTab(), tab1);
        QCOMPARE(spy.count(), 0);

        // When removing the current tab, if there is a tab after it,
        // it becomes the current one.
        QQuickItem* tab2 = createTab();
        model->add(tab2);
        spy.clear();
        model->remove(0);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->currentTab(), tab2);

        // When removing the current tab, if it was the last one, the
        // current tab should be reset to 0.
        spy.clear();
        model->remove(0);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->currentTab(), (QObject*) 0);
    }

    void shouldReturnData()
    {
        QQuickItem* tab = createTab();
        QQmlProperty(tab, "url").write(QUrl("http://ubuntu.com/"));
        QQmlProperty(tab, "title").write(QString("Lorem Ipsum"));
        QQmlProperty(tab, "icon").write(QUrl("image://webicon/123"));
        model->add(tab);
        QVERIFY(!model->data(QModelIndex(), TabsModel::Url).isValid());
        QVERIFY(!model->data(model->index(-1, 0), TabsModel::Url).isValid());
        QVERIFY(!model->data(model->index(3, 0), TabsModel::Url).isValid());
        QCOMPARE(model->data(model->index(0, 0), TabsModel::Url).toUrl(), QUrl("http://ubuntu.com/"));
        QCOMPARE(model->data(model->index(0, 0), TabsModel::Title).toString(), QString("Lorem Ipsum"));
        QCOMPARE(model->data(model->index(0, 0), TabsModel::Icon).toUrl(), QUrl("image://webicon/123"));
        QCOMPARE(model->data(model->index(0, 0), TabsModel::Tab).value<QQuickItem*>(), tab);
        QVERIFY(!model->data(model->index(0, 0), TabsModel::Tab + 3).isValid());
    }
};

QTEST_MAIN(TabsModelTests)
#include "tst_TabsModelTests.moc"

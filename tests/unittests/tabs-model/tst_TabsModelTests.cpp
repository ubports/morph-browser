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

    QQuickItem* createWebView()
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
        QCOMPARE(model->currentWebview(), (QObject*) 0);
    }

    void shouldExposeRoleNames()
    {
        QList<QByteArray> roleNames = model->roleNames().values();
        QVERIFY(roleNames.contains("url"));
        QVERIFY(roleNames.contains("title"));
        QVERIFY(roleNames.contains("icon"));
        QVERIFY(roleNames.contains("webview"));
    }

    void shouldNotAllowSettingTheIndexToAnInvalidValue()
    {
        model->setCurrent(0);
        QCOMPARE(model->currentWebview(), (QObject*) 0);
        model->setCurrent(2);
        QCOMPARE(model->currentWebview(), (QObject*) 0);
        model->setCurrent(-2);
        QCOMPARE(model->currentWebview(), (QObject*) 0);
    }

    void shouldNotAddNullWebView()
    {
        QCOMPARE(model->add(0), -1);
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldReturnIndexWhenAddingWebView()
    {
        for(int i = 0; i < 3; ++i) {
            QCOMPARE(model->add(createWebView()), i);
        }
    }

    void shouldUpdateCountWhenAddingWebView()
    {
        QSignalSpy spy(model, SIGNAL(countChanged()));
        model->add(createWebView());
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->rowCount(), 1);
    }

    void shouldUpdateCountWhenRemovingWebView()
    {
        model->add(createWebView());
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

    void shouldReturnWebViewWhenRemoving()
    {
        QQuickItem* webview = createWebView();
        model->add(webview);
        QObject* removed = model->remove(0);
        QCOMPARE(removed, webview);
    }

    void shouldNotChangeCurrentWebviewWhenAddingUnlessModelWasEmpty()
    {
        QSignalSpy spy(model, SIGNAL(currentWebviewChanged()));
        QQuickItem* webview = createWebView();
        model->add(webview);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->currentWebview(), webview);
        model->add(createWebView());
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->currentWebview(), webview);
    }

    void shouldNotDeleteWebViewWhenRemoving()
    {
        QQuickItem* webview = createWebView();
        model->add(webview);
        model->remove(0);
        QCOMPARE(webview->parent(), this);
    }

    void shouldNotifyWhenAddingWebView()
    {
        QSignalSpy spy(model, SIGNAL(rowsInserted(const QModelIndex&, int, int)));
        for(int i = 0; i < 3; ++i) {
            model->add(createWebView());
            QCOMPARE(spy.count(), 1);
            QList<QVariant> args = spy.takeFirst();
            QCOMPARE(args.at(1).toInt(), i);
            QCOMPARE(args.at(2).toInt(), i);
        }
    }

    void shouldNotifyWhenRemovingWebView()
    {
        QSignalSpy spy(model, SIGNAL(rowsRemoved(const QModelIndex&, int, int)));
        for(int i = 0; i < 5; ++i) {
            model->add(createWebView());
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

    void shouldNotifyWhenWebViewPropertiesChange()
    {
        qRegisterMetaType<QVector<int> >();
        QSignalSpy spy(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));
        QQuickItem* webview = createWebView();
        model->add(webview);

        QQmlProperty(webview, "url").write(QUrl("http://ubuntu.com"));
        QCOMPARE(spy.count(), 1);
        QList<QVariant> args = spy.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 0);
        QCOMPARE(args.at(1).toModelIndex().row(), 0);
        QVector<int> roles = args.at(2).value<QVector<int> >();
        QCOMPARE(roles.size(), 1);
        QVERIFY(roles.contains(TabsModel::Url));

        QQmlProperty(webview, "title").write(QString("Lorem Ipsum"));
        QCOMPARE(spy.count(), 1);
        args = spy.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 0);
        QCOMPARE(args.at(1).toModelIndex().row(), 0);
        roles = args.at(2).value<QVector<int> >();
        QCOMPARE(roles.size(), 1);
        QVERIFY(roles.contains(TabsModel::Title));

        QQmlProperty(webview, "icon").write(QUrl("image://webicon/123"));
        QCOMPARE(spy.count(), 1);
        args = spy.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 0);
        QCOMPARE(args.at(1).toModelIndex().row(), 0);
        roles = args.at(2).value<QVector<int> >();
        QCOMPARE(roles.size(), 1);
        QVERIFY(roles.contains(TabsModel::Icon));
    }

    void shouldUpdateCurrentWebviewWhenSettingCurrent()
    {
        QQuickItem* webview1 = createWebView();
        model->add(webview1);
        QSignalSpy spy(model, SIGNAL(currentWebviewChanged()));
        model->setCurrent(0);
        QCOMPARE(spy.count(), 0);
        QCOMPARE(model->currentWebview(), webview1);
        QQuickItem* webview2 = createWebView();
        model->add(webview2);
        model->setCurrent(1);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->currentWebview(), webview2);
    }

    void shouldUpdateCurrentWebviewWhenRemoving()
    {
        QSignalSpy spy(model, SIGNAL(currentWebviewChanged()));

        // Adding a webview to an empty model should update the current webview.
        // Removing the last webview from the model should update it too.
        model->add(createWebView());
        model->remove(0);
        QCOMPARE(spy.count(), 2);

        // When removing a webview after the current one,
        // the current webview shouldn’t change.
        QQuickItem* webview1 = createWebView();
        model->add(webview1);
        model->add(createWebView());
        spy.clear();
        model->remove(1);
        QCOMPARE(model->currentWebview(), webview1);
        QCOMPARE(spy.count(), 0);

        // When removing the current webview, if there is a webview after it,
        // it becomes the current one.
        QQuickItem* webview2 = createWebView();
        model->add(webview2);
        spy.clear();
        model->remove(0);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->currentWebview(), webview2);

        // When removing the current webview, if it was the last one, the
        // current webview should be reset to 0.
        spy.clear();
        model->remove(0);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->currentWebview(), (QObject*) 0);
    }

    void shouldReturnData()
    {
        QQuickItem* webview = createWebView();
        QQmlProperty(webview, "url").write(QUrl("http://ubuntu.com/"));
        QQmlProperty(webview, "title").write(QString("Lorem Ipsum"));
        QQmlProperty(webview, "icon").write(QUrl("image://webicon/123"));
        model->add(webview);
        QVERIFY(!model->data(QModelIndex(), TabsModel::Url).isValid());
        QVERIFY(!model->data(model->index(-1, 0), TabsModel::Url).isValid());
        QVERIFY(!model->data(model->index(3, 0), TabsModel::Url).isValid());
        QCOMPARE(model->data(model->index(0, 0), TabsModel::Url).toUrl(), QUrl("http://ubuntu.com/"));
        QCOMPARE(model->data(model->index(0, 0), TabsModel::Title).toString(), QString("Lorem Ipsum"));
        QCOMPARE(model->data(model->index(0, 0), TabsModel::Icon).toUrl(), QUrl("image://webicon/123"));
        QCOMPARE(model->data(model->index(0, 0), TabsModel::WebView).value<QQuickItem*>(), webview);
        QVERIFY(!model->data(model->index(0, 0), TabsModel::WebView + 3).isValid());
    }
};

QTEST_MAIN(TabsModelTests)
#include "tst_TabsModelTests.moc"

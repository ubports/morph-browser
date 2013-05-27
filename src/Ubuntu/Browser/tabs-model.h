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

#ifndef __TABS_MODEL_H__
#define __TABS_MODEL_H__

// Qt
#include <QtCore/QAbstractListModel>
#include <QtCore/QList>

class QQuickItem;

class TabsModel : public QAbstractListModel
{
    Q_OBJECT

    Q_ENUMS(Roles)

    Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(QQuickItem* currentWebview READ currentWebview NOTIFY currentWebviewChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    TabsModel(QObject* parent=0);
    ~TabsModel();

    enum Roles {
        Url = Qt::UserRole + 1,
        Title,
        Icon,
        Thumbnail,
        WebView
    };

    // reimplemented from QAbstractListModel
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex& parent=QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role) const;

    int currentIndex() const;
    void setCurrentIndex(int index);

    QQuickItem* currentWebview() const;

    int count() const;

    Q_INVOKABLE int add(QQuickItem* webview);
    Q_INVOKABLE QQuickItem* remove(int index);

Q_SIGNALS:
    void currentIndexChanged() const;
    void currentWebviewChanged() const;
    void countChanged() const;

private Q_SLOTS:
    void onUrlChanged();
    void onTitleChanged();
    void onIconChanged();

private:
    QList<QQuickItem*> m_webviews;
    int m_currentIndex;

    bool checkValidTabIndex(int index) const;
    void onDataChanged(QQuickItem* webview, int role);
};

#endif // __TABS_MODEL_H__

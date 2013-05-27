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

#include "tabs-model.h"

// Qt
#include <QtCore/QDebug>
#include <QtQuick/QQuickItem>

/*!
    \class TabsModel
    \brief List model that stores the list of currently open tabs.

    TabsModel is a list model that stores the list of currently open tabs.
    Each tab holds a pointer to a WebView and associated metadata (URL, title,
    icon, thumbnail).

    The model doesn’t own the WebView, so it is the responsibility of whoever
    adds a tab to instantiate the corresponding WebView, and to destroy it after
    it’s removed from the model.
*/
TabsModel::TabsModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_currentIndex(-1)
{
}

TabsModel::~TabsModel()
{
}

QHash<int, QByteArray> TabsModel::roleNames() const
{
    static QHash<int, QByteArray> roles;
    if (roles.isEmpty()) {
        roles[Url] = "url";
        roles[Title] = "title";
        roles[Icon] = "icon";
        roles[Thumbnail] = "thumbnail";
        roles[WebView] = "webview";
    }
    return roles;
}

int TabsModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_webviews.count();
}

QVariant TabsModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    int row = index.row();
    if (!checkValidTabIndex(row)) {
        return QVariant();
    }
    QQuickItem* webview = m_webviews.at(row);
    switch (role) {
    case Url:
        return webview->property("url");
    case Title:
        return webview->property("title");
    case Icon:
        return webview->property("icon");
    case Thumbnail:
        // XXX: not implemented yet
        return QVariant();
    case WebView:
        return QVariant::fromValue(webview);
    default:
        return QVariant();
    }
}

int TabsModel::currentIndex() const
{
    return m_currentIndex;
}

void TabsModel::setCurrentIndex(int index)
{
    if (index == m_currentIndex) {
        return;
    }
    if (!checkValidTabIndex(index)) {
        return;
    }
    m_currentIndex = index;
    Q_EMIT currentIndexChanged();
    Q_EMIT currentWebviewChanged();
}

QQuickItem* TabsModel::currentWebview() const
{
    if (m_currentIndex >= 0) {
        return m_webviews.at(m_currentIndex);
    } else {
        return 0;
    }
}

int TabsModel::count() const
{
    return rowCount();
}

/*!
    Add a tab to the model.

    It is the responsibility of the caller to instantiate the corresponding
    WebView beforehand.
*/
void TabsModel::add(QQuickItem* webview)
{
    if (webview == 0) {
        qWarning() << "Invalid WebView";
        return;
    }
    int count = m_webviews.count();
    beginInsertRows(QModelIndex(), count, count);
    m_webviews.append(webview);
    connect(webview, SIGNAL(urlChanged()), SLOT(onUrlChanged()));
    connect(webview, SIGNAL(titleChanged()), SLOT(onTitleChanged()));
    connect(webview, SIGNAL(iconChanged()), SLOT(onIconChanged()));
    endInsertRows();
    Q_EMIT countChanged();
}

/*!
    Given its index, remove a tab from the model.

    It is the responsibility of the caller to destroy the corresponding
    WebView afterwards.
*/
void TabsModel::remove(int index)
{
    if (!checkValidTabIndex(index)) {
        return;
    }
    beginRemoveRows(QModelIndex(), index, index);
    QQuickItem* webview = m_webviews.takeAt(index);
    webview->disconnect(this);
    endRemoveRows();
    Q_EMIT countChanged();
}

bool TabsModel::checkValidTabIndex(int index) const
{
    if ((index < 0) || (index >= m_webviews.count())) {
        qWarning() << "Invalid tab index:" << index;
        return false;
    }
    return true;
}

void TabsModel::onDataChanged(QQuickItem* webview, int role)
{
    int index = m_webviews.indexOf(webview);
    if (checkValidTabIndex(index)) {
        Q_EMIT dataChanged(this->index(index, 0), this->index(index, 0), QVector<int>() << role);
    }
}

void TabsModel::onUrlChanged()
{
    onDataChanged(qobject_cast<QQuickItem*>(sender()), Url);
}

void TabsModel::onTitleChanged()
{
    onDataChanged(qobject_cast<QQuickItem*>(sender()), Title);
}

void TabsModel::onIconChanged()
{
    onDataChanged(qobject_cast<QQuickItem*>(sender()), Icon);
}

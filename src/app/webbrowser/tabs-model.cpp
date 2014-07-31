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

#include "tabs-model.h"

// Qt
#include <QtCore/QDebug>
#include <QtCore/QObject>

/*!
    \class TabsModel
    \brief List model that stores the list of currently open tabs.

    TabsModel is a list model that stores the list of currently open tabs.
    Each tab holds a pointer to a WebView and associated metadata (URL, title,
    icon).

    The model doesn’t own the WebView, so it is the responsibility of whoever
    adds a tab to instantiate the corresponding WebView, and to destroy it after
    it’s removed from the model.
*/
TabsModel::TabsModel(QObject* parent)
    : QAbstractListModel(parent)
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
    QObject* webview = m_webviews.at(index.row());
    switch (role) {
    case Url:
        return webview->property("url");
    case Title:
        return webview->property("title");
    case Icon:
        return webview->property("icon");
    case WebView:
        return QVariant::fromValue(webview);
    default:
        return QVariant();
    }
}

QObject* TabsModel::currentWebview() const
{
    if (m_webviews.isEmpty()) {
        return 0;
    }
    return m_webviews.first();
}

/*!
    Add a tab to the model and return the corresponding index in the model.

    It is the responsibility of the caller to instantiate the corresponding
    WebView beforehand.
*/
int TabsModel::add(QObject* webview)
{
    if (webview == 0) {
        qWarning() << "Invalid WebView";
        return -1;
    }
    int index = m_webviews.count();
    beginInsertRows(QModelIndex(), index, index);
    m_webviews.append(webview);
    connect(webview, SIGNAL(urlChanged()), SLOT(onUrlChanged()));
    connect(webview, SIGNAL(titleChanged()), SLOT(onTitleChanged()));
    connect(webview, SIGNAL(iconChanged()), SLOT(onIconChanged()));
    endInsertRows();
    Q_EMIT countChanged();
    if (index == 0) {
        Q_EMIT currentWebviewChanged();
    }
    return index;
}

/*!
    Given its index, remove a tab from the model, and return the corresponding
    WebView.

    It is the responsibility of the caller to destroy the corresponding
    WebView afterwards.
*/
QObject* TabsModel::remove(int index)
{
    if (!checkValidTabIndex(index)) {
        return 0;
    }
    beginRemoveRows(QModelIndex(), index, index);
    QObject* webview = m_webviews.takeAt(index);
    webview->disconnect(this);
    endRemoveRows();
    Q_EMIT countChanged();
    if (index == 0) {
        Q_EMIT currentWebviewChanged();
    }
    return webview;
}

void TabsModel::setCurrent(int index)
{
    if (index == 0) {
        return;
    }
    if (!checkValidTabIndex(index)) {
        return;
    }
    beginMoveRows(QModelIndex(), index, index, QModelIndex(), 0);
    m_webviews.prepend(m_webviews.takeAt(index));
    endMoveRows();
    Q_EMIT currentWebviewChanged();
}

bool TabsModel::checkValidTabIndex(int index) const
{
    if ((index < 0) || (index >= m_webviews.count())) {
        qWarning() << "Invalid tab index:" << index;
        return false;
    }
    return true;
}

void TabsModel::onDataChanged(QObject* webview, int role)
{
    int index = m_webviews.indexOf(webview);
    if (checkValidTabIndex(index)) {
        Q_EMIT dataChanged(this->index(index, 0), this->index(index, 0), QVector<int>() << role);
    }
}

void TabsModel::onUrlChanged()
{
    onDataChanged(sender(), Url);
}

void TabsModel::onTitleChanged()
{
    onDataChanged(sender(), Title);
}

void TabsModel::onIconChanged()
{
    onDataChanged(sender(), Icon);
}

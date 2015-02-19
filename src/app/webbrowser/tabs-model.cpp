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
    Each tab holds a pointer to a Tab and associated metadata (URL, title,
    icon).

    The model doesn’t own the Tab, so it is the responsibility of whoever
    adds a tab to instantiate the corresponding Tab, and to destroy it after
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
        roles[Tab] = "tab";
    }
    return roles;
}

int TabsModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_tabs.count();
}

QVariant TabsModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    QObject* tab = m_tabs.at(index.row());
    switch (role) {
    case Url:
        return tab->property("url");
    case Title:
        return tab->property("title");
    case Icon:
        return tab->property("icon");
    case Tab:
        return QVariant::fromValue(tab);
    default:
        return QVariant();
    }
}

QObject* TabsModel::currentTab() const
{
    if (m_tabs.isEmpty()) {
        return 0;
    }
    return m_tabs.first();
}

/*!
    Add a tab to the model and return the corresponding index in the model.

    It is the responsibility of the caller to instantiate the corresponding
    Tab beforehand.
*/
int TabsModel::add(QObject* tab)
{
    if (tab == 0) {
        qWarning() << "Invalid Tab";
        return -1;
    }
    int index = m_tabs.count();
    beginInsertRows(QModelIndex(), index, index);
    m_tabs.append(tab);
    connect(tab, SIGNAL(urlChanged()), SLOT(onUrlChanged()));
    connect(tab, SIGNAL(titleChanged()), SLOT(onTitleChanged()));
    connect(tab, SIGNAL(iconChanged()), SLOT(onIconChanged()));
    endInsertRows();
    Q_EMIT countChanged();
    if (index == 0) {
        Q_EMIT currentTabChanged();
    }
    return index;
}

/*!
    Given its index, remove a tab from the model, and return the corresponding
    Tab.

    It is the responsibility of the caller to destroy the corresponding
    Tab afterwards.
*/
QObject* TabsModel::remove(int index)
{
    if (!checkValidTabIndex(index)) {
        return 0;
    }
    beginRemoveRows(QModelIndex(), index, index);
    QObject* tab = m_tabs.takeAt(index);
    tab->disconnect(this);
    endRemoveRows();
    Q_EMIT countChanged();
    if (index == 0) {
        Q_EMIT currentTabChanged();
    }
    return tab;
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
    m_tabs.prepend(m_tabs.takeAt(index));
    endMoveRows();
    Q_EMIT currentTabChanged();
}

QObject* TabsModel::get(int index) const
{
    if (!checkValidTabIndex(index)) {
        return 0;
    }
    return m_tabs.at(index);
}

bool TabsModel::checkValidTabIndex(int index) const
{
    if ((index < 0) || (index >= m_tabs.count())) {
        qWarning() << "Invalid tab index:" << index;
        return false;
    }
    return true;
}

void TabsModel::onDataChanged(QObject* tab, int role)
{
    int index = m_tabs.indexOf(tab);
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

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

#ifndef __BROWSER_UTILS_H__
#define __BROWSER_UTILS_H__

#include <QtCore/QObject>

class BrowserUtils : public QObject
{
    Q_OBJECT

public:
    explicit BrowserUtils(QObject* parent=0);

    Q_INVOKABLE void deleteAllCookiesOfProfile(QObject * profileObject) const;
};

#endif // __BROWSER_UTILS_H__

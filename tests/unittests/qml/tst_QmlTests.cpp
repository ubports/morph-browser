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
#include <QtQml/QtQml>
#include <QtQuickTest/QtQuickTest>

// local
#include "item-capture.h"

int main(int argc, char** argv)
{
    const char* uri = "webbrowserapp.private";
    qmlRegisterType<ItemCapture>(uri, 0, 1, "ItemCapture");

    return quick_test_main(argc, argv, "QmlTests", 0);
}

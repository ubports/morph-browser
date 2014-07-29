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

/* Manually define the main test function instead of relying on
 * the QUICK_TEST_MAIN macro because we need to inject out custom QML
 * types into the test that are coming from a private library */

#include <QtQml/QtQml>
#include <QtQml/QQmlEngine>
#include <QtQuickTest/QtQuickTest>
#include <QtQuickTest/quicktestglobal.h>

#include "../../../src/app/webbrowser/url-helper.h"

int main(int argc, char **argv)
{
    const char* uri = "webbrowserapp.private";
    qmlRegisterType<UrlHelper>(uri, 0, 1, "UrlHelper");
    return quick_test_main(argc, argv, "QmlTests", 0);
}


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

pragma Singleton

import QtQml 2.0
import Morph.Web 0.1 as Morph

QtObject {
    property alias customUA: context.userAgent

    property QtObject sharedContext: Morph.WebContext {
        id: context
        offTheRecord: false
        storageName: "Default"
    }

    property QtObject sharedIncognitoContext: Morph.WebContext {
        id: incognitoContext
        offTheRecord: true
    }
}

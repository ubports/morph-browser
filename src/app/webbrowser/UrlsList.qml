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

import QtQuick 2.0
import Ubuntu.Components 1.1

Column {
    id: urlsList

    property alias model: urlsListRepeater.model
    property int limit

    signal urlClicked(url url)
    signal urlRemoved(url url)

    spacing: units.gu(1)

    Repeater {
        id: urlsListRepeater

        delegate: Loader {
            active: index < limit
            sourceComponent: UrlDelegate{
                id: urlDelegate
                width: urlsList.width
                height: units.gu(5)

                icon: model.icon
                title: model.title ? model.title : model.url
                url: model.url

                onClicked: urlsList.urlClicked(model.url)
                onRemoved: urlsList.urlRemoved(model.url)
            }
        }
    }
}

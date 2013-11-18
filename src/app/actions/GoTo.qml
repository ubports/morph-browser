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

import Ubuntu.Components 0.1
import Ubuntu.Unity.Action 1.0 as UnityActions

UnityActions.Action {
    text: i18n.tr("Goto")
    // TRANSLATORS: This is a free-form list of keywords associated to the 'Goto' action.
    // Keywords may actually be sentences, and must be separated by semi-colons.
    keywords: i18n.tr("Address;URL;www")
    parameterType: UnityActions.Action.String
}

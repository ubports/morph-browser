/*
 * Copyright 2013-2015 Canonical Ltd.
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

import Ubuntu.Components 1.3
import Ubuntu.Unity.Action 1.1 as UnityActions

UnityActions.Action {
    text: i18n.tr("New Tab")
    // TRANSLATORS: This is a free-form list of keywords associated to the 'New Tab' action.
    // Keywords may actually be sentences, and must be separated by semi-colons.
    keywords: i18n.tr("Open a New Tab")
}

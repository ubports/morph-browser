# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2013-2016 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

"""webbrowser-app autopilot tests and emulators - top level package."""


import ubuntuuitoolkit as uitk

from autopilot import introspection

from webbrowser_app.emulators import browser


class Webbrowser(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    """Autopilot custom proxy object for the webbrowser app."""

    @classmethod
    def validate_dbus_object(cls, path, state):
        name = introspection.get_classname_from_path(path)
        if name == b'webbrowser-app':
            if state['applicationName'][1] == 'webbrowser-app':
                return True
        return False

    @property
    def main_window(self):
        return self.select_single(browser.Browser)

    def get_windows(self, **kwargs):
        return self.select_many(browser.Browser, **kwargs)

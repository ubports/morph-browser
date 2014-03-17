# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2013 Canonical
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

from __future__ import absolute_import

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestToolbar(StartOpenRemotePageTestCaseBase):

    """Tests interaction with the toolbar."""

    def test_unfocus_chrome_hides_it(self):
        self.ensure_chrome_is_hidden()
        self.main_window.open_toolbar()
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        self.assert_chrome_eventually_hidden()

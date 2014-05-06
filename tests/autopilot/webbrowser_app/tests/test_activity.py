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

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestActivity(StartOpenRemotePageTestCaseBase):

    """Tests the activity view."""

    def test_validating_url_hides_activity_view(self):
        self.ensure_activity_view_visible()
        self.assert_chrome_eventually_hidden()
        self.main_window.open_toolbar()
        self.clear_address_bar()
        url = self.base_url + "/aleaiactaest"
        self.type_in_address_bar(url)
        self.keyboard.press_and_release("Enter")
        self.assert_activity_view_eventually_hidden()
        self.assert_page_eventually_loaded(url)

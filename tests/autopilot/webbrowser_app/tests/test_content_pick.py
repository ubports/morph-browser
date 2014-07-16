# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2014 Canonical
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

from autopilot.matchers import Eventually
from autopilot.platform import model

from testtools.matchers import Equals


class TestContentPick(StartOpenRemotePageTestCaseBase):

    def test_picker_dialog_shows_up(self):
        url = self.base_url + "/uploadform"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        if model() == "Desktop":
            dialog = self.app.wait_select_single("QFileDialog")
        else:
            dialog = self.main_window.get_content_picker_dialog()
        self.assertThat(dialog.visible, Eventually(Equals(True)))

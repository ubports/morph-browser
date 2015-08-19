# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2014-2015 Canonical
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

import unittest


class TestContentPick(StartOpenRemotePageTestCaseBase):

    def setUp(self):
        super(TestContentPick, self).setUp(path="/uploadform")

    @unittest.skipIf(model() == "Desktop", "on devices only")
    def test_picker_dialog_shows_up(self):
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        dialog = self.main_window.get_content_picker_dialog()
        self.assertThat(dialog.visible, Eventually(Equals(True)))

# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2016 Canonical
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

from autopilot.platform import model
import testtools
from testtools.matchers import Equals
import time

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


@testtools.skipIf(model() == "Desktop", "on devices only")
class TestTouchSelection(StartOpenRemotePageTestCaseBase):

    def setUp(self):
        super(TestTouchSelection, self).setUp(path="/super")

    def long_press_webview(self):
        webview = self.main_window.get_current_webview()
        chrome = self.main_window.chrome
        x = webview.globalRect.x + webview.globalRect.width // 2
        y = webview.globalRect.y + \
            (webview.globalRect.height + chrome.height) // 2
        self.pointing_device.move(x, y)
        self.pointing_device.press()
        time.sleep(1.5)
        self.pointing_device.release()
        return webview.wait_select_single(objectName="touchSelectionActions",
                                          visible=True)

    def test_touch_selection(self):
        actions = self.long_press_webview()
        buttons = actions.select_many(objectName="touchSelectionActionButton",
                                      visible=True)
        # "Select All" & "Copy"
        self.assertThat(len(buttons), Equals(2))

        webview = self.main_window.get_current_webview()
        handles = webview.select_many(objectName="touchSelectionHandle",
                                      visible=True)
        self.assertThat(len(handles), Equals(2))
        handles.sort(key=lambda handle: handle.globalRect.x)
        left = 0  # Oxide.TouchSelectionController.HandleOrientationLeft
        self.assertThat(handles[0].handleOrientation, Equals(left))
        right = 2  # Oxide.TouchSelectionController.HandleOrientationRight
        self.assertThat(handles[1].handleOrientation, Equals(right))

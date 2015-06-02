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

import time
from autopilot.platform import model
from autopilot.matchers import Eventually
from testtools.matchers import Equals, GreaterThan, LessThan

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestSelection(StartOpenRemotePageTestCaseBase):

    def setUp(self):
        self.url = self.base_url + "/selection"
        super(TestSelection, self).setUp()
        webview = self.main_window.get_current_webview()
        self.pointing_device.move_to_object(webview)
        if model() == 'Desktop':
            self.pointing_device.click(button=3)
        else:
            self.pointing_device.press()
            time.sleep(1.5)
            self.pointing_device.release()
        self.selection = self.main_window.get_selection()
        self.rectangle = self.selection.get_rectangle()
        self.assertThat(self.rectangle.width, LessThan(webview.width))
        self.assertThat(self.rectangle.height, LessThan(webview.height))
        self.actions = self.main_window.get_selection_actions()
        self.assertThat(len(self.actions.select_many("Empty")), Equals(1))

    def assert_selection_eventually_dismissed(self):
        self.actions.wait_until_destroyed()
        self.selection.wait_until_destroyed()

    def test_copy_selection(self):
        copy_action = self.actions.select_single("Empty")
        self.pointing_device.click_object(copy_action)
        self.assert_selection_eventually_dismissed()

    def test_cancel_selection(self):
        webview = self.main_window.get_current_webview()
        x = int((webview.globalRect.x + self.rectangle.globalRect.x) / 2)
        y = int(webview.globalRect.y + webview.globalRect.height / 2)
        self.pointing_device.move(x, y)
        self.pointing_device.click()
        self.assert_selection_eventually_dismissed()

    def test_resize_selection(self):
        webview = self.main_window.get_current_webview()
        rect = self.rectangle.globalRect

        # Grow selection to the right
        handle = self.selection.get_handle("rightHandle")
        x0 = handle.globalRect.x + int(handle.globalRect.width / 2)
        y0 = handle.globalRect.y + int(handle.globalRect.height / 2)
        x1 = int((x0 + webview.globalRect.x + webview.globalRect.width) / 2)
        y1 = y0
        self.pointing_device.drag(x0, y0, x1, y1)
        self.assertThat(self.rectangle.width,
                        Eventually(GreaterThan(rect.width)))
        self.assertThat(self.rectangle.height,
                        Eventually(GreaterThan(rect.height)))
        self.actions.wait_until_destroyed()
        self.actions = self.main_window.get_selection_actions()

        # Shrink selection from the bottom
        handle = self.selection.get_handle("bottomHandle")
        x0 = handle.globalRect.x + int(handle.globalRect.width / 2)
        y0 = handle.globalRect.y + int(handle.globalRect.height / 2)
        x1 = x0
        y1 = webview.globalRect.y + int(webview.globalRect.height * 0.6)
        self.pointing_device.drag(x0, y0, x1, y1)
        self.assertThat(self.rectangle.globalRect, Eventually(Equals(rect)))
        self.actions.wait_until_destroyed()
        self.actions = self.main_window.get_selection_actions()

    def test_navigating_discards_selection(self):
        self.main_window.go_to_url(self.base_url + "/test1")
        self.assert_selection_eventually_dismissed()

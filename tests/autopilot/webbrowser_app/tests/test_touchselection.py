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

from autopilot.matchers import Eventually
from autopilot.platform import model
import testtools
from testtools.matchers import Equals, MatchesAny
import time

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestTouchSelectionBase(StartOpenRemotePageTestCaseBase):

    def get_actions(self):
        webview = self.main_window.get_current_webview()
        return webview.select_single(objectName="touchSelectionActions")

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
        actions = self.get_actions()
        actions.visible.wait_for(True)
        return actions

    def get_visible_actions(self, actions):
        return actions.select_many(styleName="ToolbarButtonStyle",
                                   visible=True)

    def get_handles(self):
        webview = self.main_window.get_current_webview()
        handles = webview.select_many(objectName="touchSelectionHandle",
                                      visible=True)
        handles.sort(key=lambda handle: handle.globalRect.x)
        return handles


@testtools.skipIf(model() == "Desktop", "on devices only")
class TestTouchSelection(TestTouchSelectionBase):

    def setUp(self):
        super(TestTouchSelection, self).setUp(path="/super")

    def test_touch_selection(self):
        actions = self.long_press_webview()
        self.assertThat(len(self.get_visible_actions(actions)), Equals(2))
        actions.select_single(objectName="touchSelectionAction_selectall",
                              visible=True)
        actions.select_single(objectName="touchSelectionAction_copy",
                              visible=True)

        handles = self.get_handles()
        self.assertThat(len(handles), Equals(2))
        left = 0  # Oxide.TouchSelectionController.HandleOrientationLeft
        self.assertThat(handles[0].handleOrientation, Equals(left))
        right = 2  # Oxide.TouchSelectionController.HandleOrientationRight
        self.assertThat(handles[1].handleOrientation, Equals(right))


@testtools.skipIf(model() == "Desktop", "on devices only")
class TestTouchInsertion(TestTouchSelectionBase):

    def setUp(self):
        super(TestTouchInsertion, self).setUp(path="/textarea")

    def test_touch_insertion(self):
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        actions = self.get_actions()
        self.assertThat(actions.visible, Equals(False))
        handles = self.get_handles()
        self.assertThat(len(handles), Equals(1))
        handle = handles[0]
        center = 1  # Oxide.TouchSelectionController.HandleOrientationCenter
        self.assertThat(handle.handleOrientation, Equals(center))
        self.pointing_device.click_object(handle)
        self.assertThat(actions.visible, Eventually(Equals(True)))
        self.assertThat(len(self.get_visible_actions(actions)),
                        MatchesAny(Equals(1), Equals(2)))
        actions.select_single(objectName="touchSelectionAction_selectall",
                              visible=True)
        if len(self.get_visible_actions(actions)) == 2:
            actions.select_single(objectName="touchSelectionAction_paste",
                                  visible=True)
        self.pointing_device.click_object(handle)
        self.assertThat(actions.visible, Eventually(Equals(False)))


# TODO: add tests for selection resizing, and activation of the contextual
# actions (verifying the contents of the clipboard is a complex task).

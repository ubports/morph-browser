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

from testtools.matchers import Equals
from autopilot.matchers import Eventually
from time import sleep

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestMultipleWindows(StartOpenRemotePageTestCaseBase):

    def test_open_new_window(self):
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(1))
        self.open_new_window()
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(2))
        for window in windows:
            self.assertThat(window.incognito, Equals(False))

    def test_open_new_private_window(self):
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(1))
        self.open_new_private_window()
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(2))
        self.assertThat(len(self.app.get_windows(incognito=False)), Equals(1))
        self.assertThat(len(self.app.get_windows(incognito=True)), Equals(1))


class TestMultipleWindowsDrag(StartOpenRemotePageTestCaseBase):
    def setUp(self):
        super(TestMultipleWindowsDrag, self).setUp()

        if not self.main_window.wide:
            self.skipTest("Only on wide form factors")

    def drag_tab(self, tab, x2, y2):
        x1, y1 = self.get_object_center(tab)

        self.pointing_device.move(x1, y1)
        self.pointing_device.press()

        # Drag tab downwards first to ensure we activate tab dragging
        for i in range(100):
            self.pointing_device.move(x1, y1 + i)

        # Move to destination and release
        # pause at each point so we can what is happening
        sleep(0.25)
        self.pointing_device.move(x2, y2)
        sleep(0.25)
        self.pointing_device.release()
        sleep(0.25)

    def get_object_center(self, obj):
        x1, y1, width, height = obj.globalRect
        x1 += width // 2
        y1 += height // 2

        return x1, y1

    def get_tab_delegate(self, window, tabIndex):
        return window.chrome.get_tabs_bar().get_tab(tabIndex)

    def test_drag_tab_tabbar_nothing(self):
        '''test that dragging a tab out and in of tabbar is same'''
        window = self.app.get_windows()[0]

        # Drag tab down and then back into tab bar
        tab = self.get_tab_delegate(window, 0)
        x2, y2 = self.get_object_center(tab)

        self.drag_tab(tab, x2, y2)

        # Check we still have 1 window and 1 tab
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(1))
        self.assertThat(lambda: len(windows[0].get_webviews()),
                        Eventually(Equals(1)))

    def test_drag_tab_bottom_new_window(self):
        '''test with two tabs dragging one to the bottom opens a new window'''
        window = self.app.get_windows()[0]

        # Open a new tab and check we have two
        self.open_new_tab()
        self.assertThat(lambda: len(window.get_webviews()),
                        Eventually(Equals(2)))

        # Drag new tab to bottom part of window
        tab = self.get_tab_delegate(window, 1)
        x2, y2 = self.get_object_center(window)

        self.drag_tab(tab, x2, y2)

        # Check that a new window has been opened
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(2))
        self.assertThat(lambda: len(windows[0].get_webviews()),
                        Eventually(Equals(1)))
        self.assertThat(lambda: len(windows[1].get_webviews()),
                        Eventually(Equals(1)))

    def test_drag_tab_outside_new_window(self):
        '''test with two tabs dragging one to the bottom opens a new window'''
        window = self.app.get_windows()[0]

        # Open a new tab and check we have two
        self.open_new_tab()
        self.assertThat(lambda: len(window.get_webviews()),
                        Eventually(Equals(2)))

        # Drag new tab outside of window
        tab = self.get_tab_delegate(window, 1)
        x2, y2, width, height = window.globalRect

        if x2 > 20:
            x2 -= 20
        else:
            x2 += width + 20

        self.drag_tab(tab, x2, y2)

        # Check that a new window has been opened
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(2))
        self.assertThat(lambda: len(windows[0].get_webviews()),
                        Eventually(Equals(1)))
        self.assertThat(lambda: len(windows[1].get_webviews()),
                        Eventually(Equals(1)))

    def test_drag_tab_between_windows_move(self):
        '''test that dragging a tab from one window to another'''
        # Open a new tab and window
        self.open_new_tab()
        self.open_new_window()

        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(2))
        self.assertThat(lambda: len(windows[0].get_webviews()),
                        Eventually(Equals(2)))
        self.assertThat(lambda: len(windows[1].get_webviews()),
                        Eventually(Equals(1)))

        # Focus window 0
        self.pointing_device.click_object(windows[0])

        # Move tab into window 1
        tab = self.get_tab_delegate(windows[0], 1)
        x2, y2 = self.get_object_center(windows[1].chrome.get_tabs_bar())

        self.drag_tab(tab, x2, y2)

        # Check there are two windows and two tabs open in the second window
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(2))
        self.assertThat(lambda: len(windows[0].get_webviews()),
                        Eventually(Equals(1)))
        self.assertThat(lambda: len(windows[1].get_webviews()),
                        Eventually(Equals(2)))

    def test_drag_tab_between_windows_move_and_close_window(self):
        '''test that dragging tab from one window to another closes original'''
        self.open_new_window()
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(2))

        # Focus window 0
        self.pointing_device.click_object(windows[0])

        # Move tab into window 1
        tab = self.get_tab_delegate(windows[0], 0)
        x2, y2 = self.get_object_center(windows[1].chrome.get_tabs_bar())

        self.drag_tab(tab, x2, y2)

        # Check there are two tabs open in the single remaining window
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(1))
        self.assertThat(lambda: len(windows[0].get_webviews()),
                        Eventually(Equals(2)))

    def test_drag_public_tab_into_private_window(self):
        '''test that you cannot drag a public tab into private window'''
        # Open private window, check there are two windows
        self.open_new_private_window()
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(2))

        public_window = self.app.get_windows(incognito=False)[0]
        private_window = self.app.get_windows(incognito=True)[0]

        # Focus public window
        self.pointing_device.click_object(public_window)

        # Move tab into private window
        tab = self.get_tab_delegate(public_window, 0)
        x2, y2 = self.get_object_center(private_window)

        self.drag_tab(tab, x2, y2)

        # Check there are two windows, one of public and one private
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(2))
        self.assertThat(len(self.app.get_windows(incognito=False)), Equals(1))
        self.assertThat(len(self.app.get_windows(incognito=True)), Equals(1))

    def test_drag_private_tab_into_public_window(self):
        '''test that you cannot drag a private tab into public window'''
        # Open private window, check there are two windows
        self.open_new_private_window()
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(2))

        public_window = self.app.get_windows(incognito=False)[0]
        private_window = self.app.get_windows(incognito=True)[0]

        # Focus private window
        self.pointing_device.click_object(private_window)

        # Move tab into public window
        tab = self.get_tab_delegate(private_window, 0)
        x2, y2 = self.get_object_center(public_window)

        self.drag_tab(tab, x2, y2)

        # Check there are two windows, one of public and one private
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(2))
        self.assertThat(len(self.app.get_windows(incognito=False)), Equals(1))
        self.assertThat(len(self.app.get_windows(incognito=True)), Equals(1))

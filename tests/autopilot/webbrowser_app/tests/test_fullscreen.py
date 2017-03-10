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

import testtools
from testtools.matchers import Equals, LessThan
from autopilot.matchers import Eventually
from autopilot.platform import model


class TestFullscreenBase(StartOpenRemotePageTestCaseBase):

    # Ref: http://doc.qt.io/qt-5/qwindow.html#Visibility-enum
    QWINDOW_FULLSCREEN = 5

    def assert_webview_fullscreen(self, fullscreen):
        self.assertThat(self.main_window.get_current_webview().fullscreen,
                        Eventually(Equals(fullscreen)))

    def assert_window_fullscreen(self, fullscreen):
        if fullscreen:
            self.assertThat(self.main_window.get_window().visibility,
                            Eventually(Equals(self.QWINDOW_FULLSCREEN)))
        else:
            self.assertThat(self.main_window.get_window().visibility,
                            Eventually(LessThan(self.QWINDOW_FULLSCREEN)))


class TestPageInitiatedFullscreen(TestFullscreenBase):

    def setUp(self):
        super(TestPageInitiatedFullscreen, self).setUp(path="/fullscreen")
        self.assert_webview_fullscreen(False)
        self.assert_window_fullscreen(False)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        self.assert_webview_fullscreen(True)
        self.assert_window_fullscreen(True)

    def test_page_initiated_exit(self):
        webview = self.main_window.get_current_webview()
        hint = webview.wait_select_single(objectName="fullscreenExitHint")
        self.pointing_device.click_object(webview)
        self.assert_webview_fullscreen(False)
        self.assert_window_fullscreen(False)
        hint.wait_until_destroyed()

    @testtools.skipIf(model() == "Desktop", "on touch devices only")
    def test_user_exit_swipe_up(self):
        self.open_tabs_view()
        self.assert_webview_fullscreen(False)
        self.assert_window_fullscreen(False)

    @testtools.skipIf(model() != "Desktop", "on desktop only")
    def test_user_exit_ESC(self):
        self.main_window.press_key('Escape')
        self.assert_webview_fullscreen(False)
        self.assert_window_fullscreen(False)

    @testtools.skipIf(model() != "Desktop", "on desktop only")
    def test_user_exit_F11(self):
        self.main_window.press_key('F11')
        self.assert_webview_fullscreen(False)
        self.assert_window_fullscreen(False)


@testtools.skipIf(model() != "Desktop", "on desktop only")
class TestUserInitiatedFullscreen(TestFullscreenBase):

    def setUp(self):
        super(TestUserInitiatedFullscreen, self).setUp()
        self.assert_webview_fullscreen(False)
        self.assert_window_fullscreen(False)
        self.main_window.press_key('F11')
        self.assert_window_fullscreen(True)
        self.assert_webview_fullscreen(False)

    def test_user_exit_ESC(self):
        self.main_window.press_key('Escape')
        self.assert_window_fullscreen(False)
        self.assert_webview_fullscreen(False)

    def test_user_exit_F11(self):
        self.main_window.press_key('F11')
        self.assert_window_fullscreen(False)
        self.assert_webview_fullscreen(False)


@testtools.skipIf(model() != "Desktop", "on desktop only")
class TestUserThenPageInitiatedFullscreen(TestFullscreenBase):

    def setUp(self):
        super(TestUserThenPageInitiatedFullscreen, self).setUp(
            path="/fullscreen")
        self.assert_webview_fullscreen(False)
        self.assert_window_fullscreen(False)

        # user initiated fullscreen
        self.main_window.press_key('F11')
        self.assert_window_fullscreen(True)
        self.assert_webview_fullscreen(False)

        # page initiated fullscreen
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        self.assert_webview_fullscreen(True)
        self.assert_window_fullscreen(True)

    def test_user_exit_ESC(self):
        self.main_window.press_key('Escape')
        self.assert_webview_fullscreen(False)
        self.assert_window_fullscreen(False)

    def test_user_exit_F11(self):
        self.main_window.press_key('F11')
        self.assert_webview_fullscreen(False)
        self.assert_window_fullscreen(False)

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

"""webbrowser-app autopilot tests."""

import os
import shutil
import urllib.request

from testtools.matchers import Contains, Equals

from autopilot.matchers import Eventually
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase

from . import http_server

from ubuntuuitoolkit import emulators as toolkit_emulators

from webbrowser_app.emulators.browser import Browser


class BrowserTestCaseBase(AutopilotTestCase):

    """
    A common test case class that provides several useful methods
    for webbrowser-app tests.
    """

    local_location = "../../src/app/webbrowser/webbrowser-app"
    d_f = "--desktop_file_hint=/usr/share/applications/webbrowser-app.desktop"

    ARGS = []

    def setUp(self):
        self.pointing_device = toolkit_emulators.get_pointing_device()
        super(BrowserTestCaseBase, self).setUp()
        if os.path.exists(self.local_location):
            self.launch_test_local()
        else:
            self.launch_test_installed()
        self.main_window.visible.wait_for(True)

    def launch_test_local(self):
        self.app = self.launch_test_application(
            self.local_location,
            *self.ARGS,
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def launch_test_installed(self):
        if model() == 'Desktop':
            self.app = self.launch_test_application(
                "webbrowser-app",
                *self.ARGS,
                emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)
        else:
            self.app = self.launch_test_application(
                "webbrowser-app",
                self.d_f,
                *self.ARGS,
                app_type='qt',
                emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def clear_cache(self):
        cachedir = os.path.join(os.path.expanduser("~"), ".local", "share",
                                "webbrowser-app")
        shutil.rmtree(cachedir, True)
        os.makedirs(cachedir)

    @property
    def main_window(self):
        return self.app.select_single(Browser)

    def assert_osk_eventually_shown(self):
        if model() != 'Desktop':
            keyboardRectangle = self.main_window.get_keyboard_rectangle()
            self.assertThat(keyboardRectangle.state,
                            Eventually(Equals("shown")))

    def assert_osk_eventually_hidden(self):
        if model() != 'Desktop':
            keyboardRectangle = self.main_window.get_keyboard_rectangle()
            self.assertThat(keyboardRectangle.state,
                            Eventually(Equals("hidden")))

    def assert_chrome_eventually_shown(self):
        toolbar = self.main_window.get_toolbar()
        self.assertThat(toolbar.opened, Eventually(Equals(True)))
        self.assertThat(toolbar.animating, Eventually(Equals(False)))

    def assert_chrome_eventually_hidden(self):
        toolbar = self.main_window.get_toolbar()
        self.assertThat(toolbar.opened, Eventually(Equals(False)))
        self.assertThat(toolbar.animating, Eventually(Equals(False)))

    def ensure_chrome_is_hidden(self):
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        self.assert_chrome_eventually_hidden()
        self.assert_osk_eventually_hidden()

    def focus_address_bar(self):
        address_bar = self.main_window.get_address_bar()
        self.pointing_device.click_object(address_bar)
        self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))
        self.assert_osk_eventually_shown()

    def clear_address_bar(self):
        self.focus_address_bar()
        self.assert_osk_eventually_shown()
        clear_button = self.main_window.get_address_bar_clear_button()
        self.pointing_device.click_object(clear_button)
        text_field = self.main_window.get_address_bar_text_field()
        self.assertThat(text_field.text, Eventually(Equals("")))

    def type_in_address_bar(self, text):
        address_bar = self.main_window.get_address_bar()
        self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))
        self.keyboard.type(text)
        text_field = self.main_window.get_address_bar_text_field()
        self.assertThat(text_field.text, Eventually(Contains(text)))

    def go_to_url(self, url):
        self.ensure_chrome_is_hidden()
        self.main_window.open_toolbar()
        self.clear_address_bar()
        self.type_in_address_bar(url)
        self.keyboard.press_and_release("Enter")
        self.assert_osk_eventually_hidden()

    def assert_page_eventually_loading(self):
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.loading, Eventually(Equals(True)))

    def assert_page_eventually_loaded(self, url):
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.url, Eventually(Equals(url)))
        # loadProgress == 100 ensures that a page has actually loaded
        self.assertThat(webview.loadProgress,
                        Eventually(Equals(100), timeout=20))
        self.assertThat(webview.loading, Eventually(Equals(False)))

    def assert_activity_view_eventually_hidden(self):
        self.assertThat(self.main_window.get_many_activity_view,
                        Eventually(Equals([])))

    def ensure_activity_view_visible(self):
        self.ensure_chrome_is_hidden()
        self.main_window.open_toolbar().click_button("activityButton")
        self.main_window.get_activity_view()
        self.assertThat(self.main_window.get_visible_webviews(), Equals([]))

    def ping_server(self):
        ping = urllib.request.urlopen(self.base_url + "/ping")
        self.assertThat(ping.read(), Equals(b"pong"))

    def assert_new_tab_view_eventually_visible(self):
        new_tab_view = self.main_window.get_new_tab_view()
        self.assertThat(new_tab_view.visible, Eventually(Equals(True)))

    def assert_new_tab_view_eventually_hidden(self):
        self.assertThat(self.main_window.get_many_new_tab_view,
                        Eventually(Equals([])))


class StartOpenRemotePageTestCaseBase(BrowserTestCaseBase):

    """
    Helper test class that opens the browser at a remote URL instead of
    defaulting to the homepage.

    This class should be preferred to the base test case class, as it doesn’t
    rely on a connection to the outside world (to open the default homepage),
    and because it ensures the initial page is fully loaded before the tests
    are executed, thus making them more robust.
    """

    def setUp(self):
        self.server = http_server.HTTPServerInAThread()
        self.addCleanup(self.server.cleanup)
        self.base_url = "http://localhost:{}".format(self.server.port)
        self.ping_server()
        self.url = self.base_url + "/loremipsum"
        self.ARGS = [self.url]
        super(StartOpenRemotePageTestCaseBase, self).setUp()
        self.assert_home_page_eventually_loaded()

    def assert_home_page_eventually_loaded(self):
        self.assert_page_eventually_loaded(self.url)

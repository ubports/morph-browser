# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2013-2014 Canonical
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

from testtools.matchers import Equals

from autopilot.matchers import Eventually
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase

from . import http_server

import ubuntuuitoolkit as uitk

from webbrowser_app.emulators import browser


class BrowserTestCaseBase(AutopilotTestCase):

    """
    A common test case class that provides several useful methods
    for webbrowser-app tests.
    """

    local_location = "../../src/app/webbrowser/webbrowser-app"
    d_f = "--desktop_file_hint=/usr/share/applications/webbrowser-app.desktop"

    ARGS = ["--new-session"]

    def setUp(self):
        self.pointing_device = uitk.get_pointing_device()
        super(BrowserTestCaseBase, self).setUp()
        self.app = self.launch_app()

    def launch_app(self):
        if os.path.exists(self.local_location):
            return self.launch_test_local()
        else:
            return self.launch_test_installed()
        self.main_window.visible.wait_for(True)

    def launch_test_local(self):
        return self.launch_test_application(
            self.local_location,
            *self.ARGS,
            emulator_base=browser.Webbrowser)

    def launch_test_installed(self):
        if model() == 'Desktop':
            return self.launch_test_application(
                "webbrowser-app",
                *self.ARGS,
                emulator_base=browser.Webbrowser)
        else:
            return self.launch_test_application(
                "webbrowser-app",
                self.d_f,
                *self.ARGS,
                app_type='qt',
                emulator_base=browser.Webbrowser)

    def clear_cache(self):
        cachedir = os.path.join(os.path.expanduser("~"), ".local", "share",
                                "webbrowser-app")
        shutil.rmtree(cachedir, True)
        os.makedirs(cachedir)

    @property
    def main_window(self):
        return self.app.main_window

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

    def open_tabs_view(self):
        chrome = self.main_window.chrome
        drawer_button = chrome.get_drawer_button()
        self.pointing_device.click_object(drawer_button)
        chrome.get_drawer()
        tabs_action = chrome.get_drawer_action("tabs")
        self.pointing_device.click_object(tabs_action)
        self.main_window.get_tabs_view()

    def open_new_tab(self):
        count = len(self.main_window.get_webviews())
        # assumes the tabs view is already open
        tabs_view = self.main_window.get_tabs_view()
        add_button = tabs_view.get_add_button()
        self.pointing_device.click_object(add_button)
        tabs_view.wait_until_destroyed()
        max_webviews = self.main_window.maxLiveWebviews
        new_count = (count + 1) if (count < max_webviews) else max_webviews
        self.assert_number_webviews_eventually(new_count)
        self.main_window.get_new_tab_view()
        if model() == 'Desktop':
            self.assertThat(
                self.main_window.address_bar.activeFocus,
                Eventually(Equals(True)))

    def assert_number_webviews_eventually(self, count):
        self.assertThat(lambda: len(self.main_window.get_webviews()),
                        Eventually(Equals(count)))

    def ping_server(self):
        ping = urllib.request.urlopen(self.base_url + "/ping")
        self.assertThat(ping.read(), Equals(b"pong"))


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
        self.domain = "localhost"
        self.ping_server()
        self.url = self.base_url + "/test1"
        self.ARGS = self.ARGS + [self.url]
        super(StartOpenRemotePageTestCaseBase, self).setUp()
        self.assert_home_page_eventually_loaded()

    def assert_home_page_eventually_loaded(self):
        self.assert_page_eventually_loaded(self.url)

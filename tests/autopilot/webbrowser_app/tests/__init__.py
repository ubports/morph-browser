# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2013-2015 Canonical
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
import tempfile
import urllib.request

import fixtures
from testtools.matchers import Equals, NotEquals

from autopilot.matchers import Eventually
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase

from . import http_server

import ubuntuuitoolkit as uitk


class BrowserTestCaseBase(AutopilotTestCase):

    """
    A common test case class that provides several useful methods
    for webbrowser-app tests.
    """

    local_location = "../../src/app/webbrowser/webbrowser-app"
    d_f = "--desktop_file_hint=/usr/share/applications/webbrowser-app.desktop"

    ARGS = ["--new-session"]

    def create_temporary_profile(self):
        # This method is meant to be called exactly once, in setUp().
        # Tests that need to pre-populate the profile may call it earlier.
        if hasattr(self, '_temp_xdg_dir'):
            return
        self._temp_xdg_dir = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self._temp_xdg_dir)

        appname = 'webbrowser-app'

        xdg_data = os.path.join(self._temp_xdg_dir, 'data')
        self.useFixture(fixtures.EnvironmentVariable(
            'XDG_DATA_HOME',
            xdg_data))
        self.data_location = os.path.join(xdg_data, appname)
        if not os.path.exists(self.data_location):
            os.makedirs(self.data_location)

        xdg_config = os.path.join(self._temp_xdg_dir, 'config')
        self.useFixture(fixtures.EnvironmentVariable(
            'XDG_CONFIG_HOME',
            xdg_config))
        self.config_location = os.path.join(xdg_config, appname)
        if not os.path.exists(self.config_location):
            os.makedirs(self.config_location)

        xdg_cache = os.path.join(self._temp_xdg_dir, 'cache')
        self.useFixture(fixtures.EnvironmentVariable(
            'XDG_CACHE_HOME',
            xdg_cache))
        self.cache_location = os.path.join(xdg_cache, appname)
        if not os.path.exists(self.cache_location):
            os.makedirs(self.cache_location)

    def setUp(self):
        self.create_temporary_profile()
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
            emulator_base=uitk.UbuntuUIToolkitCustomProxyObjectBase)

    def launch_test_installed(self):
        if model() == 'Desktop':
            return self.launch_test_application(
                "webbrowser-app",
                *self.ARGS,
                emulator_base=uitk.UbuntuUIToolkitCustomProxyObjectBase)
        else:
            return self.launch_test_application(
                "webbrowser-app",
                self.d_f,
                *self.ARGS,
                app_type='qt',
                emulator_base=uitk.UbuntuUIToolkitCustomProxyObjectBase)

    @property
    def main_window(self):
        return self.app.main_window

    def drag_bottom_edge_upwards(self, fraction):
        self.assertThat(model(), NotEquals('Desktop'))
        hint = self.main_window.get_bottom_edge_hint()
        x = hint.globalRect.x + hint.globalRect.width // 2
        y0 = hint.globalRect.y + hint.globalRect.height // 2
        y1 = y0 - int(self.main_window.height * fraction)
        self.pointing_device.drag(x, y0, x, y1)

    def open_tabs_view(self):
        if model() == 'Desktop':
            chrome = self.main_window.chrome
            drawer_button = chrome.get_drawer_button()
            self.pointing_device.click_object(drawer_button)
            chrome.get_drawer()
            tabs_action = chrome.get_drawer_action("tabs")
            self.pointing_device.click_object(tabs_action)
        else:
            self.drag_bottom_edge_upwards(0.75)
        self.main_window.get_tabs_view()

    def open_new_tab(self, incognito=False):
        if (incognito):
            count = len(self.main_window.get_incognito_webviews())
        else:
            count = len(self.main_window.get_webviews())

        # assumes the tabs view is already open
        tabs_view = self.main_window.get_tabs_view()
        self.main_window.get_recent_view_toolbar().click_action("newTabButton")
        tabs_view.visible.wait_for(False)
        max_webviews = self.main_window.maxLiveWebviews
        new_count = (count + 1) if (count < max_webviews) else max_webviews
        if (incognito):
            self.assert_number_incognito_webviews_eventually(new_count)
            new_tab_view = self.main_window.get_new_private_tab_view()
        else:
            self.assert_number_webviews_eventually(new_count)
            new_tab_view = self.main_window.get_new_tab_view()
        if model() == 'Desktop':
            self.assertThat(
                self.main_window.address_bar.activeFocus,
                Eventually(Equals(True)))
        return new_tab_view

    def open_settings(self):
        chrome = self.main_window.chrome
        drawer_button = chrome.get_drawer_button()
        self.pointing_device.click_object(drawer_button)
        chrome.get_drawer()
        settings_action = chrome.get_drawer_action("settings")
        self.pointing_device.click_object(settings_action)
        return self.main_window.get_settings_page()

    def assert_number_webviews_eventually(self, count):
        self.assertThat(lambda: len(self.main_window.get_webviews()),
                        Eventually(Equals(count)))

    def assert_number_incognito_webviews_eventually(self, count):
        self.assertThat(lambda: len(self.main_window.get_incognito_webviews()),
                        Eventually(Equals(count)))

    def ping_server(self, server):
        url = "http://localhost:{}/ping".format(server.port)
        ping = urllib.request.urlopen(url)
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
        self.http_server = http_server.HTTPServerInAThread()
        self.ping_server(self.http_server)
        self.addCleanup(self.http_server.cleanup)
        self.useFixture(fixtures.EnvironmentVariable(
            'UBUNTU_WEBVIEW_HOST_MAPPING_RULES',
            "MAP test:80 localhost:{}".format(self.http_server.port)))
        self.base_url = "http://test"
        self.url = self.base_url + "/test1"
        self.ARGS = self.ARGS + [self.url]
        super(StartOpenRemotePageTestCaseBase, self).setUp()
        self.assert_home_page_eventually_loaded()

    def assert_home_page_eventually_loaded(self):
        self.main_window.wait_until_page_loaded(self.url)

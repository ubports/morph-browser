# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
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

""" Autopilot tests for the webapp_container package """

import os
import subprocess

import fixtures
from autopilot.testcase import AutopilotTestCase
from autopilot.platform import model
from testtools.matchers import Equals, GreaterThan
from autopilot.matchers import Eventually

import ubuntuuitoolkit as uitk
from webapp_container.tests import fake_servers

BASE_FILE_PATH = os.path.dirname(os.path.realpath(__file__))
CONTAINER_EXEC_REL_PATH = '../../../../src/app/webcontainer/webapp-container'
INSTALLED_BROWSER_CONTAINER_PATH_NAME = 'webapp-container'
try:
    INSTALLED_BROWSER_CONTAINER_PATH_NAME = subprocess.check_output(
        ['which', 'webapp-container']).strip()
except subprocess.CalledProcessError:
    pass

LOCAL_BROWSER_CONTAINER_PATH_NAME = \
    os.path.join(BASE_FILE_PATH, CONTAINER_EXEC_REL_PATH)


class WebappContainerTestCaseBase(AutopilotTestCase):
    def setUp(self):
        self.pointing_device = uitk.get_pointing_device()
        super(WebappContainerTestCaseBase, self).setUp()

    def get_webcontainer_app_path(self):
        if os.path.exists(LOCAL_BROWSER_CONTAINER_PATH_NAME):
            return LOCAL_BROWSER_CONTAINER_PATH_NAME
        return INSTALLED_BROWSER_CONTAINER_PATH_NAME

    def launch_webcontainer_app(self, args, envvars={}):
        if model() != 'Desktop':
            args.append(
                '--desktop_file_hint=/usr/share/applications/'
                'webbrowser-app.desktop')
        if envvars:
            for envvar_key in envvars:
                self.useFixture(fixtures.EnvironmentVariable(
                    envvar_key, envvars[envvar_key]))

        try:
            self.app = self.launch_test_application(
                self.get_webcontainer_app_path(),
                *args,
                emulator_base=uitk.UbuntuUIToolkitCustomProxyObjectBase)
        except:
            self.app = None

    def get_webcontainer_proxy(self):
        return self.app

    def get_webcontainer_window(self):
        return self.app.select_single(objectName="webappContainer")

    def get_webcontainer_webview(self):
        return self.app.select_single(objectName="webappBrowserView")

    def get_webcontainer_chrome_button(self, name):
        return self.app.select_single(objectName=name)

    def get_webcontainer_chrome(self):
        return self.app.select_single("Chrome")

    def get_webview(self):
        return self.app.select_single(objectName="webview")

    def get_oxide_webview(self):
        container = self.get_webview().select_single(
            objectName='containerWebviewLoader')
        return container.wait_select_single('WebViewImplOxide')

    def assert_page_eventually_loaded(self, url):
        webview = self.get_oxide_webview()
        self.assertThat(webview.url, Eventually(Equals(url)))
        # loadProgress == 100 ensures that a page has actually loaded
        self.assertThat(webview.loadProgress,
                        Eventually(Equals(100), timeout=20))
        self.assertThat(webview.loading, Eventually(Equals(False)))

    def get_intent_filtered_uri(self, uri):
        webviewContainer = self.get_webcontainer_window()
        watcher = webviewContainer.watch_signal(
            'intentUriHandleResult(QString)')
        previous = watcher.num_emissions
        webviewContainer.slots.handleIntentUri(uri)
        self.assertThat(
            lambda: watcher.num_emissions,
            Eventually(GreaterThan(previous)))
        result = webviewContainer.get_signal_emissions(
            'intentUriHandleResult(QString)')[-1][0]
        return result

    def browse_to(self, url):
        webview = self.get_oxide_webview()
        webview.url = url
        self.assert_page_eventually_loaded(url)


class WebappContainerTestCaseWithLocalContentBase(WebappContainerTestCaseBase):
    BASE_URL_SCHEME = 'http://'

    def setUp(self):
        super(WebappContainerTestCaseWithLocalContentBase, self).setUp()
        self.http_server = fake_servers.WebappContainerContentHttpServer()
        self.addCleanup(self.http_server.shutdown)
        self.base_url = "{}localhost:{}".format(
            self.BASE_URL_SCHEME, self.http_server.port)

    def get_base_url_hostname(self):
        return self.base_url[len(self.BASE_URL_SCHEME):]

    def launch_webcontainer_app_with_local_http_server(
            self, args, path='/', envvars={}, homepage=''):
        self.url = self.base_url + path
        if len(homepage) != 0:
            self.url = homepage
        args.append(self.url)
        self.launch_webcontainer_app(args, envvars)

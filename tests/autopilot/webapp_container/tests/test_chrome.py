# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2014 Canonical
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

from testtools.matchers import Equals, GreaterThan
from autopilot.matchers import Eventually

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase


class WebappContainerChromeSetupTestCase(
        WebappContainerTestCaseWithLocalContentBase):

    def test_default_to_chromeless(self):
        self.launch_webcontainer_app_with_local_http_server([])
        self.assertIsNotNone(self.get_webcontainer_proxy())
        webview = self.get_webcontainer_webview()
        self.assertThat(webview.chromeless, Equals(True))

    def test_enable_chrome_back_forward(self):
        args = ['--enable-back-forward']
        self.launch_webcontainer_app_with_local_http_server(args)
        webview = self.get_webcontainer_webview()
        self.assertThat(webview.chromeless, Equals(False))
        chrome = self.get_webcontainer_chrome()
        self.assertThat(chrome.navigationButtonsVisible, Equals(True))
        self.assertThat(
            self.get_webcontainer_chrome_button("reloadButton").visible,
            Equals(True))
        self.assertThat(
            self.get_webcontainer_chrome_button("backButton").visible,
            Equals(True))

    def test_enable_chrome_address_bar(self):
        args = ['--enable-addressbar']
        self.launch_webcontainer_app_with_local_http_server(args)
        self.assertIsNotNone(self.get_webcontainer_proxy())
        webview = self.get_webcontainer_webview()
        self.assertThat(webview.chromeless, Equals(False))

    def test_reload(self):
        args = ['--enable-back-forward']
        self.launch_webcontainer_app_with_local_http_server(args)
        self.get_webcontainer_window().visible.wait_for(True)

        self.assert_page_eventually_loaded(self.url)

        container_view = self.get_webcontainer_webview()
        self.assertThat(container_view.chromeless, Equals(False))

        reload_button = self.get_webcontainer_chrome_button("reloadButton")
        self.assertThat(reload_button.visible, Equals(True))

        webview = self.get_oxide_webview()
        watcher = webview.watch_signal('loadingStateChanged()')

        previous = watcher.num_emissions
        self.pointing_device.click_object(reload_button)
        self.assertThat(
            lambda: watcher.num_emissions,
            Eventually(GreaterThan(previous)))

        self.assertThat(webview.loading, Eventually(Equals(False)))

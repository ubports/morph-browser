# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2014-2016 Canonical
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

import testtools

from testtools.matchers import Equals, GreaterThan
from autopilot.matchers import Eventually
from autopilot.platform import model

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
            self.app.select_single(objectName="reloadButton").visible,
            Equals(True))
        self.assertThat(
            self.app.select_single(objectName="backButton").visible,
            Equals(True))

    def test_enable_chrome_address_bar(self):
        args = ['--enable-addressbar']
        self.launch_webcontainer_app_with_local_http_server(args)
        self.assertIsNotNone(self.get_webcontainer_proxy())
        webview = self.get_webcontainer_webview()
        self.assertThat(webview.chromeless, Equals(False))

    def press_key(self, key):
        self.keyboard.press_and_release(key)

    @testtools.skipIf(model() != "Desktop", "on desktop only")
    def test_shortcut_backforward(self):
        args = [""]
        self.launch_webcontainer_app_with_local_http_server(args)
        self.get_webcontainer_window().visible.wait_for(True)

        webview = self.get_oxide_webview()
        webview.watch_signal('loadingStateChanged()')

        previous = self.get_oxide_webview().url
        url2 = self.base_url + "/test2"
        self.browse_to(url2)

        self.press_key("Alt+Left")
        self.assertThat(lambda: self.get_oxide_webview().url,
                        Eventually(Equals(previous)))

        self.press_key("Alt+Right")
        self.assertThat(lambda: self.get_oxide_webview().url,
                        Eventually(Equals(url2)))

    @testtools.skipIf(model() != "Desktop", "on desktop only")
    def test_shortcut_reload(self):
        args = ['']
        self.launch_webcontainer_app_with_local_http_server(args)
        self.get_webcontainer_window().visible.wait_for(True)
        self.assert_page_eventually_loaded(self.url)

        webview = self.get_oxide_webview()
        watcher = webview.watch_signal('loadingStateChanged()')

        previous = watcher.num_emissions
        self.press_key('Ctrl+r')
        self.assertThat(
            lambda: watcher.num_emissions,
            Eventually(GreaterThan(previous)))

        self.assertThat(webview.loading, Eventually(Equals(False)))

        previous = watcher.num_emissions
        self.press_key('F5')
        self.assertThat(
            lambda: watcher.num_emissions,
            Eventually(GreaterThan(previous)))

        self.assertThat(webview.loading, Eventually(Equals(False)))

    def test_reload(self):
        args = ['--enable-back-forward']
        self.launch_webcontainer_app_with_local_http_server(args)
        self.get_webcontainer_window().visible.wait_for(True)

        self.assert_page_eventually_loaded(self.url)

        container_view = self.get_webcontainer_webview()
        self.assertThat(container_view.chromeless, Equals(False))

        reload_button = self.app.select_single(objectName="reloadButton")
        self.assertThat(reload_button.visible, Equals(True))

        webview = self.get_oxide_webview()
        watcher = webview.watch_signal('loadingStateChanged()')

        previous = watcher.num_emissions
        self.pointing_device.click_object(reload_button)
        self.assertThat(
            lambda: watcher.num_emissions,
            Eventually(GreaterThan(previous)))

        self.assertThat(webview.loading, Eventually(Equals(False)))

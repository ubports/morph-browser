# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2015 Canonical
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

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase

from testtools.matchers import Equals
from autopilot.matchers import Eventually


class TestPageMetaCollector(WebappContainerTestCaseWithLocalContentBase):
    def _click_webview(self):
        webview = self.get_oxide_webview()
        gr = webview.globalRect
        self.pointing_device.move(
            gr.x + gr.width/4,
            gr.y + gr.height/4)
        self.pointing_device.click()
        self.assert_page_eventually_loaded()

    def _click_theme_color_webview(self):
        webview = self.get_oxide_webview()
        gr = webview.globalRect
        self.pointing_device.move(
            gr.x + 3*gr.width/4,
            gr.y + 3*gr.height/4)
        self.pointing_device.click()
        self.assert_page_eventually_loaded()

    def _setup_back_forward_context(self, color_url_part):
        args = ['--enable-addressbar', '--enable-back-forward']
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/local-browse-link-chain/1?color_url_part={}'.format(
                color_url_part))
        self.get_webcontainer_window().visible.wait_for(True)

        self._click_webview()
        self._click_webview()

        self.pointing_device.click_object(
            self.app.select_single(
                objectName="backButton"))

    def _validate_chrome_component_color(self, fcolor, bcolor):
        text_component = self.app.wait_select_single(
            objectName="chromeTextLabel")
        self.assertThat(
            lambda: str(text_component.color),
            Eventually(Equals(fcolor)))

        component = self.app.wait_select_single(
            objectName="backButton")
        self.assertThat(
            lambda: str(component.iconColor),
            Eventually(Equals(fcolor)))

        component = self.app.wait_select_single(
            objectName="reloadButton")
        self.assertThat(
            lambda: str(component.iconColor),
            Eventually(Equals(fcolor)))

        chrome_base = self.app.wait_select_single(
            objectName="chromeBase")
        self.assertThat(
            lambda: str(chrome_base.backgroundColor),
            Eventually(Equals(bcolor)))

    def test_update_theme_color(self):
        import urllib.parse
        self._setup_back_forward_context(
            urllib.parse.quote("/theme-color/?color=red"))
        self._click_theme_color_webview()
        self._validate_chrome_component_color(
            "Color(255, 255, 255, 255)",
            "Color(255, 0, 0, 255)")

    def test_update_theme_color_with_manifest(self):
        import urllib.parse
        self._setup_back_forward_context(
            urllib.parse.quote("/theme-color/?manifest=true"))
        self._click_theme_color_webview()
        self._validate_chrome_component_color(
            "Color(255, 255, 255, 255)",
            "Color(255, 0, 0, 255)")

    def test_track_theme_color_live_updates(self):
        args = ['--enable-addressbar', '--enable-back-forward']
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/theme-color/?color=red&delaycolorupdate=black')
        self.get_webcontainer_window().visible.wait_for(True)

        chrome_base = self.app.wait_select_single(
            objectName="chromeBase")

        self.assertThat(
            lambda: str(chrome_base.backgroundColor),
            Eventually(Equals("Color(255, 0, 0, 255)")))

        self.assertThat(
            lambda: str(chrome_base.backgroundColor),
            Eventually(Equals("Color(0, 0, 0, 255)")))

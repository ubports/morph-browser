# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
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

import testtools

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase

from testtools.matchers import Equals, GreaterThan
from autopilot.matchers import Eventually


class TestMediaPermission(WebappContainerTestCaseWithLocalContentBase):
    def _click_window_open(self):
        webview = self.get_oxide_webview()
        gr = webview.globalRect
        self.pointing_device.move(
            gr.x + webview.width*3/4,
            gr.y + webview.height*3/4)
        self.pointing_device.click()

    @testtools.skip("Skipping due to the lack of HTTPS support in the "
                    "test suite, see https://launchpad.net/bugs/1505995")
    def test_access_media_from_main_view(self):
        args = []
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/media-access')
        self.get_webcontainer_window().visible.wait_for(True)

        self.app.wait_select_single(
            objectName="mediaAccessDialog")

    @testtools.skip("Skipping due to the lack of HTTPS support in the "
                    "test suite, see https://launchpad.net/bugs/1505995")
    def test_access_media_from_overlay(self):
        args = []
        overlay_link = "/with-overlay-link?path=media-access"
        self.launch_webcontainer_app_with_local_http_server(
            args,
            overlay_link)
        self.get_webcontainer_window().visible.wait_for(True)

        popup_controller = self.get_popup_controller()
        animation_watcher = popup_controller.watch_signal(
            'windowOverlayOpenAnimationDone()')
        animation_signal_emission = animation_watcher.num_emissions

        self._click_window_open()

        self.assertThat(
            lambda: len(self.get_popup_overlay_views()),
            Eventually(Equals(1)))
        self.assertThat(
            lambda: animation_watcher.num_emissions,
            Eventually(GreaterThan(animation_signal_emission)))

        self.app.wait_select_single(
            objectName="mediaAccessDialog")

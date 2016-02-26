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

import signal

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase

from testtools.matchers import Equals, Contains, GreaterThan
from autopilot.matchers import Eventually


class TestOverlayRecovery(WebappContainerTestCaseWithLocalContentBase):
    def _click_href_target_blank(self):
        webview = self.get_oxide_webview()
        self.assertThat(webview.url, Contains('/open-close-content'))
        gr = webview.globalRect
        self.pointing_device.move(
            gr.x + gr.width/4,
            gr.y + gr.height/4)
        self.pointing_device.click()

    def _click_overlay(self):
        popup_controller = self.get_popup_controller()
        new_view_watcher = popup_controller.watch_signal(
            'newViewCreated(QString)')
        animation_watcher = popup_controller.watch_signal(
            'windowOverlayOpenAnimationDone()')
        animation_signal_emission = animation_watcher.num_emissions

        views = self.get_popup_overlay_views()
        self.assertThat(len(views), Equals(0))

        self._click_href_target_blank()

        self.assertThat(
            lambda: new_view_watcher.was_emitted,
            Eventually(Equals(True)))
        self.assertThat(
            lambda: len(self.get_popup_overlay_views()),
            Eventually(Equals(1)))
        views = self.get_popup_overlay_views()
        overlay = views[0]
        self.assertThat(
            overlay.select_single(objectName="overlayWebview").url,
            Contains('/open-close-content'))

        self.assertThat(
            lambda: animation_watcher.num_emissions,
            Eventually(GreaterThan(animation_signal_emission)))

    def test_crash_app_overlay_reloaded(self):
        args = []
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/open-close-content')
        self.get_webcontainer_window().visible.wait_for(True)

        self._click_overlay()
        self.assertThat(
            lambda: len(self.get_popup_overlay_views()),
            Eventually(Equals(1)))

        self.kill_app(signal.SIGABRT)

        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/open-close-content')
        self.get_webcontainer_window().visible.wait_for(True)

        self.assertThat(
            lambda: len(self.get_popup_overlay_views()),
            Eventually(Equals(1)))

        views = self.get_popup_overlay_views()
        overlay = views[0]
        self.assertThat(
            lambda: overlay.wait_select_single(
                objectName="overlayWebview").url,
            Eventually(Contains('/open-close-content')))

    def test_crash_app_closed_overlay_not_reloaded(self):
        args = []
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/open-close-content')
        self.get_webcontainer_window().visible.wait_for(True)

        self._click_overlay()
        self.assertThat(
            lambda: len(self.get_popup_overlay_views()),
            Eventually(Equals(1)))

        views = self.get_popup_overlay_views()
        overlay = views[0]
        closeButton = overlay.select_single(
            objectName='overlayCloseButton')
        self.pointing_device.click_object(closeButton)

        self.assertThat(
            lambda: len(self.get_popup_overlay_views()),
            Eventually(Equals(0)))

        self.kill_app(signal.SIGABRT)

        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/open-close-content')
        self.get_webcontainer_window().visible.wait_for(True)

        self.assertThat(
            lambda: len(self.get_popup_overlay_views()),
            Eventually(Equals(0)))

    def test_closed_app_overlay_not_reloaded(self):
        args = []
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/open-close-content')
        self.get_webcontainer_window().visible.wait_for(True)

        self._click_overlay()
        self.assertThat(
            lambda: len(self.get_popup_overlay_views()),
            Eventually(Equals(1)))

        self.kill_app(signal.SIGTERM)

        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/open-close-content')
        self.get_webcontainer_window().visible.wait_for(True)

        self.assertThat(
            lambda: len(self.get_popup_overlay_views()),
            Eventually(Equals(0)))

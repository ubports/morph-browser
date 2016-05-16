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

from testtools.matchers import Equals, Contains, GreaterThan
from autopilot.matchers import Eventually

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase


class WebappContainerPopupWebViewOverlayTestCase(
        WebappContainerTestCaseWithLocalContentBase):

    def click_href_target_blank(self):
        webview = self.get_oxide_webview()
        self.assertThat(webview.url, Contains('/open-close-content'))
        gr = webview.globalRect
        self.pointing_device.move(
            gr.x + gr.width/4,
            gr.y + gr.height/4)
        self.pointing_device.click()

    def click_window_open(self):
        webview = self.get_oxide_webview()
        self.assertThat(webview.url.endswith('/open-close-content'))
        gr = webview.globalRect
        self.pointing_device.move(
            gr.x + webview.width*3/4,
            gr.y + webview.height*3/4)
        self.pointing_device.click()

    def test_open_close_back_to_mainview(self):
        args = []
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/open-close-content')
        self.get_webcontainer_window().visible.wait_for(True)

        popup_controller = self.get_popup_controller()
        new_view_watcher = popup_controller.watch_signal(
            'newViewCreated(QString)')
        animation_watcher = popup_controller.watch_signal(
            'windowOverlayOpenAnimationDone()')
        animation_signal_emission = animation_watcher.num_emissions

        views = self.get_popup_overlay_views()
        self.assertThat(len(views), Equals(0))

        self.click_href_target_blank()

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
        animation_signal_emission = animation_watcher.num_emissions

        closeButton = overlay.select_single(
            objectName='overlayCloseButton')

        self.pointing_device.click_object(closeButton)

        self.assertThat(
            lambda: len(self.get_popup_overlay_views()),
            Eventually(Equals(0)))

    def test_open_overlay_in_main_browser(self):
        args = []
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/open-close-content',
            {'WEBAPP_CONTAINER_BLOCK_OPEN_URL_EXTERNALLY': '1'})
        self.get_webcontainer_window().visible.wait_for(True)

        popup_controller = self.get_popup_controller()
        webview = self.get_oxide_webview()
        self.assertThat(
            lambda: webview.visible,
            Eventually(Equals(True)))
        external_open_watcher = popup_controller.watch_signal(
            'openExternalUrlTriggered(QString)')

        animation_watcher = popup_controller.watch_signal(
            'windowOverlayOpenAnimationDone()')
        animation_signal_emission = animation_watcher.num_emissions

        self.click_href_target_blank()

        self.assertThat(
            lambda: len(self.get_popup_overlay_views()),
            Eventually(Equals(1)))

        views = self.get_popup_overlay_views()
        overlay = views[0]

        self.assertThat(
            lambda: animation_watcher.num_emissions,
            Eventually(GreaterThan(animation_signal_emission)))
        animation_signal_emission = animation_watcher.num_emissions

        openInBrowserButton = overlay.select_single(
            objectName='overlayButtonOpenInBrowser')

        self.pointing_device.click_object(openInBrowserButton)

        self.assertThat(
            lambda: len(self.get_popup_overlay_views()),
            Eventually(Equals(0)))
        self.assertThat(
            lambda: external_open_watcher.was_emitted,
            Eventually(Equals(True)))
        self.assertThat(
            lambda: webview.visible,
            Eventually(Equals(True)))

    def test_max_overlay_count_reached(self):
        args = []
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/open-close-content',
            {'WEBAPP_CONTAINER_BLOCK_OPEN_URL_EXTERNALLY': '1'})
        self.get_webcontainer_window().visible.wait_for(True)

        popup_controller = self.get_popup_controller()
        webview = self.get_oxide_webview()
        self.assertThat(
            lambda: webview.visible,
            Eventually(Equals(True)))

        animation_watcher = popup_controller.watch_signal(
            'windowOverlayOpenAnimationDone()')
        animation_signal_emission = animation_watcher.num_emissions

        OVERLAY_MAX_COUNT = 3
        for i in range(0, OVERLAY_MAX_COUNT):
            self.click_href_target_blank()
            self.assertThat(
                lambda: animation_watcher.num_emissions,
                Eventually(GreaterThan(animation_signal_emission)))
            animation_signal_emission = animation_watcher.num_emissions

        external_open_watcher = popup_controller.watch_signal(
            'openExternalUrlTriggered(QString)')

        self.click_href_target_blank()

        self.assertThat(
            lambda: external_open_watcher.was_emitted,
            Eventually(Equals(True)))

    def test_multiple_window_open_from_webview(self):
        args = []
        overlay_opened_from_main_view_count = 3
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/timer-window-open-content?count={}'.format(
                overlay_opened_from_main_view_count),
            {'WEBAPP_CONTAINER_BLOCKER_DISABLED': '1'})
        self.get_webcontainer_window().visible.wait_for(True)

        webview = self.get_oxide_webview()
        self.assertThat(
            lambda: webview.visible,
            Eventually(Equals(True)))

        self.assertThat(
            lambda: len(self.get_popup_overlay_views()),
            Eventually(Equals(overlay_opened_from_main_view_count)))

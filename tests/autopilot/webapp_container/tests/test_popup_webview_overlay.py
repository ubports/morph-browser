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

from testtools.matchers import Equals, Contains
from autopilot.matchers import Eventually

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase


class WebappContainerPopupWebViewOverlayTestCase(
        WebappContainerTestCaseWithLocalContentBase):

    def click_href_target_blank(self):
        webview = self.get_oxide_webview()
        self.assertThat(webview.url, Contains('/open-close-content'))
        self.pointing_device.move(webview.width/2, webview.height/2)
        self.pointing_device.click()

    def click_window_open(self):
        webview = self.get_oxide_webview()
        self.assertThat(webview.url.endswith('/open-close-content'))
        self.pointing_device.move(webview.width*3/4, webview.height*3/4)
        self.pointing_device.click()

    def test_open_close_back_to_mainview(self):
        args = []
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/open-close-content',
            {'WEBAPP_CONTAINER_BLOCK_OPEN_URL_EXTERNALLY': '1'})
        self.get_webcontainer_window().visible.wait_for(True)

        webview = self.get_oxide_webview()
        external_open_watcher = webview.watch_signal(
            'openExternalUrlTriggered(QString)')

        views = self.get_popup_overlay_views()
        self.assertThat(len(views), Equals(0))

        self.click_href_target_blank()

        self.assertThat(
            lambda: external_open_watcher.was_emitted,
            Eventually(Equals(False)))
        self.assertThat(webview.visible, Equals(False))
        self.assertThat(
            lambda: len(self.get_popup_overlay_views()),
            Eventually(Equals(1)))
        views = self.get_popup_overlay_views()
        overlay = views[0]
        self.assertThat(
            overlay.select_single(objectName="webview").url,
            Contains('/open-close-content'))

        closeButton = overlay.select_single(
            objectName='overlayCloseButton')
        self.pointing_device.click_object(closeButton)
        self.assertThat(webview.visible, Equals(True))
        views = self.get_popup_overlay_views()
        self.assertThat(len(views), Equals(0))

    def test_open_in_main_browser(self):
        args = []
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/open-close-content',
            {'WEBAPP_CONTAINER_BLOCK_OPEN_URL_EXTERNALLY': '1'})
        self.get_webcontainer_window().visible.wait_for(True)

        controller = self.get_popup_controller()
        webview = self.get_oxide_webview()
        self.assertThat(
            lambda: webview.visible,
            Eventually(Equals(True)))
        external_open_watcher = controller.watch_signal(
            'openExternalUrlTriggered(QString)')

        self.click_href_target_blank()

        self.assertThat(
            lambda: len(self.get_popup_overlay_views()),
            Eventually(Equals(1)))

        self.assertThat(
            lambda: webview.visible,
            Eventually(Equals(False)))

        views = self.get_popup_overlay_views()
        overlay = views[0]
        openInBrowserButton = overlay.select_single(
            objectName='overlayButtonOpenInBrowser')
        self.pointing_device.click_object(openInBrowserButton)

        self.assertThat(
            lambda: webview.visible,
            Eventually(Equals(True)))
        views = self.get_popup_overlay_views()
        self.assertThat(len(views), Equals(0))
        self.assertThat(
            lambda: external_open_watcher.was_emitted,
            Eventually(Equals(True)))

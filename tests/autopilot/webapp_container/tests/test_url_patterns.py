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

from testtools.matchers import Equals, Contains
from autopilot.matchers import Eventually

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase


class WebappContainerUrlPatternsTestCase(
        WebappContainerTestCaseWithLocalContentBase):

    def test_pattern_with_external_url(self):
        args = ["--webappUrlPatterns=http://www.test.com/*"]
        rule = 'MAP *.test.com:80 ' + self.get_base_url_hostname()
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '',
            {'WEBAPP_CONTAINER_BLOCK_OPEN_URL_EXTERNALLY': '1',
                'UBUNTU_WEBVIEW_HOST_MAPPING_RULES': rule},
            "http://www.test.com/with-external-link")

        self.get_webcontainer_window().visible.wait_for(True)

        webview = self.get_oxide_webview()
        external_open_watcher = webview.watch_signal(
            'openExternalUrlTriggered(QString)')

        self.pointing_device.click_object(webview)

        self.assertThat(
            lambda: external_open_watcher.was_emitted,
            Eventually(Equals(True)))

    def test_pattern_with_external_url_in_overlay(self):
        args = ["--webappUrlPatterns=http://www.test.com/*",
                "--open-external-url-in-overlay"]
        rule = 'MAP *.test.com:80 ' + self.get_base_url_hostname()
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '',
            {'WEBAPP_CONTAINER_BLOCK_OPEN_URL_EXTERNALLY': '1',
                'UBUNTU_WEBVIEW_HOST_MAPPING_RULES': rule},
            "http://www.test.com/with-external-link")
        self.get_webcontainer_window().visible.wait_for(True)

        popup_controller = self.get_popup_controller()
        new_view_watcher = popup_controller.watch_signal(
            'newViewCreated(QString)')

        views = self.get_popup_overlay_views()
        self.assertThat(len(views), Equals(0))

        webview = self.get_oxide_webview()
        external_open_watcher = webview.watch_signal(
            'openExternalUrlTriggered(QString)')

        self.pointing_device.click_object(webview)

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
            Contains('ubuntu'))

        self.assertThat(
            external_open_watcher.was_emitted,
            Equals(False))

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


class WebappContainerSAMLUrlPatternsTestCase(
        WebappContainerTestCaseWithLocalContentBase):
    def test_saml_urls_added(self):
        rule = 'MAP *.test.com:80 ' + self.get_base_url_hostname()
        args = ["--webappUrlPatterns=\
http://www.test.com/saml/*,{}/saml/*".format(self.base_url)]

        expectedSamlRequestRedirectPatternsCount = 1
        samlRequestNavigationCount = 3
        target_path = '/saml/?\
loopcount={}'.format(str(samlRequestNavigationCount))

        self.launch_webcontainer_app_with_local_http_server(
            args,
            target_path,
            {'WEBAPP_CONTAINER_BLOCK_OPEN_URL_EXTERNALLY': '1',
                'UBUNTU_WEBVIEW_HOST_MAPPING_RULES': rule})
        self.get_webcontainer_window().visible.wait_for(True)
        self.assert_page_eventually_loaded(self.base_url+target_path)

        saml_url_navigations_detected_watcher = self.get_webview(
            ).watch_signal('samlRequestUrlPatternReceived(QString)')
        webcontainer_webview = self.get_webcontainer_webview()
        url_patterns_settings_watcher = webcontainer_webview.watch_signal(
            'generatedUrlPatternsChanged()')

        webview = self.get_oxide_webview()

        gr = webview.globalRect
        self.pointing_device.move(
            gr.x + webview.width*0.5,
            gr.y + webview.height*0.5)
        self.pointing_device.click()

        self.assertThat(
            lambda: url_patterns_settings_watcher.was_emitted,
            Eventually(Equals(True)))
        self.assertThat(
            lambda: url_patterns_settings_watcher.num_emissions,
            Eventually(Equals(expectedSamlRequestRedirectPatternsCount)))
        self.assertThat(
            lambda: saml_url_navigations_detected_watcher.num_emissions,
            Eventually(Equals(samlRequestNavigationCount+1)))

        saved_patterns = webcontainer_webview.generatedUrlPatterns

        self.assertThat(
            saved_patterns,
            Contains("\"https?://{}/*\"".format(self.get_base_url_hostname())))

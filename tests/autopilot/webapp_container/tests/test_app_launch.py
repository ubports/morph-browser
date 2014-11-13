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

from testtools.matchers import Equals
from autopilot.matchers import Eventually

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase


class WebappContainerAppLaunchTestCase(
        WebappContainerTestCaseWithLocalContentBase):

    def test_container_does_not_load_with_no_webapp_name_and_url(self):
        args = []
        self.launch_webcontainer_app(args)
        self.assertIsNone(self.get_webcontainer_proxy())

    def test_loads_with_url(self):
        args = ['--enable-addressbar']
        self.launch_webcontainer_app_with_local_http_server(args)
        window = self.get_webcontainer_window()
        self.assertThat(window.url, Eventually(Equals(self.url)))

    def test_local_app_with_webapps_model(self):
        args = ['--webappModelSearchPath=.', './index.html']
        self.launch_webcontainer_app(args,
            {'WEBAPP_CONTAINER_SHOULD_VALIDATE_CLI_URLS': '1'})
        self.assertIsNone(self.get_webcontainer_proxy())

    def test_local_app_with_webapp_name(self):
        args = ['--webapp=DEADBEEF', './index.html']
        self.launch_webcontainer_app(args,
            {'WEBAPP_CONTAINER_SHOULD_VALIDATE_CLI_URLS': '1'})
        self.assertIsNone(self.get_webcontainer_proxy())

    def test_local_app_with_urls_patterns(self):
        args = ['--webappUrlPatterns=https?://*.blabla.com/*', './index.html']
        self.launch_webcontainer_app(args,
            {'WEBAPP_CONTAINER_SHOULD_VALIDATE_CLI_URLS': '1'})
        self.assertIsNone(self.get_webcontainer_proxy())

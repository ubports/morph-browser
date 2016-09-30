# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2014-2015 Canonical
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

from contextlib import contextmanager
import os
import tempfile
import shutil

from testtools.matchers import Equals
from autopilot.matchers import Eventually

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase


@contextmanager
def generate_temp_webapp():
    tmpdir = tempfile.mkdtemp()
    webapp_folder_name = '{}/unity-webapps-test'.format(tmpdir)
    os.mkdir(webapp_folder_name)
    manifest_content = """
    {
        "includes": ["http://test.com:*/*"],
        "name": "test",
        "scripts": ["test.user.js"],
        "domain":"",
        "homepage":"http://www.test.com/"
    }
    """
    manifest_file = "{}/manifest.json".format(webapp_folder_name)
    with open(manifest_file, "w+") as f:
        f.write(manifest_content)
    script_file = "{}/test.user.js".format(webapp_folder_name)
    with open(script_file, "w+") as f:
        f.write("")
    try:
        yield tmpdir
    finally:
        shutil.rmtree(tmpdir)


class WebappContainerAppLaunchTestCase(
        WebappContainerTestCaseWithLocalContentBase):
    def test_container_does_not_load_with_no_webapp_name_and_url(self):
        args = []
        self.launch_webcontainer_app(args, {}, True)
        self.assertIsNone(self.get_webcontainer_proxy())

    def test_loads_with_url(self):
        args = ['--enable-addressbar']
        self.launch_webcontainer_app_with_local_http_server(args)
        window = self.get_webcontainer_window()
        self.assertThat(window.url, Eventually(Equals(self.url)))

    def test_local_app_with_webapps_model(self):
        args = ['--webappModelSearchPath=.', './index.html']
        self.launch_webcontainer_app(
            args,
            {'WEBAPP_CONTAINER_SHOULD_NOT_VALIDATE_CLI_URLS': '1'},
            True)
        self.assertIsNone(self.get_webcontainer_proxy())

    def test_local_app_with_webapp_name(self):
        args = ['--webapp=DEADBEEF', './index.html']
        self.launch_webcontainer_app(
            args,
            {'WEBAPP_CONTAINER_SHOULD_NOT_VALIDATE_CLI_URLS': '1'},
            True)
        self.assertIsNone(self.get_webcontainer_proxy())

    def test_local_app_with_urls_patterns(self):
        args = ['--webappUrlPatterns=https?://*.blabla.com/*', './index.html']
        self.launch_webcontainer_app(
            args,
            {'WEBAPP_CONTAINER_SHOULD_NOT_VALIDATE_CLI_URLS': '1'},
            True)
        self.assertIsNone(self.get_webcontainer_proxy())

    def test_webapps_launch_default_search_path(self):
        args = ["--webapp='dGVzdA=='"]
        rule = 'MAP *.test.com:80 ' + self.get_base_url_hostname()
        with generate_temp_webapp() as webapp_install_path:
            env_vars = {
                'UBUNTU_WEBVIEW_HOST_MAPPING_RULES': rule,
                'WEBAPP_QML_DEFAULT_WEBAPPS_INSTALL_FOLDER': (
                    webapp_install_path)
            }
            self.launch_webcontainer_app(args, env_vars)
            webview = self.get_oxide_webview()
            webapp_url = 'http://www.test.com/'
            self.assertThat(webview.url, Eventually(Equals(webapp_url)))

            result = 'test'
            self.assertThat(self.get_webcontainer_window().title,
                            Eventually(Equals(result)))

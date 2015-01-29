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

from contextlib import contextmanager
import os
import tempfile
import shutil

from testtools.matchers import Equals
from autopilot.matchers import Eventually

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase


@contextmanager
def generate_temp_local_props_webapp():
    tmpdir = tempfile.mkdtemp()
    webapp_folder_name = '{}/unity-webapps-test'.format(tmpdir)
    os.mkdir(webapp_folder_name)
    manifest_content = """
    {
        "includes": ["http://test.com:*/*"],
        "name": "test",
        "domain": "",
        "homepage": "http://www.test.com/show-user-agent",
        "user-agent-override": "MyUserAgent"
    }
    """
    manifest_file = "{}/webapp-properties.json".format(webapp_folder_name)
    with open(manifest_file, "w+") as f:
        f.write(manifest_content)
    try:
        yield webapp_folder_name
    finally:
        shutil.rmtree(tmpdir)


class WebappUserAgentTestCase(
        WebappContainerTestCaseWithLocalContentBase):

    def test_override_user_agent(self):
        args = ['--user-agent-string=MyUserAgent']
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/show-user-agent')
        self.get_webcontainer_window().visible.wait_for(True)

        # trick until we get e.g. selenium/chromedriver tests
        result = 'MyUserAgent MyUserAgent'
        self.assertThat(self.get_oxide_webview().title,
                        Eventually(Equals(result)))

    def test_webapp_properties_override(self):
        rule = 'MAP *.test.com:80 ' + self.get_base_url_hostname()
        with generate_temp_local_props_webapp() as webapp_install_path:
            args = ['--webappModelSearchPath=' + webapp_install_path]
            self.launch_webcontainer_app(
                args,
                {'UBUNTU_WEBVIEW_HOST_MAPPING_RULES': rule})
            self.get_webcontainer_window().visible.wait_for(True)

            webview = self.get_oxide_webview()
            webapp_url = 'http://www.test.com/show-user-agent'
            self.assertThat(webview.url, Eventually(Equals(webapp_url)))

            webapp_name = 'test'
            self.assertThat(self.get_webcontainer_window().title,
                            Eventually(Equals(webapp_name)))

            # trick until we get e.g. selenium/chromedriver tests
            result = 'MyUserAgent MyUserAgent'
            self.assertThat(self.get_oxide_webview().title,
                            Eventually(Equals(result)))

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

from contextlib import contextmanager
import os
import tempfile
import shutil

from testtools.matchers import Equals
from autopilot.matchers import Eventually

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase


@contextmanager
def generate_temp_webapp(manifest_filename='manifest.json'):
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
    manifest_file = "{}/{}".format(webapp_folder_name, manifest_filename)
    with open(manifest_file, "w+") as f:
        f.write(manifest_content)
    script_file = "{}/test.user.js".format(webapp_folder_name)
    with open(script_file, "w+") as f:
        f.write("")
    try:
        yield tmpdir
    finally:
        shutil.rmtree(tmpdir)


class WebappContainerWebappNamePrecedenceTestCase(
        WebappContainerTestCaseWithLocalContentBase):
    def test_webapps_launch_default_search_path(self):
        args = ["--webapp='dGVzdA=='"]
        rule = 'MAP *.test.com:80 ' + self.get_base_url_hostname()
        with generate_temp_webapp() as webapp_install_path:
            self.launch_webcontainer_app(
                args,
                {'UBUNTU_WEBVIEW_HOST_MAPPING_RULES': rule,
                 'WEBAPP_QML_DEFAULT_WEBAPPS_INSTALL_FOLDER':
                 webapp_install_path})
            webview = self.get_oxide_webview()
            webapp_url = 'http://www.test.com/'
            self.assertThat(webview.url, Eventually(Equals(webapp_url)))

            result = 'test'
            self.assertThat(self.get_webcontainer_window().title,
                            Eventually(Equals(result)))

    def test_webapps_launch_custom_search_path(self):
        args = []
        rule = 'MAP *.test.com:80 ' + self.get_base_url_hostname()
        with generate_temp_webapp('webapp-properties.json') as install_path:
            args.append('--webappModelSearchPath={}'.format(install_path))
            self.launch_webcontainer_app(
                args,
                {'UBUNTU_WEBVIEW_HOST_MAPPING_RULES': rule,
                 'WEBAPP_QML_DEFAULT_WEBAPPS_INSTALL_FOLDER':
                 install_path})
            webview = self.get_oxide_webview()
            webapp_url = 'http://www.test.com/'
            self.assertThat(webview.url, Eventually(Equals(webapp_url)))

            result = 'test'
            self.assertThat(self.get_webcontainer_window().title,
                            Eventually(Equals(result)))

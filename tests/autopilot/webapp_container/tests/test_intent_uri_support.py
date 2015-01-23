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
def generate_temp_webapp_with_intent(intent_filter_content=""):
    tmpdir = tempfile.mkdtemp()
    manifest_content = """
    {
        "includes": ["http://www.test.com/*"],
        "name": "test",
        "domain":"",
        "homepage":"http://www.test.com/"
    }
    """
    manifest_file = "{}/webapp-properties.json".format(tmpdir)
    with open(manifest_file, "w+") as f:
        f.write(manifest_content)
    if len(intent_filter_content) != 0:
        intent_filter_file = "{}/local-intent-filter.js".format(tmpdir)
        with open(intent_filter_file, "w+") as f:
            f.write(intent_filter_content)
    old_cwd = os.getcwd()
    try:
        os.chdir(tmpdir)
        yield tmpdir
    finally:
        os.chdir(old_cwd)
        shutil.rmtree(tmpdir)


class WebappContainerIntentUriSupportTestCase(
        WebappContainerTestCaseWithLocalContentBase):
    def test_basic_intent_parsing(self):
        rule = 'MAP *.test.com:80 ' + self.get_base_url_hostname()
        with generate_temp_webapp_with_intent() as webapp_install_path:
            args = ['--webappModelSearchPath='+webapp_install_path]
            self.launch_webcontainer_app(
                args,
                {'UBUNTU_WEBVIEW_HOST_MAPPING_RULES': rule})
            webview = self.get_oxide_webview()
            webapp_url = 'http://www.test.com/'
            self.assertThat(webview.url, Eventually(Equals(webapp_url)))

            intent_uri = 'intent://maps.google.es/maps?ie=utf-8&gl=es\
#Intent;scheme=http;package=com.google.android.apps.maps;end'
            self.assertThat(
                'http://maps.google.es/maps?ie=utf-8&gl=es',
                Equals(self.get_intent_filtered_uri(intent_uri)))

    def test_webapp_with_invalid_default_local_intent(self):
        rule = 'MAP *.test.com:80 ' + self.get_base_url_hostname()
        filter = "1"
        with generate_temp_webapp_with_intent(filter) as webapp_install_path:
            args = ['--webappModelSearchPath='+webapp_install_path]
            self.launch_webcontainer_app(
                args,
                {'UBUNTU_WEBVIEW_HOST_MAPPING_RULES': rule})
            webview = self.get_oxide_webview()
            webapp_url = 'http://www.test.com/'
            self.assertThat(webview.url, Eventually(Equals(webapp_url)))

            intent_uri = 'intent://www.test.com/maps?ie=utf-8&gl=es\
#Intent;scheme=http;package=com.google.android.apps.maps;end'
            self.assertThat(
                'http://www.test.com/maps?ie=utf-8&gl=es',
                Equals(self.get_intent_filtered_uri(intent_uri)))

    def test_with_valid_default_local_intent(self):
        rule = 'MAP *.test.com:80 ' + self.get_base_url_hostname()
        filter = "(function(r) { \
            return { \
                'scheme': 'https', \
                'host': 'maps.test.com', \
                'uri': r.uri }; })"
        with generate_temp_webapp_with_intent(filter) as webapp_install_path:
            args = [
                '--webappModelSearchPath='+webapp_install_path,
                '--use-local-intent-filter']
            self.launch_webcontainer_app(
                args,
                {'UBUNTU_WEBVIEW_HOST_MAPPING_RULES': rule})
            webview = self.get_oxide_webview()
            webapp_url = 'http://www.test.com/'
            self.assertThat(webview.url, Eventually(Equals(webapp_url)))

            intent_uri = 'intent://www.test.com/maps?ie=utf-8&gl=es\
#Intent;scheme=http;package=com.google.android.apps.maps;end'
            self.assertThat(
                'https://maps.test.com/maps?ie=utf-8&gl=es',
                Equals(self.get_intent_filtered_uri(intent_uri)))

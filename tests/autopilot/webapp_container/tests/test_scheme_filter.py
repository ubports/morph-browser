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
def generate_webapp_with_scheme_filter(scheme_filter_content=""):
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
    if len(scheme_filter_content) != 0:
        scheme_filter_file = "{}/local-scheme-filter.js".format(tmpdir)
        with open(scheme_filter_file, "w+") as f:
            f.write(scheme_filter_content)
    old_cwd = os.getcwd()
    try:
        os.chdir(tmpdir)
        yield tmpdir
    finally:
        os.chdir(old_cwd)
        shutil.rmtree(tmpdir)


# Those tests rely on get_scheme_filtered_uri() which
# relies on implementation detail to trigger part of the intent handling
# code. This comes from the fact that the url-dispatcher is not easily
# instrumentable , so a full feature flow coverage is quite tricky to get.
# Those tests are not really functional in that sense.
class WebappContainerSchemeFilterTestCase(
        WebappContainerTestCaseWithLocalContentBase):
    def test_basic_intent_parsing(self):
        rule = 'MAP *.test.com:80 ' + self.get_base_url_hostname()
        with generate_webapp_with_scheme_filter() as webapp_install_path:
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
                Equals(self.get_scheme_filtered_uri(intent_uri)))

    def test_webapp_with_invalid_default_local_intent(self):
        rule = 'MAP *.test.com:80 ' + self.get_base_url_hostname()
        filter = "{ \"intent\": 1 }"
        with generate_webapp_with_scheme_filter(filter) as webapp_install_path:
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
                Equals(self.get_scheme_filtered_uri(intent_uri)))

    def test_with_valid_default_local_intent(self):
        rule = 'MAP *.test.com:80 ' + self.get_base_url_hostname()
        filter = "{ \"intent\": \"(function(r) { \
            return { \
                'scheme': 'https', \
                'host': 'maps.test.com', \
                'path': r.path }; })\" }"
        with generate_webapp_with_scheme_filter(filter) as webapp_install_path:
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
                'https://maps.test.com/maps?ie=utf-8&gl=es',
                Equals(self.get_scheme_filtered_uri(intent_uri)))

    def test_no_filter_for_http(self):
        rule = 'MAP *.test.com:80 ' + self.get_base_url_hostname()
        filter = "{ \"http\": \"(function(r) { \
            return { \
                'scheme': 'https', \
                'host': 'maps.test.com', \
                'path': r.path }; })\" }"
        with generate_webapp_with_scheme_filter(filter) as webapp_install_path:
            args = ['--webappModelSearchPath='+webapp_install_path]
            self.launch_webcontainer_app(
                args,
                {'UBUNTU_WEBVIEW_HOST_MAPPING_RULES': rule})

            webview = self.get_oxide_webview()
            webapp_url = 'http://www.test.com/'
            self.assertThat(webview.url, Eventually(Equals(webapp_url)))

            new_uri = 'http://www.test.com/maps?ie=utf-8&gl=es'
            self.assertThat(
                'http://www.test.com/maps?ie=utf-8&gl=es',
                Equals(self.get_scheme_filtered_uri(new_uri)))

    def test_default_scheme_filter(self):
        rule = 'MAP *.test.com:80 ' + self.get_base_url_hostname()
        filter = "{ \"mailto\": \"(function(r) { \
            return { \
                'scheme': 'https', \
                'host': 'mail.google.com', \
                'path': '?to='+encodeURIComponent(r.path) }; })\" }"
        with generate_webapp_with_scheme_filter(filter) as webapp_install_path:
            args = ['--webappModelSearchPath='+webapp_install_path]
            self.launch_webcontainer_app(
                args,
                {'UBUNTU_WEBVIEW_HOST_MAPPING_RULES': rule})
            webview = self.get_oxide_webview()
            webapp_url = 'http://www.test.com/'
            self.assertThat(webview.url, Eventually(Equals(webapp_url)))

            scheme_uri = 'mailto:blabla@ubuntu.com'
            self.assertThat(
                'https://mail.google.com/?to=blabla%40ubuntu.com',
                Equals(self.get_scheme_filtered_uri(scheme_uri)))

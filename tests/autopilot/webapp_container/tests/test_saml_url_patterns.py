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
import json

from testtools.matchers import Equals
from autopilot.matchers import Eventually

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase


@contextmanager
def generate_saml_file_with_url_patterns(
        path,
        patterns,
        do_generate_invalid_content=False):
    tmpdir = tempfile.mkdtemp()

    if do_generate_invalid_content:
        file_content = "{]"
    else:
        file_content = json.dump(patterns)

    patterns_file = "{}/generated-url-patterns.json".format(tmpdir)
    with open(patterns_file, "w+") as f:
        f.write(file_content)
    old_cwd = os.getcwd()
    try:
        os.chdir(tmpdir)
        yield tmpdir
    finally:
        os.chdir(old_cwd)
        shutil.rmtree(tmpdir)


class WebappContainerSAMLUrlPatternsTestCase(
        WebappContainerTestCaseWithLocalContentBase):
    def test_saml_urls_added(self):
        rule = 'MAP *.test.com:80 ' + self.get_base_url_hostname()
        args = []
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '',
            {'WEBAPP_CONTAINER_BLOCK_OPEN_URL_EXTERNALLY': '1',
                'UBUNTU_WEBVIEW_HOST_MAPPING_RULES': rule})
        self.get_webcontainer_window().visible.wait_for(True)

        container_webview = self.get_webcontainer_webview()
        url_patterns_file_updated_watcher = container_webview.watch_signal(
            'generatedUrlPatternsFileUpdated(QString)')

        samlRequestRedirectsCount = 2

        webview = self.get_oxide_webview()
        target_webapp_url = 'http://www.test.com/'
        webview.url = 'http://www.test.com/'
        + 'redirect-to-saml/?loopcount='
        + str(samlRequestRedirectsCount)
        + '&SAMLRequest=1'
        self.assertThat(webview.url, Eventually(Equals(target_webapp_url)))

        self.assertThat(
            url_patterns_file_updated_watcher.was_emitted,
            Equals(False))
        self.assertThat(
            url_patterns_file_updated_watcher,
            Equals(samlRequestRedirectsCount))

        path = container_webview.get_signal_emissions(
            'generatedUrlPatternsFileUpdated(QString)')[0][0]

        with open(path, "r") as f:
            self.assertThat(f.read(), Equals("[\"https?://www.test.com/*\"]"))
            shutil.rm(path)

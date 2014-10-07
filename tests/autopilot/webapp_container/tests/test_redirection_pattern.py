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


class WebappContainerRedirectionPatternTestCase(
        WebappContainerTestCaseWithLocalContentBase):

    def test_browse_to_redirection_pattern_url(self):
        REDIRECTION_HOSTNAME = self.get_base_url_hostname()
        args = ["--popup-redirection-url-prefix={}{}{}".format(
            'http://', REDIRECTION_HOSTNAME.replace('.', '\.'),
            '/redirect\\?url=([^&]*).*')]
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/get-redirect',
            {'WEBAPP_CONTAINER_BLOCK_OPEN_URL_EXTERNALLY': '1',
                'WEBAPP_CONTAINER_DO_NOT_FILTER_PATTERN_URL': '1'})

        webview = self.get_oxide_webview()
        external_open_watcher = webview.watch_signal(
            'openExternalUrlTriggered(QString)')
        got_redirection_url_watcher = webview.watch_signal(
            'gotRedirectionUrl(QString)')

        self.assertThat(external_open_watcher.was_emitted, Equals(False))
        self.assertThat(got_redirection_url_watcher.was_emitted, Equals(False))
        self.browse_to(
            "http://{}/get-redirect".format(REDIRECTION_HOSTNAME))

        self.pointing_device.click_object(webview)

        self.assertThat(
            lambda: got_redirection_url_watcher.was_emitted,
            Eventually(Equals(True)))
        self.assertThat(
            webview.get_signal_emissions(
                'gotRedirectionUrl(QString)')[0][0],
            Equals('myredirect'))
        self.assertThat(
            lambda: external_open_watcher.was_emitted,
            Eventually(Equals(True)))

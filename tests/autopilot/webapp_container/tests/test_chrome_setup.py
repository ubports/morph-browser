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

from __future__ import absolute_import

from testtools.matchers import Equals, NotEquals

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase


class WebappContainerChromeSetupTestCase(
        WebappContainerTestCaseWithLocalContentBase):

    def test_default_to_chromeless(self):
        self.launch_webcontainer_app_with_local_http_server([])
        self.assertThat(self.get_webcontainer_proxy(), NotEquals(None))
        self.assertThat(self.get_webcontainer_webview().chromeless,
                        Equals(True))

    def test_enable_chrome_back_forward(self):
        args = ['--enable-back-forward']
        self.launch_webcontainer_app_with_local_http_server(args)
        self.assertThat(self.get_webcontainer_webview().chromeless,
                        Equals(False))
        panel = self.get_webcontainer_panel()
        self.assertThat(panel.backForwardButtonsVisible,
                        Equals(True))

    def test_enable_chrome_address_bar(self):
        args = ['--enable-addressbar']
        self.launch_webcontainer_app_with_local_http_server(args)
        self.assertThat(self.get_webcontainer_proxy(), NotEquals(None))
        self.assertThat(self.get_webcontainer_webview().chromeless,
                        Equals(False))
        self.assertThat(self.get_webcontainer_panel().addressBarVisible,
                        Equals(True))

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

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase

from testtools.matchers import Equals
from autopilot.matchers import Eventually


class TestPageMetaCollector(WebappContainerTestCaseWithLocalContentBase):
    def test_update_theme_color(self):
        args = ['--enable-addressbar']
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/theme-color/?color=red')
        self.get_webcontainer_window().visible.wait_for(True)

        chrome_base = self.app.wait_select_single(
            objectName="chromeBase")

        self.assertThat(
            lambda: str(chrome_base.backgroundColor),
            Eventually(Equals("Color(255, 0, 0, 255)")))

    def test_update_theme_color_with_manifest(self):
        args = ['--enable-addressbar']
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/theme-color/?manifest=true')
        self.get_webcontainer_window().visible.wait_for(True)

        chrome_base = self.app.wait_select_single(
            objectName="chromeBase")

        self.assertThat(
            lambda: str(chrome_base.backgroundColor),
            Eventually(Equals("Color(255, 0, 0, 255)")))

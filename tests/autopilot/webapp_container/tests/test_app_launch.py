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
        args = ['--webapp']
        self.launch_webcontainer_app(args)
        self.assertThat(self.get_webcontainer_proxy(), Equals(None))

    def test_loads_with_url(self):
        args = ['--enable-addressbar']
        self.launch_webcontainer_app_with_local_http_server(args)
        self.assertThat(lambda: self.get_webcontainer_window().url,
                        Eventually(Equals(self.url)))

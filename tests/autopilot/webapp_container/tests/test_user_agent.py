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

from testtools.matchers import Contains
from autopilot.matchers import Eventually

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase


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
        self.assertThat(self.get_webcontainer_window().title,
                        Eventually(Contains(result)))

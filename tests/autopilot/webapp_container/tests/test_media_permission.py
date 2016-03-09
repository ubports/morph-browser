# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2016 Canonical
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


class TestMediaPermission(WebappContainerTestCaseWithLocalContentBase):
    def test_access_media_from_main_view(self):
        args = []
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/media-access')
        self.get_webcontainer_window().visible.wait_for(True)

        chrome_base = self.app.wait_select_single(
            objectName="mediaAccessDialog")

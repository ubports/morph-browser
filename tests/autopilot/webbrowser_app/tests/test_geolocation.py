# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2014-2016 Canonical
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

import testtools
from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


@testtools.skip("Skipping due to the lack of HTTPS support in the "
                "test suite, see https://launchpad.net/bugs/1505995")
class TestGeolocation(StartOpenRemotePageTestCaseBase):

    def setUp(self):
        super(TestGeolocation, self).setUp(path="/geolocation")
        self.dialog = self.main_window.get_geolocation_dialog()

    def tearDown(self):
        self.dialog.wait_until_destroyed()
        super(TestGeolocation, self).tearDown()

    def test_geolocation_deny(self):
        self.pointing_device.click_object(self.dialog.get_deny_button())

    def test_geolocation_accept(self):
        self.pointing_device.click_object(self.dialog.get_allow_button())

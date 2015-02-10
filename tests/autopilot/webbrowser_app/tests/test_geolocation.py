# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
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

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestGeolocation(StartOpenRemotePageTestCaseBase):

    def setUp(self):
        super(TestGeolocation, self).setUp()
        url = self.base_url + "/geolocation"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        self.dialog = self.main_window.get_geolocation_dialog()

    def tearDown(self):
        self.dialog.wait_until_destroyed()
        super(TestGeolocation, self).tearDown()

    def test_geolocation_deny(self):
        self.pointing_device.click_object(self.dialog.get_deny_button())

    def test_geolocation_accept(self):
        self.pointing_device.click_object(self.dialog.get_allow_button())

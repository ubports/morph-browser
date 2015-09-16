# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
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

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestBasicAuthentication(StartOpenRemotePageTestCaseBase):

    def setUp(self):
        super(TestBasicAuthentication, self).setUp()
        self.main_window.go_to_url(self.base_url + "/basicauth")
        self.dialog = self.main_window.get_http_auth_dialog()
        self.username = "user"
        self.password = "pass"

    def test_cancel(self):
        self.pointing_device.click_object(self.dialog.get_deny_button())
        self.dialog.wait_until_destroyed()

    def test_right_credentials(self):
        username = self.dialog.get_username_field()
        username.write(self.username)
        password = self.dialog.get_password_field()
        password.write(self.password)
        self.pointing_device.click_object(self.dialog.get_allow_button())
        self.dialog.wait_until_destroyed()

    def test_wrong_credentials(self):
        username = self.dialog.get_username_field()
        username.write("x")
        password = self.dialog.get_password_field()
        password.write("x")
        self.pointing_device.click_object(self.dialog.get_allow_button())
        self.dialog.wait_until_destroyed()
        # verify that a new dialog has been displayed
        self.main_window.get_http_auth_dialog()

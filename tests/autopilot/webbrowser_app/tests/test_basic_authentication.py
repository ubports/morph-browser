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
        self.username = "user"
        self.password = "pass"
        self.url = self.base_url + "/basic_auth"

    def test_cancel(self):
        self.main_window.go_to_url(self.url)
        dialog = self.main_window.get_basic_auth_dialog()
        self.pointing_device.click_object(dialog.get_deny_button())
        dialog.wait_until_destroyed()

    def test_right_credentials(self):
        self.main_window.go_to_url(self.url)
        dialog = self.main_window.get_basic_auth_dialog()
        username = dialog.get_username_field()
        username.write(self.username)
        password = dialog.get_password_field()
        password.write(self.password)
        self.pointing_device.click_object(dialog.get_allow_button())
        dialog.wait_until_destroyed()

    def test_wrong_credentials(self):
        self.main_window.go_to_url(self.url)
        dialog = self.main_window.get_basic_auth_dialog()
        username = dialog.get_username_field()
        username.write("x")
        password = dialog.get_password_field()
        password.write("x")
        self.pointing_device.click_object(dialog.get_allow_button())
        dialog.wait_until_destroyed()
        # verify that a new dialog has been displayed
        self.main_window.get_basic_auth_dialog()

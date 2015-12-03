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

import testtools
from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestMediaAccessPermission(StartOpenRemotePageTestCaseBase):

    def setUp(self):
        super(TestMediaAccessPermission, self).setUp()
        self.url = self.base_url + "/media/"
        self.allowed_url = self.base_url + "/test1"
        self.denied_url = self.base_url + "/test2"

    @testtools.skip("We can't guarantee/test that audio/video devices exist")
    def test_allow(self):
        # verify that trying to access any media raises an authorization dialog
        url = self.url + "a"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        dialog = self.main_window.get_media_access_dialog()

        # note that we have no easy way to verify that the browser actually
        # grants or denied permission based on our choice, because we can't
        # easily inspect the contents of the page from AP tests. the simplest
        # workaround I could find was to redirect the user to two different
        # pages upon permission granted or denied, and detect that instead
        dialog.click_allow_button()
        dialog.wait_until_destroyed()
        self.main_window.wait_until_page_loaded(self.allowed_url)

        # verify that trying to access the same media for the same origin in
        # the same session will not ask for permission again...
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(self.allowed_url)

        # ...but it will ask if we try to access other media
        url = self.url + "v"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        dialog = self.main_window.get_media_access_dialog()
        dialog.click_allow_button()
        dialog.wait_until_destroyed()
        self.main_window.wait_until_page_loaded(self.allowed_url)

        # now that we granted both permissions, verify that asking for both
        # together will also not raise the dialog
        url = self.url + "av"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(self.allowed_url)

    @testtools.skip("Skipping due to the lack of HTTPS support in the "
                    "test suite, see https://launchpad.net/bugs/1505995")
    def test_deny(self):
        # verify that trying to access any media raises an authorization dialog
        # and we get redirected to the denial page in case we refuse to give
        # permission
        url = self.url + "a"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        dialog = self.main_window.get_media_access_dialog()
        dialog.click_deny_button()
        dialog.wait_until_destroyed()
        self.main_window.wait_until_page_loaded(self.denied_url)

        # verify that trying to access the same media for the same origin in
        # the same session will not ask for permission again...
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(self.denied_url)

    @testtools.skip("Skipping due to oxide bug, see http://pad.lv/1501017")
    def test_deny_combined(self):
        # deny first one input type, then try to ask both and verify that a
        # request is made for the media that was not asked for the fist time
        url = self.url + "a"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        dialog = self.main_window.get_media_access_dialog()
        dialog.click_deny_button()
        dialog.wait_until_destroyed()
        self.main_window.wait_until_page_loaded(self.denied_url)

        url = self.url + "av"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        dialog = self.main_window.get_media_access_dialog()

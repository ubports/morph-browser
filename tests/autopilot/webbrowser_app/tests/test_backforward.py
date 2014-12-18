# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2013-2014 Canonical
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

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestBackForward(StartOpenRemotePageTestCaseBase):

    """Tests the back and forward functionality."""

    def setUp(self):
        super().setUp()
        self.chrome = self.main_window.chrome

    def test_homepage_no_history(self):
        self.assertThat(self.chrome.is_back_button_enabled(), Equals(False))
        self.assertThat(self.chrome.is_forward_button_enabled(), Equals(False))

    def test_go_back_after_opening_a_new_page(self):
        """Test that the back button must open the previous page."""
        self.assertThat(self.chrome.is_back_button_enabled(), Equals(False))
        url = self.base_url + "/test2"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        self.main_window.go_back()
        self.assert_home_page_eventually_loaded()

    def test_go_forward_after_going_back(self):
        """Test that the forward button must open the previous page."""
        url = self.base_url + "/test2"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        self.assertThat(self.chrome.is_forward_button_enabled(), Equals(False))
        self.main_window.go_back()
        self.assert_home_page_eventually_loaded()
        self.main_window.go_forward()
        self.main_window.wait_until_page_loaded(url)

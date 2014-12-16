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
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase

INVALID_URL = "http://invalid/"


class TestErrorSheet(StartOpenRemotePageTestCaseBase):

    """Tests the error message functionality."""

    def test_invalid_url_triggers_error_message(self):
        error = self.main_window.get_error_sheet()
        self.assertThat(error.visible, Equals(False))
        self.go_to_url(INVALID_URL)
        self.assertThat(error.visible, Eventually(Equals(True)))

    def test_navigating_away_discards_error_message(self):
        error = self.main_window.get_error_sheet()
        self.go_to_url(INVALID_URL)
        self.assertThat(error.visible, Eventually(Equals(True)))
        self.go_to_url(self.base_url + "/test2")
        self.assertThat(error.visible, Eventually(Equals(False)))

    def test_navigating_back_discards_error_message(self):
        error = self.main_window.get_error_sheet()
        self.go_to_url(INVALID_URL)
        self.assertThat(error.visible, Eventually(Equals(True)))
        chrome = self.main_window.get_chrome()
        self.pointing_device.click_object(chrome.get_back_button())
        self.assertThat(error.visible, Eventually(Equals(False)))

    def test_navigating_forward_discards_error_message(self):
        error = self.main_window.get_error_sheet()
        self.go_to_url(INVALID_URL)
        self.assert_page_eventually_loaded(INVALID_URL)
        url = self.base_url + "/test2"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        chrome = self.main_window.get_chrome()
        self.pointing_device.click_object(chrome.get_back_button())
        self.assertThat(error.visible, Eventually(Equals(True)))
        self.pointing_device.click_object(chrome.get_forward_button())
        self.assertThat(error.visible, Eventually(Equals(False)))

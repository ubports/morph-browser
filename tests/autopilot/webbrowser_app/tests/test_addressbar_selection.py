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

import time

from testtools.matchers import Equals, GreaterThan
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestAddressBarSelection(StartOpenRemotePageTestCaseBase):

    def test_click_to_select(self):
        address_bar = self.main_window.get_chrome().get_address_bar()
        self.pointing_device.click_object(address_bar)
        text_field = address_bar.get_text_field()
        self.assertThat(text_field.selectedText,
                        Eventually(Equals(text_field.text)))

    def test_click_on_action_button(self):
        address_bar = self.main_window.get_chrome().get_address_bar()
        action_button = address_bar.get_action_button()
        self.pointing_device.click_object(action_button)
        text_field = address_bar.get_text_field()
        self.assertThat(text_field.selectedText, Eventually(Equals("")))

    def test_second_click_deselect_text(self):
        address_bar = self.main_window.get_chrome().get_address_bar()
        self.pointing_device.click_object(address_bar)
        # avoid double click
        time.sleep(1)
        self.assert_osk_eventually_shown()
        self.pointing_device.click_object(address_bar)
        text_field = address_bar.get_text_field()
        self.assertThat(text_field.selectedText, Eventually(Equals('')))
        self.assertThat(text_field.cursorPosition, Eventually(GreaterThan(0)))

    def test_double_click_select_word(self):
        address_bar = self.main_window.get_chrome().get_address_bar()
        self.pointing_device.click_object(address_bar)
        self.assert_osk_eventually_shown()
        self.pointing_device.click_object(address_bar)
        # avoid double click
        time.sleep(1)
        # now simulate a double click
        self.pointing_device.click()
        self.pointing_device.click()
        text_field = address_bar.get_text_field()
        self.assertThat(lambda: len(text_field.selectedText),
                        Eventually(GreaterThan(0)))

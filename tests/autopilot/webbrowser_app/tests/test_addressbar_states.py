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


class TestAddressBarStates(StartOpenRemotePageTestCaseBase):

    """Tests the address bar states."""

    def test_state_idle_when_loaded(self):
        address_bar = self.main_window.get_chrome().get_address_bar()
        self.assertThat(address_bar.state, Eventually(Equals("")))

    def test_state_loading_then_idle(self):
        address_bar = self.main_window.get_chrome().get_address_bar()
        url = self.base_url + "/wait/2"
        self.go_to_url(url)
        self.assertThat(address_bar.state, Eventually(Equals("loading")))
        self.assertThat(address_bar.state, Eventually(Equals("")))

    def test_cancel_state_loading(self):
        address_bar = self.main_window.get_chrome().get_address_bar()
        action_button = address_bar.get_action_button()
        url = self.base_url + "/wait/5"
        self.go_to_url(url)
        self.assertThat(address_bar.state, Eventually(Equals("loading")))
        self.pointing_device.click_object(action_button)
        self.assertThat(address_bar.state, Eventually(Equals("")))

    def test_state_editing(self):
        address_bar = self.main_window.get_chrome().get_address_bar()
        self.pointing_device.click_object(address_bar)
        self.assertThat(address_bar.state, Eventually(Equals("editing")))
        self.keyboard.press_and_release("Enter")
        self.assertThat(address_bar.state, Eventually(Equals("")))

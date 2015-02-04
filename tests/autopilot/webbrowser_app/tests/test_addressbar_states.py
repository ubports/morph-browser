# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2013-2015 Canonical
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


class TestAddressBarStates(StartOpenRemotePageTestCaseBase):

    def test_cancel_state_loading(self):
        address_bar = self.main_window.address_bar
        action_button = address_bar.get_action_button()
        url = self.base_url + "/wait/5"
        self.main_window.go_to_url(url)
        address_bar.loading.wait_for(True)
        self.pointing_device.click_object(action_button)
        address_bar.loading.wait_for(False)

    def test_state_editing(self):
        address_bar = self.main_window.address_bar
        self.pointing_device.click_object(address_bar)
        address_bar.activeFocus.wait_for(True)
        self.keyboard.press_and_release("Enter")
        address_bar.activeFocus.wait_for(False)

    def test_looses_focus_when_loading_starts(self):
        address_bar = self.main_window.address_bar
        self.pointing_device.click_object(address_bar)
        address_bar.activeFocus.wait_for(True)
        url = self.base_url + "/test2"
        self.main_window.go_to_url(url)
        address_bar.activeFocus.wait_for(False)

    def test_looses_focus_when_reloading(self):
        address_bar = self.main_window.address_bar
        self.pointing_device.click_object(address_bar)
        address_bar.activeFocus.wait_for(True)
        action_button = address_bar.get_action_button()
        # The following fails (see https://launchpad.net/bugs/1417118)
        # self.pointing_device.click_object(action_button)
        # whereas clicking somewhere in the leftmost half of the button works
        self.pointing_device.move(
            action_button.globalRect.x + action_button.width * 0.49,
            action_button.globalRect.y + action_button.height * 0.5)
        self.pointing_device.click()
        address_bar.activeFocus.wait_for(False)

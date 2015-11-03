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

import testtools
from testtools.matchers import Equals
from autopilot.matchers import Eventually
from autopilot.platform import model

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestAddressBarStates(StartOpenRemotePageTestCaseBase):

    def test_cancel_state_loading(self):
        address_bar = self.main_window.address_bar
        url = self.base_url + "/wait/5"
        self.main_window.go_to_url(url)
        address_bar.loading.wait_for(True)
        address_bar.click_action_button()
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
        # Work around https://launchpad.net/bugs/1417118 by clearing the
        # address bar and typing again the current URL to enable the reload
        # button.
        address_bar.clear()
        address_bar.write(self.url)
        address_bar.click_action_button()
        address_bar.activeFocus.wait_for(False)

    # http://pad.lv/1456199
    @testtools.skipIf(model() != "Desktop", "on desktop only")
    def test_clears_when_actual_url_changed(self):
        address_bar = self.main_window.address_bar
        self.pointing_device.click_object(address_bar)
        address_bar.activeFocus.wait_for(True)
        url = self.base_url + "/test1"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        self.pointing_device.click_object(address_bar)
        address_bar.activeFocus.wait_for(True)
        self.new_tab_view = self.open_new_tab(open_tabs_view=True)
        self.assertThat(address_bar.text, Eventually(Equals("")))

    # http://pad.lv/1487713
    def test_does_not_clear_when_typing_while_loading(self):
        address_bar = self.main_window.address_bar
        self.pointing_device.click_object(address_bar)
        address_bar.activeFocus.wait_for(True)
        url = self.base_url + "/wait/3"
        self.main_window.go_to_url(url)
        self.pointing_device.click_object(address_bar)
        address_bar.write("x")
        self.main_window.wait_until_page_loaded(url)
        self.assertThat(address_bar.text, Equals("x"))

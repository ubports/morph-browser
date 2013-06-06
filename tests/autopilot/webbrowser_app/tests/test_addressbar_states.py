# -*- coding: utf-8 -*-
#
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

from __future__ import absolute_import

from testtools.matchers import Equals
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestAddressBarStates(StartOpenRemotePageTestCaseBase):

    """Tests the address bar states."""

    def test_state_idle_when_loaded(self):
        address_bar = self.main_window.get_address_bar()
        self.assertThat(address_bar.state, Eventually(Equals("")))

    def test_state_loading_then_idle(self):
        address_bar = self.main_window.get_address_bar()
        url = self.base_url + "/wait/2"
        self.go_to_url(url)
        self.assertThat(address_bar.state, Eventually(Equals("loading")))
        self.assertThat(address_bar.state, Eventually(Equals("")))

    def test_cancel_state_loading(self):
        address_bar = self.main_window.get_address_bar()
        action_button = self.main_window.get_address_bar_action_button()
        url = self.base_url + "/wait/5"
        self.go_to_url(url)
        self.assertThat(address_bar.state, Eventually(Equals("loading")))
        self.ensure_chrome_is_hidden()
        self.reveal_chrome()
        self.pointing_device.move_to_object(action_button)
        self.pointing_device.click()
        self.assertThat(address_bar.state, Eventually(Equals("")))

    def test_state_editing(self):
        address_bar = self.main_window.get_address_bar()
        self.assert_chrome_eventually_hidden()
        self.reveal_chrome()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()
        self.assertThat(address_bar.state, Eventually(Equals("editing")))
        self.keyboard.press_and_release("Enter")
        self.assertThat(address_bar.state, Eventually(Equals("")))

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

from webbrowser_app.tests import BrowserTestCaseBase, TYPING_DELAY


class TestMainWindowAddressBarActionButton(BrowserTestCaseBase):

    def test_button_disabled_when_text_is_empty(self):
        self.reveal_chrome()

        address_bar = self.main_window.get_address_bar()
        self.mouse.move_to_object(address_bar)
        self.mouse.click()

        clear_button = self.main_window.get_address_bar_clear_button()
        self.mouse.move_to_object(clear_button)
        self.mouse.click()

        action_button = self.main_window.get_address_bar_action_button()
        self.assertThat(action_button.enabled, Eventually(Equals(False)))

        self.keyboard.type("ubuntu", delay=TYPING_DELAY)
        self.assertThat(action_button.enabled, Eventually(Equals(True)))

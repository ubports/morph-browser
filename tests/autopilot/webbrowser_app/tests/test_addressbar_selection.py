# -*- coding: utf-8 -*-
#
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

from __future__ import absolute_import

import time

from testtools.matchers import Equals, GreaterThan
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestAddressBarSelection(StartOpenRemotePageTestCaseBase):

    """Test the address bar selection"""

    def test_click_to_select(self):
        self.reveal_chrome()
        address_bar = self.main_window.get_address_bar()
        self.mouse.move_to_object(address_bar)
        self.mouse.click()
        text_field = self.main_window.get_address_bar_text_field()
        self.assertThat(text_field.selectedText,
                        Eventually(Equals(text_field.text)))

    def test_click_on_action_button(self):
        self.reveal_chrome()
        action_button = self.main_window.get_address_bar_action_button()
        self.mouse.move_to_object(action_button)
        self.mouse.click()
        text_field = self.main_window.get_address_bar_text_field()
        self.assertThat(text_field.selectedText, Eventually(Equals("")))

    def test_second_click_deselect_text(self):
        self.reveal_chrome()
        address_bar = self.main_window.get_address_bar()
        self.mouse.move_to_object(address_bar)
        self.mouse.click()
        # avoid double click
        time.sleep(1)
        self.mouse.click()
        text_field = self.main_window.get_address_bar_text_field()
        self.assertThat(text_field.selectedText, Eventually(Equals('')))
        self.assertThat(text_field.cursorPosition, Eventually(GreaterThan(0)))

    def test_double_click_select_word(self):
        self.reveal_chrome()
        address_bar = self.main_window.get_address_bar()
        self.mouse.move_to_object(address_bar)
        self.mouse.click()
        self.mouse.click()
        text_field = self.main_window.get_address_bar_text_field()
        self.assertThat(lambda: len(text_field.selectedText),
                        Eventually(GreaterThan(0)))

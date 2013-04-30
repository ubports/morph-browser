# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Tests for the Browser"""

from __future__ import absolute_import

from testtools.matchers import Equals, GreaterThan
from autopilot.matchers import Eventually

from webbrowser_app.tests import \
    BrowserTestCaseBaseWithHTTPServer, \
    HTTP_SERVER_PORT

import time


class TestMainWindowStartOpenRemotePageBase(BrowserTestCaseBaseWithHTTPServer):

    """Helper test class that opens the browser at a remote URL instead of
    defaulting to the homepage."""

    def setUp(self):
        self.base_url = "http://localhost:%d" % HTTP_SERVER_PORT
        self.url = self.base_url + "/loremipsum"
        self.ARGS = [self.url]
        super(TestMainWindowStartOpenRemotePageBase, self).setUp()
        self.assert_home_page_eventually_loaded()

    def assert_home_page_eventually_loaded(self):
        self.assert_page_eventually_loaded(self.url)


class TestMainWindowAddressBarStates(TestMainWindowStartOpenRemotePageBase):

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
        self.reveal_chrome()
        self.mouse.move_to_object(action_button)
        self.mouse.click()
        self.assertThat(address_bar.state, Eventually(Equals("")))

    def test_state_editing(self):
        address_bar = self.main_window.get_address_bar()
        self.reveal_chrome()
        self.mouse.move_to_object(address_bar)
        self.mouse.click()
        self.assertThat(address_bar.state, Eventually(Equals("editing")))
        self.keyboard.press("Enter")
        self.assertThat(address_bar.state, Eventually(Equals("")))


class TestMainWindowAddressBarSelection(TestMainWindowStartOpenRemotePageBase):

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

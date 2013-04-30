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
    BrowserTestCaseBase, \
    BrowserTestCaseBaseWithHTTPServer, \
    HTTP_SERVER_PORT

import time


LOREMIPSUM = "<p>Lorem ipsum dolor sit amet.</p>"


class TestMainWindowStartOpenLocalPageBase(BrowserTestCaseBase):

    """Helper test class that opens the browser at a local URL instead of
    defaulting to the homepage."""

    def setUp(self):
        self.url = self.make_html_page("start page", LOREMIPSUM)
        self.ARGS = [self.url]
        super(TestMainWindowStartOpenLocalPageBase, self).setUp()
        self.assert_home_page_eventually_loaded()

    def assert_home_page_eventually_loaded(self):
        self.assert_page_eventually_loaded(self.url)


class TestMainWindowBackForward(TestMainWindowStartOpenLocalPageBase):

    """Tests the back and forward functionality."""

    def click_back_button(self):
        self.reveal_chrome()
        back_button = self.main_window.get_back_button()
        self.mouse.move_to_object(back_button)
        self.mouse.click()

    def test_homepage_no_history(self):
        back_button = self.main_window.get_back_button()
        self.assertThat(back_button.enabled, Equals(False))
        forward_button = self.main_window.get_forward_button()
        self.assertThat(forward_button.enabled, Equals(False))

    def test_opening_new_page_enables_back_button(self):
        back_button = self.main_window.get_back_button()
        self.assertThat(back_button.enabled, Equals(False))
        url = self.make_html_page("page 2", LOREMIPSUM)
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        self.assertThat(back_button.enabled, Eventually(Equals(True)))

    def test_navigating_back_enables_forward_button(self):
        url = self.make_html_page("page 2", LOREMIPSUM)
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        forward_button = self.main_window.get_forward_button()
        self.assertThat(forward_button.enabled, Equals(False))
        self.click_back_button()
        self.assert_home_page_eventually_loaded()
        self.assertThat(forward_button.enabled, Eventually(Equals(True)))


class TestMainWindowErrorSheet(TestMainWindowStartOpenLocalPageBase):

    """Tests the error message functionality."""

    def test_invalid_url_triggers_error_message(self):
        error = self.main_window.get_error_sheet()
        self.assertThat(error.visible, Equals(False))
        self.go_to_url("http://invalid")
        self.assertThat(error.visible, Eventually(Equals(True)))


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

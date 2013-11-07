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


LOREMIPSUM = "<p>Lorem ipsum dolor sit amet.</p>"


class TestBackForward(StartOpenRemotePageTestCaseBase):

    """Tests the back and forward functionality."""

    def click_back_button(self):
        self.ensure_chrome_is_hidden()
        self.main_window.open_toolbar().click_button("backButton")

    def test_homepage_no_history(self):
        back_button = self.main_window.get_back_button()
        self.assertThat(back_button.enabled, Equals(False))
        forward_button = self.main_window.get_forward_button()
        self.assertThat(forward_button.enabled, Equals(False))

    def test_opening_new_page_enables_back_button(self):
        back_button = self.main_window.get_back_button()
        self.assertThat(back_button.enabled, Equals(False))
        url = self.base_url + "/aleaiactaest"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        self.assertThat(back_button.enabled, Eventually(Equals(True)))

    def test_navigating_back_enables_forward_button(self):
        url = self.base_url + "/aleaiactaest"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        forward_button = self.main_window.get_forward_button()
        self.assertThat(forward_button.enabled, Equals(False))
        self.click_back_button()
        self.assert_home_page_eventually_loaded()
        self.assertThat(forward_button.enabled, Eventually(Equals(True)))

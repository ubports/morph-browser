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


class TestWindowTitle(BrowserTestCaseBase):

    """Tests that the window’s title reflects the page title."""

    def test_window_title(self):
        title = "Alice in Wonderland"
        body = "<p>Lorem ipsum dolor sit amet.</p>"
        url = self.make_html_page(title, body)
        self.reveal_chrome()
        address_bar = self.main_window.get_address_bar()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()
        clear_button = self.main_window.get_address_bar_clear_button()
        self.pointing_device.move_to_object(clear_button)
        self.pointing_device.click()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()
        self.keyboard.type(url, delay=TYPING_DELAY)
        self.keyboard.press_and_release("Enter")
        window = self.main_window.get_qml_view()
        title = "Alice in Wonderland - Ubuntu Web Browser"
        self.assertThat(window.title, Eventually(Equals(title)))

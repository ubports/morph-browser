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

from webbrowser_app.tests import BrowserTestCaseBase


class TestToolbar(BrowserTestCaseBase):

    """Tests interaction with the toolbar."""

    def assert_chrome_eventually_hidden(self):
        view = self.main_window.get_qml_view()
        chrome = self.main_window.get_chrome()
        self.assertThat(lambda: chrome.globalRect[1],
                        Eventually(Equals(view.y + view.height)))

    def test_reveal_chrome(self):
        view = self.main_window.get_qml_view()
        chrome = self.main_window.get_chrome()
        self.assertThat(chrome.globalRect[1], Equals(view.y + view.height))
        self.reveal_chrome()
        expected_y = view.y + view.height - chrome.height
        self.assertThat(lambda: chrome.globalRect[1],
                        Eventually(Equals(expected_y)))

    def test_hide_chrome(self):
        self.reveal_chrome()
        self.hide_chrome()
        self.assert_chrome_eventually_hidden()

    def test_unfocus_chrome_hides_it(self):
        webview = self.main_window.get_web_view()
        self.reveal_chrome()
        self.pointing_device.move_to_object(webview)
        self.pointing_device.click()
        self.assert_chrome_eventually_hidden()

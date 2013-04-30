# -*- coding: utf-8 -*-
#
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

from __future__ import absolute_import

from webbrowser_app.tests import BrowserTestCaseBase


class TestMainWindowToolbar(BrowserTestCaseBase):

    """Tests interaction with the toolbar."""

    def test_reveal_chrome(self):
        self.assert_chrome_hidden()
        self.reveal_chrome()
        self.assert_chrome_eventually_shown()

    def test_reveal_chrome_with_partial_swipe(self):
        self.assert_chrome_hidden()
        self.swipe_chrome_up(10)
        self.assert_chrome_eventually_shown()

    def test_reveal_chrome_with_long_swipe(self):
        chrome = self.main_window.get_chrome()
        self.assert_chrome_hidden()
        self.swipe_chrome_up(chrome.height * 2)
        self.assert_chrome_eventually_shown()

    def test_hide_chrome(self):
        self.reveal_chrome()
        self.hide_chrome()
        self.assert_chrome_eventually_hidden()

    def test_hide_chrome_with_partial_swipe(self):
        self.reveal_chrome()
        self.swipe_chrome_down(10)
        self.assert_chrome_eventually_hidden()

    def test_hide_chrome_with_long_swipe(self):
        chrome = self.main_window.get_chrome()
        self.reveal_chrome()
        self.swipe_chrome_down(chrome.height * 2)
        self.assert_chrome_eventually_hidden()

    def test_unfocus_chrome_hides_it(self):
        webview = self.main_window.get_web_view()
        self.reveal_chrome()
        self.mouse.move_to_object(webview)
        self.mouse.click()
        self.assert_chrome_eventually_hidden()

    def test_swipe_down_hidden_chrome_doesnt_reveal_it(self):
        view = self.main_window.get_qml_view()
        x_line = int(view.x + view.width * 0.5)
        start_y = int(view.y + view.height - 1)
        stop_y = start_y + 20
        self.mouse.drag(x_line, start_y, x_line, stop_y)
        self.assert_chrome_eventually_hidden()

    def test_swipe_shown_chrome_up_doesnt_hide_it(self):
        view = self.main_window.get_qml_view()
        chrome = self.main_window.get_chrome()
        self.reveal_chrome()
        x_line = int(view.x + view.width * 0.5)
        start_y = int(chrome.globalRect[1])
        stop_y = int(view.y - 1)
        self.mouse.drag(x_line, start_y, x_line, stop_y)
        self.assert_chrome_eventually_shown()

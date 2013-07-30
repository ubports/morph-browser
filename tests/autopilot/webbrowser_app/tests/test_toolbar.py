# -*- coding: utf-8 -*-
#
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

from __future__ import absolute_import

from webbrowser_app.tests import StartOpenLocalPageTestCaseBase


class TestToolbar(StartOpenLocalPageTestCaseBase):

    """Tests interaction with the toolbar."""

    def test_reveal_chrome(self):
        self.ensure_chrome_is_hidden()
        self.reveal_chrome()
        self.assert_chrome_eventually_shown()

    def test_hide_chrome(self):
        self.ensure_chrome_is_hidden()
        self.reveal_chrome()
        self.hide_chrome()
        self.assert_chrome_eventually_hidden()

    def test_unfocus_chrome_hides_it(self):
        webview = self.main_window.get_current_webview()
        self.ensure_chrome_is_hidden()
        self.reveal_chrome()
        self.pointing_device.click_object(webview)
        self.assert_chrome_eventually_hidden()

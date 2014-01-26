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

import unittest

from webbrowser_app.tests import \
    http_server, \
    BrowserTestCaseBase, \
    StartOpenRemotePageTestCaseBase


LOREMIPSUM = "<p>Lorem ipsum dolor sit amet.</p>"


class TestProgressBarAtStartup(BrowserTestCaseBase):

    """Tests that the progress bar (embedded inside the address bar) is
    initially visible when loading a page."""

    def setUp(self):
        self.server = http_server.HTTPServerInAThread()
        self.server.start()
        self.addCleanup(self.server.shutdown)
        self.base_url = "http://localhost:%d" % self.server.port
        self.ping_server()
        self.url = self.base_url + "/wait/8"
        self.ARGS = [self.url]
        super(TestProgressBarAtStartup, self).setUp()

    @unittest.skip("This test is flaky on slow configurations where the "
                   "autopilot machinery takes longer to initialize than the "
                   "hardcoded page load delay.")
    def test_chrome_initially_shown_then_hides_when_loaded(self):
        self.assert_chrome_eventually_shown()
        self.assert_page_eventually_loaded(self.url)
        self.assert_chrome_eventually_hidden()


class TestProgressBar(StartOpenRemotePageTestCaseBase):

    """Tests that the progress bar (embedded inside the address bar) is
    visible when a page is loading and hidden by default otherwise."""

    def test_chrome_hides_when_loaded(self):
        self.assert_chrome_eventually_hidden()
        url = self.base_url + "/wait/3"
        self.go_to_url(url)
        self.assert_chrome_eventually_shown()
        self.assert_page_eventually_loaded(url)
        self.assert_chrome_eventually_hidden()

    def test_load_page_from_link_reveals_chrome(self):
        url = self.base_url + "/clickanywherethenwait/3"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        self.assert_chrome_eventually_hidden()
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        self.assert_chrome_eventually_shown()

    def test_hide_chrome_while_loading(self):
        # simulate user interaction to hide the chrome while loading,
        # and ensure it doesn’t re-appear when loaded
        self.assert_chrome_eventually_hidden()
        url = self.base_url + "/wait/3"
        self.go_to_url(url)
        self.assert_chrome_eventually_shown()
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        self.assert_chrome_eventually_hidden()
        self.assert_page_eventually_loaded(url)
        self.assert_chrome_eventually_hidden()

    def test_stop_loading(self):
        # ensure that the chrome is not automatically hidden
        # when the user interrupts a page that was loading
        self.assert_chrome_eventually_hidden()
        url = self.base_url + "/wait/5"
        self.go_to_url(url)
        self.assert_page_eventually_loading()
        self.assert_chrome_eventually_shown()
        address_bar = self.main_window.get_address_bar()
        self.assertThat(address_bar.state, Eventually(Equals("loading")))
        action_button = self.main_window.get_address_bar_action_button()
        self.pointing_device.click_object(action_button)
        self.assertThat(address_bar.state, Eventually(Equals("")))
        self.assert_chrome_eventually_shown()
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        self.assert_chrome_eventually_hidden()

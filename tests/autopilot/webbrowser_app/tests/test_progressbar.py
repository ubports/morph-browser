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

from webbrowser_app.tests import \
    BrowserTestCaseBaseWithHTTPServer, HTTP_SERVER_PORT


LOREMIPSUM = "<p>Lorem ipsum dolor sit amet.</p>"


class TestProgressBarAtStartup(BrowserTestCaseBaseWithHTTPServer):

    """Tests that the progress bar (embedded inside the address bar) is
    initially visible when loading a page."""

    def setUp(self):
        self.base_url = "http://localhost:%d" % HTTP_SERVER_PORT
        self.url = self.base_url + "/wait/5"
        self.ARGS = [self.url]
        super(TestProgressBarAtStartup, self).setUp()

    def test_chrome_initially_shown_then_hides_when_loaded(self):
        self.assert_chrome_eventually_shown()
        self.assert_page_eventually_loaded(self.url)
        self.assert_chrome_eventually_hidden()


class TestProgressBar(BrowserTestCaseBaseWithHTTPServer):

    """Tests that the progress bar (embedded inside the address bar) is
    visible when a page is loading and hidden by default otherwise."""

    def test_chrome_hides_when_loaded(self):
        self.ensure_chrome_is_hidden()
        url = "http://localhost:%d/wait/3" % HTTP_SERVER_PORT
        self.go_to_url(url)
        self.assert_chrome_eventually_shown()
        self.assert_page_eventually_loaded(url)
        self.assert_chrome_eventually_hidden()

    def test_load_page_from_link_reveals_chrome(self):
        # craft a page that accepts clicks anywhere inside its window
        style = "'margin: 0; height: 100%'"
        url = "http://localhost:%d/wait/3" % HTTP_SERVER_PORT
        script = "'window.location = \"%s\"'" % url
        html = "<html><body style=%s onclick=%s></body></html>" % \
            (style, script)
        url = self.make_raw_html_page(html)
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        self.assert_chrome_eventually_hidden()
        webview = self.main_window.get_web_view()
        self.pointing_device.move_to_object(webview)
        self.pointing_device.click()
        self.assert_chrome_eventually_shown()

    def test_hide_chrome_while_loading(self):
        # simulate user interaction to hide the chrome while loading,
        # and ensure it doesn’t re-appear when loaded
        self.ensure_chrome_is_hidden()
        url = "http://localhost:%d/wait/3" % HTTP_SERVER_PORT
        self.go_to_url(url)
        self.assert_chrome_eventually_shown()
        webview = self.main_window.get_web_view()
        self.pointing_device.move_to_object(webview)
        self.pointing_device.click()
        self.assert_chrome_eventually_hidden()
        self.assert_page_eventually_loaded(url)
        self.assert_chrome_eventually_hidden()

    def test_stop_loading(self):
        # ensure that the chrome is not automatically hidden
        # when the user interrupts a page that was loading
        self.ensure_chrome_is_hidden()
        url = "http://localhost:%d/wait/5" % HTTP_SERVER_PORT
        self.go_to_url(url)
        self.assert_page_eventually_loading()
        self.assert_chrome_eventually_shown()
        action_button = self.main_window.get_address_bar_action_button()
        self.pointing_device.move_to_object(action_button)
        self.pointing_device.click()
        address_bar = self.main_window.get_address_bar()
        self.assertThat(address_bar.state, Eventually(Equals("")))
        self.assert_chrome_eventually_shown()
        webview = self.main_window.get_web_view()
        self.pointing_device.move_to_object(webview)
        self.pointing_device.click()
        self.assert_chrome_eventually_hidden()

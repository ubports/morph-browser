# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Tests for the Browser"""

from __future__ import absolute_import

from testtools.matchers import Equals
from autopilot.matchers import Eventually

from webbrowser_app.tests import BrowserTestCaseBase


TYPING_DELAY = 0.001
LOREMIPSUM = "<p>Lorem ipsum dolor sit amet.</p>"


class TestMainWindowMixin(object):

    def swipe_chrome_up(self, distance):
        view = self.main_window.get_qml_view()
        x_line = int(view.x + view.width * 0.5)
        start_y = int(view.y + view.height - 1)
        stop_y = int(start_y - distance)
        self.pointing_device.drag(x_line, start_y, x_line, stop_y)

    def swipe_chrome_down(self, distance):
        view = self.main_window.get_qml_view()
        x_line = int(view.x + view.width * 0.5)
        start_y = int(self.main_window.get_chrome().globalRect[1])
        stop_y = int(start_y + distance)
        self.pointing_device.drag(x_line, start_y, x_line, stop_y)

    def reveal_chrome(self):
        self.swipe_chrome_up(self.main_window.get_chrome().height)

    def hide_chrome(self):
        self.swipe_chrome_down(self.main_window.get_chrome().height)

    def assert_chrome_eventually_shown(self):
        view = self.main_window.get_qml_view()
        chrome = self.main_window.get_chrome()
        expected_y = view.y + view.height - chrome.height
        self.assertThat(lambda: chrome.globalRect[1],
                        Eventually(Equals(expected_y)))

    def assert_chrome_hidden(self):
        view = self.main_window.get_qml_view()
        chrome = self.main_window.get_chrome()
        self.assertThat(chrome.globalRect[1], Equals(view.y + view.height))

    def assert_chrome_eventually_hidden(self):
        view = self.main_window.get_qml_view()
        chrome = self.main_window.get_chrome()
        self.assertThat(lambda: chrome.globalRect[1],
                        Eventually(Equals(view.y + view.height)))

    def go_to_url(self, url):
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
        self.keyboard.press("Enter")

    def assert_page_eventually_loaded(self, url):
        webview = self.main_window.get_web_view()
        self.assertThat(webview.url, Eventually(Equals(url)))


class TestMainWindow(BrowserTestCaseBase, TestMainWindowMixin):

    """Tests the main browser features"""

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
        self.pointing_device.move_to_object(webview)
        self.pointing_device.click()
        self.assert_chrome_eventually_hidden()

    def test_swipe_down_hidden_chrome_doesnt_reveal_it(self):
        view = self.main_window.get_qml_view()
        x_line = int(view.x + view.width * 0.5)
        start_y = int(view.y + view.height - 1)
        stop_y = start_y + 20
        self.pointing_device.drag(x_line, start_y, x_line, stop_y)
        self.assert_chrome_eventually_hidden()

    def test_swipe_shown_chrome_up_doesnt_hide_it(self):
        view = self.main_window.get_qml_view()
        chrome = self.main_window.get_chrome()
        self.reveal_chrome()
        x_line = int(view.x + view.width * 0.5)
        start_y = int(chrome.globalRect[1])
        stop_y = int(view.y - 1)
        self.pointing_device.drag(x_line, start_y, x_line, stop_y)
        self.assert_chrome_eventually_shown()

    def test_open_website(self):
        self.reveal_chrome()
        address_bar = self.main_window.get_address_bar()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()
        clear_button = self.main_window.get_address_bar_clear_button()
        self.pointing_device.move_to_object(clear_button)
        self.pointing_device.click()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()

        self.keyboard.type("http://www.canonical.com", delay=TYPING_DELAY)
        self.keyboard.press("Enter")

        web_view = self.main_window.get_web_view()
        self.assertThat(web_view.url,
                        Eventually(Equals("http://www.canonical.com/")))

    def test_title(self):
        url = self.make_html_page("Alice in Wonderland", LOREMIPSUM)

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
        self.keyboard.press("Enter")

        window = self.main_window.get_qml_view()
        self.assertThat(window.title,
            Eventually(Equals("Alice in Wonderland - Ubuntu Web Browser")))


class TestMainWindowChromeless(BrowserTestCaseBase):

    """Tests the main browser features when run in chromeless mode."""

    ARGS = ['--chromeless']

    def test_chrome_is_not_loaded(self):
        self.assertThat(self.main_window.get_chrome(), Equals(None))


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


class TestMainWindowHistory(TestMainWindowStartOpenLocalPageBase,
                            TestMainWindowMixin):

    """Tests the back and forward functionality."""

    def click_back_button(self):
        self.reveal_chrome()
        back_button = self.main_window.get_back_button()
        self.pointing_device.move_to_object(back_button)
        self.pointing_device.click()

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


class TestMainWindowErrorSheet(TestMainWindowStartOpenLocalPageBase,
                               TestMainWindowMixin):

    """Tests the error message functionality."""

    def test_invalid_url_triggers_error_message(self):
        error = self.main_window.get_error_sheet()
        self.assertThat(error.visible, Equals(False))
        self.go_to_url("http://invalid")
        self.assertThat(error.visible, Eventually(Equals(True)))

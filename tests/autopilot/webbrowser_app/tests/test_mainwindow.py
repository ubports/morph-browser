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

from webbrowser_app.tests import BrowserTestCaseBase, \
                                    BrowserTestCaseBaseWithHTTPServer, \
                                    HTTP_SERVER_PORT
import os.path
import random
import sqlite3
import time

TYPING_DELAY = 0.001
LOREMIPSUM = "<p>Lorem ipsum dolor sit amet.</p>"


class TestMainWindowMixin(object):

    def swipe_chrome_up(self, distance):
        view = self.main_window.get_qml_view()
        x_line = int(view.x + view.width * 0.5)
        start_y = int(view.y + view.height - 1)
        stop_y = int(start_y - distance)
        self.mouse.drag(x_line, start_y, x_line, stop_y)

    def swipe_chrome_down(self, distance):
        view = self.main_window.get_qml_view()
        x_line = int(view.x + view.width * 0.5)
        start_y = int(self.main_window.get_chrome().globalRect[1])
        stop_y = int(start_y + distance)
        self.mouse.drag(x_line, start_y, x_line, stop_y)

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
        self.mouse.move_to_object(address_bar)
        self.mouse.click()
        clear_button = self.main_window.get_address_bar_clear_button()
        self.mouse.move_to_object(clear_button)
        self.mouse.click()
        self.mouse.move_to_object(address_bar)
        self.mouse.click()
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

    def test_open_website(self):
        self.reveal_chrome()
        address_bar = self.main_window.get_address_bar()
        self.mouse.move_to_object(address_bar)
        self.mouse.click()
        clear_button = self.main_window.get_address_bar_clear_button()
        self.mouse.move_to_object(clear_button)
        self.mouse.click()
        self.mouse.move_to_object(address_bar)
        self.mouse.click()

        self.keyboard.type("http://www.canonical.com", delay=TYPING_DELAY)
        self.keyboard.press("Enter")

        web_view = self.main_window.get_web_view()
        self.assertThat(web_view.url,
                        Eventually(Equals("http://www.canonical.com/")))

    def test_title(self):
        url = self.make_html_page("Alice in Wonderland", LOREMIPSUM)

        self.reveal_chrome()
        address_bar = self.main_window.get_address_bar()
        self.mouse.move_to_object(address_bar)
        self.mouse.click()
        clear_button = self.main_window.get_address_bar_clear_button()
        self.mouse.move_to_object(clear_button)
        self.mouse.click()
        self.mouse.move_to_object(address_bar)
        self.mouse.click()
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


class TestMainWindowBackForward(TestMainWindowStartOpenLocalPageBase,
                                TestMainWindowMixin):

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


class TestMainWindowErrorSheet(TestMainWindowStartOpenLocalPageBase,
                               TestMainWindowMixin):

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


class TestMainWindowAddressBarStates(TestMainWindowStartOpenRemotePageBase,
                                     TestMainWindowMixin):

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


class TestMainWindowAddressBarSelection(TestMainWindowStartOpenRemotePageBase,
                                        TestMainWindowMixin):

    """Test the address bar selection"""
    def test_click_to_select(self):
        self.reveal_chrome()
        address_bar = self.main_window.get_address_bar()
        self.mouse.move_to_object(address_bar)
        self.mouse.click()
        text_field = self.main_window.get_address_bar_text_field()
        self.assertThat(text_field.selectedText, Eventually(Equals(text_field.text)))

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
        self.assertThat(lambda: len(text_field.selectedText), Eventually(GreaterThan(0)))


class TestMainWindowPrepopulatedHistoryDatabase(BrowserTestCaseBase):

    """Helper test class that pre-populates the history database."""

    def setUp(self):
        super(TestMainWindowPrepopulatedHistoryDatabase, self).setUp()
        self.clear_cache()
        db_path = os.path.join(os.path.expanduser("~"), ".local", "share",
                               "webbrowser-app", "history.sqlite")
        connection = sqlite3.connect(db_path)
        connection.execute("""CREATE TABLE IF NOT EXISTS history
                              (url VARCHAR, title VARCHAR, icon VARCHAR,
                               visits INTEGER, lastVisit DATETIME);""")
        rows = [("http://www.ubuntu.com/", "Home | Ubuntu"),
                ("http://www.google.com/search?client=ubuntu&q=ubuntu&ie=utf-8&oe=utf-8", "ubuntu - Google Search"),
                ("http://en.wikipedia.org/wiki/Ubuntu_(operating_system)", "Ubuntu (operating system) - Wikipedia, the free encyclopedia"),
                ("http://en.wikipedia.org/wiki/Ubuntu_(philosophy)", "Ubuntu (philosophy) - Wikipedia, the free encyclopedia"),
                ("http://www.google.com/search?client=ubuntu&q=example&ie=utf-8&oe=utf-8", "example - Google Search"),
                ("http://example.iana.org/", "Example Domain"),
                ("http://www.iana.org/domains/special", "IANA — Special Use Domains")]
        for i, row in enumerate(rows):
            visits = random.randint(1, 5)
            timestamp = int(time.time()) - i * 10
            query = "INSERT INTO history VALUES ('%s', '%s', '', %d, %d);" % \
                    (row[0], row[1], visits, timestamp)
            connection.execute(query)
        connection.commit()
        connection.close()


class TestMainWindowHistorySuggestions(TestMainWindowPrepopulatedHistoryDatabase,
                                       TestMainWindowMixin):

    """Test the address bar suggestions based on navigation history."""

    def test_show_list_of_suggestions(self):
        suggestions = self.main_window.get_address_bar_suggestions()
        listview = self.main_window.get_address_bar_suggestions_listview()
        self.assertThat(suggestions.visible, Equals(False))
        self.reveal_chrome()
        self.assertThat(suggestions.visible, Equals(False))
        address_bar = self.main_window.get_address_bar()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()
        self.assertThat(suggestions.visible, Eventually(Equals(True)))
        self.assertThat(listview.count, Eventually(Equals(1)))
        clear_button = self.main_window.get_address_bar_clear_button()
        self.pointing_device.move_to_object(clear_button)
        self.pointing_device.click()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()
        self.assertThat(suggestions.visible, Eventually(Equals(False)))
        self.keyboard.type("u", delay=TYPING_DELAY)
        self.assertThat(suggestions.visible, Eventually(Equals(True)))
        self.assertThat(listview.count, Eventually(Equals(6)))
        self.keyboard.type("b", delay=TYPING_DELAY)
        self.assertThat(listview.count, Eventually(Equals(5)))
        self.keyboard.type("leh", delay=TYPING_DELAY)
        self.assertThat(listview.count, Eventually(Equals(0)))

    def test_clear_address_bar_dismisses_suggestions(self):
        suggestions = self.main_window.get_address_bar_suggestions()
        self.reveal_chrome()
        address_bar = self.main_window.get_address_bar()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()
        self.assertThat(suggestions.visible, Eventually(Equals(True)))
        clear_button = self.main_window.get_address_bar_clear_button()
        self.pointing_device.move_to_object(clear_button)
        self.pointing_device.click()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()
        self.keyboard.type("ubuntu", delay=TYPING_DELAY)
        self.assertThat(suggestions.visible, Eventually(Equals(True)))
        self.pointing_device.move_to_object(clear_button)
        self.pointing_device.click()
        self.assertThat(suggestions.visible, Eventually(Equals(False)))

    def test_addressbar_loosing_focus_dismisses_suggestions(self):
        suggestions = self.main_window.get_address_bar_suggestions()
        self.reveal_chrome()
        address_bar = self.main_window.get_address_bar()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()
        self.assertThat(suggestions.visible, Eventually(Equals(True)))
        coord = suggestions.globalRect
        webview = self.main_window.get_web_view()
        self.pointing_device.move(coord[0] + int(coord[2] / 2),
                                  int((coord[1] + webview.globalRect[1]) / 2))
        self.pointing_device.click()
        self.assertThat(suggestions.visible, Eventually(Equals(False)))

    def test_select_suggestion(self):
        suggestions = self.main_window.get_address_bar_suggestions()
        listview = self.main_window.get_address_bar_suggestions_listview()
        self.reveal_chrome()
        address_bar = self.main_window.get_address_bar()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()
        self.assertThat(suggestions.visible, Eventually(Equals(True)))
        clear_button = self.main_window.get_address_bar_clear_button()
        self.pointing_device.move_to_object(clear_button)
        self.pointing_device.click()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()
        self.keyboard.type("ubuntu", delay=TYPING_DELAY)
        self.assertThat(listview.count, Eventually(Equals(5)))
        entries = self.main_window.get_address_bar_suggestions_listview_entries()
        entry = entries[2]
        url = "http://en.wikipedia.org/wiki/<b>Ubuntu</b>_(operating_system)"
        self.assertThat(entry.subText, Equals(url))
        self.pointing_device.move_to_object(entry)
        self.pointing_device.click()
        webview = self.main_window.get_web_view()
        url = "http://en.wikipedia.org/wiki/Ubuntu_(operating_system)"
        self.assertThat(webview.url, Eventually(Equals(url)))

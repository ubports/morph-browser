# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2015-2017 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

import os
import sqlite3
import time
import testtools

from testtools.matchers import Equals, Mismatch, NotEquals, GreaterThan
from autopilot import exceptions
from autopilot.matchers import Eventually
from autopilot.platform import model

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class PrepopulatedDatabaseTestCaseBase(StartOpenRemotePageTestCaseBase):

    """Helper test class that pre-populates history and bookmarks databases."""

    def setUp(self):
        self.create_temporary_profile()
        self.populate_bookmarks()
        super(PrepopulatedDatabaseTestCaseBase, self).setUp("/tab/0")

    def populate_bookmarks(self):
        db_path = os.path.join(self.data_location, "bookmarks.sqlite")
        connection = sqlite3.connect(db_path)
        connection.execute("""CREATE TABLE IF NOT EXISTS bookmarks
                              (url VARCHAR, title VARCHAR, icon VARCHAR,
                              created INTEGER, folderId INTEGER);""")
        rows = [
            ("http://www.rsc.org/periodic-table/element/77/iridium",
             "Iridium - Element Information")
        ]

        for i, row in enumerate(rows):
            timestamp = int(time.time()) - i * 10
            query = "INSERT INTO bookmarks \
                     VALUES ('{}', '{}', '', {}, '');"
            query = query.format(row[0], row[1], timestamp)
            connection.execute(query)

        connection.commit()
        connection.close()


class AlmostEquals(object):

    def __init__(self, expected):
        self.expected = expected

    def match(self, actual):
        if round(actual - self.expected, 3) == 0:
            return None
        else:
            msg = "{} is not almost equal to {}"
            return Mismatch(msg.format(actual, self.expected))


@testtools.skipIf(model() != "Desktop", "on desktop only")
class TestKeyboard(PrepopulatedDatabaseTestCaseBase):

    """Test keyboard interaction"""

    def setUp(self):
        super(TestKeyboard, self).setUp()
        self.address_bar = self.main_window.address_bar

    def open_tab(self, url):
        self.main_window.press_key('Ctrl+t')
        new_tab_view = self.main_window.get_new_tab_view()
        self.address_bar.go_to_url(url)
        new_tab_view.wait_until_destroyed()
        self.assertThat(lambda: self.main_window.get_current_webview().url,
                        Eventually(Equals(url)))

    # Name tabs starting from 1 by default because tab 0 has been opened
    # already via StartOpenRemotePageTestCaseBase
    def open_tabs(self, count, base=1):
        for i in range(0, count):
            self.open_tab(self.base_url + "/tab/" + str(i + base))

    def check_tab_number(self, number):
        url = self.base_url + "/tab/" + str(number)
        self.assertThat(lambda: self.main_window.get_current_webview().url,
                        Eventually(Equals(url)))

    def test_new_tab(self):
        self.main_window.press_key('Ctrl+t')
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.url, Equals(""))
        new_tab_view = self.main_window.get_new_tab_view()
        self.assertThat(new_tab_view.visible, Eventually(Equals(True)))

    def test_switch_tabs(self):
        self.open_tabs(2)
        self.check_tab_number(2)
        self.main_window.press_key('Ctrl+Tab')
        self.check_tab_number(0)
        self.main_window.press_key('Ctrl+Tab')
        self.check_tab_number(1)
        self.main_window.press_key('Ctrl+Tab')
        self.check_tab_number(2)
        self.main_window.press_key('Ctrl+Page_Down')
        self.check_tab_number(0)
        self.main_window.press_key('Ctrl+Shift+Tab')
        if self.main_window.wide:
            self.check_tab_number(2)
        else:
            self.check_tab_number(1)
        self.main_window.press_key('Ctrl+Page_Up')
        if self.main_window.wide:
            self.check_tab_number(1)
        else:
            self.check_tab_number(2)

    def test_can_switch_tabs_after_suggestions_escape(self):
        self.open_tabs(1)
        self.check_tab_number(1)

        suggestions = self.main_window.get_suggestions()
        self.address_bar.write('el')
        self.assertThat(suggestions.opacity, Eventually(Equals(1)))
        self.main_window.press_key('Down')
        self.assertThat(suggestions.activeFocus, Eventually(Equals(True)))

        self.main_window.press_key('Escape')
        self.assertThat(suggestions.opacity, Eventually(Equals(0)))

        self.main_window.press_key('Ctrl+Tab')
        self.check_tab_number(0)

    def test_switch_tabs_from_tabs_view(self):
        if self.main_window.wide:
            self.skipTest("Only on narrow form factors")
        self.open_tabs(1)
        self.check_tab_number(1)
        tabs = self.open_tabs_view()
        self.main_window.press_key('Ctrl+Tab')
        self.check_tab_number(0)
        self.main_window.press_key('Ctrl+Tab')
        self.check_tab_number(1)
        self.main_window.press_key('Ctrl+Tab')
        self.check_tab_number(0)
        self.main_window.press_key('Escape')
        self.assertThat(tabs.visible, Eventually(Equals(False)))
        self.check_tab_number(0)

    def test_close_tabs_ctrl_f4(self):
        wide = self.main_window.wide
        self.open_tabs(1)
        self.check_tab_number(1)
        self.main_window.press_key('Ctrl+F4')
        self.check_tab_number(0)
        self.main_window.press_key('Ctrl+F4')
        if wide:
            # closing the last open tab exits the application
            self.app.process.wait()
        else:
            webview = self.main_window.get_current_webview()
            self.assertThat(webview.url, Equals(""))

    def test_close_tabs_ctrl_w(self):
        wide = self.main_window.wide
        self.open_tabs(1)
        self.check_tab_number(1)
        self.main_window.press_key('Ctrl+w')
        self.check_tab_number(0)
        self.main_window.press_key('Ctrl+w')
        if wide:
            # closing the last open tab exits the application
            self.app.process.wait()
        else:
            webview = self.main_window.get_current_webview()
            self.assertThat(webview.url, Equals(""))

    def test_close_tabs_tabs_view(self):
        if self.main_window.wide:
            self.skipTest("Only on narrow form factors")
        self.open_tabs(1)
        self.check_tab_number(1)
        self.open_tabs_view()
        self.main_window.press_key('Ctrl+w')
        self.check_tab_number(0)
        self.main_window.press_key('Ctrl+F4')
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.url, Equals(""))

    def test_select_address_bar_ctrl_l(self):
        self.main_window.press_key('Ctrl+l')
        self.assertThat(self.address_bar.text_field.selectedText,
                        Eventually(Equals(self.address_bar.text_field.text)))

    def test_select_address_bar_alt_d(self):
        self.main_window.press_key('Alt+d')
        self.assertThat(self.address_bar.text_field.selectedText,
                        Eventually(Equals(self.address_bar.text_field.text)))

    def test_select_address_bar_f6(self):
        self.main_window.press_key('F6')
        self.assertThat(self.address_bar.text_field.selectedText,
                        Eventually(Equals(self.address_bar.text_field.text)))

    def test_escape_from_address_bar(self):
        self.main_window.press_key('Alt+d')
        self.assertThat(self.address_bar.text_field.selectedText,
                        Eventually(Equals(self.address_bar.text_field.text)))
        self.main_window.press_key('Escape')
        self.assertThat(self.address_bar.text_field.selectedText,
                        Eventually(Equals("")))
        self.assertThat(self.address_bar.activeFocus,
                        Eventually(Equals(False)))
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.activeFocus, Eventually(Equals(True)))

    def test_reload(self):
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.loading, Eventually(Equals(False)))

        watcher = webview.watch_signal('loadingStateChanged()')
        previous = watcher.num_emissions

        self.main_window.press_key('Ctrl+r')
        self.assertThat(
            lambda: watcher.num_emissions,
            Eventually(GreaterThan(previous)))

        self.assertThat(webview.loading, Eventually(Equals(False)))

        previous = watcher.num_emissions

        self.main_window.press_key('F5')
        self.assertThat(
            lambda: watcher.num_emissions,
            Eventually(GreaterThan(previous)))

        self.assertThat(webview.loading, Eventually(Equals(False)))

    def test_bookmark(self):
        chrome = self.main_window.chrome
        self.assertThat(chrome.bookmarked, Equals(False))
        self.main_window.press_key('Ctrl+d')
        self.assertThat(chrome.bookmarked, Eventually(Equals(True)))
        self.main_window.press_key('Escape')
        self.assertThat(chrome.bookmarked, Eventually(Equals(False)))
        self.main_window.press_key('Ctrl+d')
        self.assertThat(chrome.bookmarked, Eventually(Equals(True)))
        self.main_window.press_key('Ctrl+d')
        self.assertThat(chrome.bookmarked, Eventually(Equals(False)))

    def test_cannot_bookmark_empty_tab(self):
        self.main_window.press_key('Ctrl+t')
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.url, Equals(""))
        new_tab_view = self.main_window.get_new_tab_view()
        self.assertThat(new_tab_view.visible, Eventually(Equals(True)))
        self.main_window.press_key('Ctrl+d')
        time.sleep(2)
        try:
            self.main_window.get_bookmark_options()
        except exceptions.StateNotFoundError:
            pass
        else:
            self.fail("Bookmarking an empty tab should not be allowed")

    def test_history_navigation_with_alt_arrows(self):
        previous = self.main_window.get_current_webview().url
        url = self.base_url + "/test2"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)

        self.main_window.press_key('Alt+Left')
        self.assertThat(lambda: self.main_window.get_current_webview().url,
                        Eventually(Equals(previous)))

        self.main_window.press_key('Alt+Right')
        self.assertThat(lambda: self.main_window.get_current_webview().url,
                        Eventually(Equals(url)))

    def test_history_navigation_with_backspace(self):
        previous = self.main_window.get_current_webview().url
        url = self.base_url + "/test2"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)

        self.main_window.press_key('Backspace')
        self.assertThat(lambda: self.main_window.get_current_webview().url,
                        Eventually(Equals(previous)))

        self.main_window.press_key('Shift+Backspace')
        self.assertThat(lambda: self.main_window.get_current_webview().url,
                        Eventually(Equals(url)))

    def test_backspace_does_not_go_back_when_html_text_field_focused(self):
        # Regression test for https://launchpad.net/bugs/1569938
        url = self.base_url + "/textarea"
        self.main_window.go_to_url(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        self.main_window.press_key('Backspace')
        time.sleep(2)
        self.assertThat(webview.url, Equals(url))

    def test_toggle_bookmarks(self):
        self.assertThat(self.main_window.get_bookmarks_view(), Equals(None))
        self.main_window.press_key('Ctrl+Shift+o')
        self.assertThat(lambda: self.main_window.get_bookmarks_view(),
                        Eventually(NotEquals(None)))
        bookmarks_view = self.main_window.get_bookmarks_view()

        self.main_window.press_key('Escape')
        bookmarks_view.wait_until_destroyed()
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.activeFocus, Eventually(Equals(True)))

    def test_toggle_bookmarks_from_menu(self):
        self.assertThat(self.main_window.get_bookmarks_view(), Equals(None))
        self.open_bookmarks()
        bookmarks_view = self.main_window.get_bookmarks_view()
        self.assertThat(bookmarks_view.activeFocus, Eventually(Equals(True)))

        self.main_window.press_key('Escape')
        bookmarks_view.wait_until_destroyed()

    def test_new_tab_from_bookmarks_view(self):
        self.assertThat(self.main_window.get_bookmarks_view(), Equals(None))
        self.open_bookmarks()
        bookmarks_view = self.main_window.get_bookmarks_view()
        self.assertThat(bookmarks_view.activeFocus, Eventually(Equals(True)))

        self.main_window.press_key('Ctrl+t')
        bookmarks_view.wait_until_destroyed()

        new_tab_view = self.main_window.get_new_tab_view()
        self.assertThat(new_tab_view.visible, Eventually(Equals(True)))

    def test_toggle_history(self):
        self.assertThat(self.main_window.get_history_view(), Equals(None))
        self.main_window.press_key('Ctrl+h')
        self.assertThat(lambda: self.main_window.get_history_view(),
                        Eventually(NotEquals(None)))
        history_view = self.main_window.get_history_view()

        self.main_window.press_key('Escape')
        history_view.wait_until_destroyed()
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.activeFocus, Eventually(Equals(True)))

    def test_toggle_history_from_menu(self):
        self.assertThat(self.main_window.get_history_view(), Equals(None))
        self.open_history()
        history_view = self.main_window.get_history_view()
        self.assertThat(history_view.activeFocus, Eventually(Equals(True)))

        self.main_window.press_key('Escape')
        history_view.wait_until_destroyed()

    def test_new_tab_from_history_view(self):
        self.assertThat(self.main_window.get_history_view(), Equals(None))
        self.open_history()
        history_view = self.main_window.get_history_view()
        self.assertThat(history_view.activeFocus, Eventually(Equals(True)))

        self.main_window.press_key('Ctrl+t')
        history_view.wait_until_destroyed()

        new_tab_view = self.main_window.get_new_tab_view()
        self.assertThat(new_tab_view.visible, Eventually(Equals(True)))

    def test_search_in_history(self):
        if not self.main_window.wide:
            self.skipTest("Only on wide form factors")

        self.assertThat(self.main_window.get_history_view(), Equals(None))
        self.main_window.press_key('Ctrl+h')
        self.assertThat(lambda: self.main_window.get_history_view(),
                        Eventually(NotEquals(None)))
        history_view = self.main_window.get_history_view()

        self.main_window.press_key('Ctrl+f')
        self.assertThat(history_view.searchMode, Eventually(Equals(True)))
        search_field = history_view.get_search_field()
        self.assertThat(search_field.visible, Equals(True))
        self.assertThat(search_field.activeFocus, Eventually(Equals(True)))

        self.main_window.press_key('Escape')
        self.assertThat(history_view.searchMode, Eventually(Equals(False)))
        search_field.wait_until_destroyed()

        self.main_window.press_key('Escape')
        history_view.wait_until_destroyed()

    def test_open_history_exits_findinpage(self):
        address_bar = self.main_window.chrome.address_bar
        self.main_window.press_key('Ctrl+f')
        self.assertThat(address_bar.findInPageMode, Eventually(Equals(True)))
        self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))

        self.main_window.press_key('Ctrl+h')
        self.assertThat(lambda: self.main_window.get_history_view(),
                        Eventually(NotEquals(None)))
        history_view = self.main_window.get_history_view()
        self.assertThat(address_bar.findInPageMode, Eventually(Equals(False)))
        self.assertThat(address_bar.activeFocus, Eventually(Equals(False)))

        self.main_window.press_key('Escape')
        history_view.wait_until_destroyed()

    def test_open_bookmarks_exits_findinpage(self):
        address_bar = self.main_window.chrome.address_bar
        self.main_window.press_key('Ctrl+f')
        self.assertThat(address_bar.findInPageMode, Eventually(Equals(True)))
        self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))

        self.main_window.press_key('Ctrl+Shift+o')
        self.assertThat(lambda: self.main_window.get_bookmarks_view(),
                        Eventually(NotEquals(None)))
        bookmarks_view = self.main_window.get_bookmarks_view()
        self.assertThat(address_bar.findInPageMode, Eventually(Equals(False)))
        self.assertThat(address_bar.activeFocus, Eventually(Equals(False)))

        self.main_window.press_key('Escape')
        bookmarks_view.wait_until_destroyed()

    def test_open_settings_exits_findinpage(self):
        address_bar = self.main_window.chrome.address_bar
        self.main_window.press_key('Ctrl+f')
        self.assertThat(address_bar.findInPageMode, Eventually(Equals(True)))
        self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))

        settings = self.open_settings()
        self.assertThat(address_bar.findInPageMode, Eventually(Equals(False)))
        self.assertThat(address_bar.activeFocus, Eventually(Equals(False)))

        self.main_window.press_key('Escape')
        settings.wait_until_destroyed()

    def test_escape_settings(self):
        settings = self.open_settings()
        self.main_window.press_key('Escape')
        settings.wait_until_destroyed()
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.activeFocus, Eventually(Equals(True)))

    def test_find_in_page_ctrl_f(self):
        address_bar = self.main_window.chrome.address_bar
        self.assertThat(address_bar.findInPageMode, Equals(False))
        self.main_window.press_key('Ctrl+f')
        self.assertThat(address_bar.findInPageMode, Eventually(Equals(True)))
        self.main_window.press_key('Escape')
        self.assertThat(address_bar.findInPageMode, Eventually(Equals(False)))
        if not self.main_window.wide:
            self.open_tabs_view()
        self.open_new_tab()
        self.main_window.press_key('Ctrl+f')
        self.assertThat(address_bar.findInPageMode, Equals(False))

    def test_find_previous_and_next(self):
        url = self.base_url + "/findinpage"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        address_bar = self.main_window.chrome.address_bar
        self.main_window.press_key('Ctrl+f')
        self.assertThat(address_bar.findInPageMode, Eventually(Equals(True)))
        address_bar.write("e")
        counter = address_bar.get_find_in_page_counter()
        self.assertThat(counter.count, Eventually(Equals(4)))
        self.assertThat(counter.current, Eventually(Equals(1)))
        for i in [2, 3, 4, 1, 2, 3, 4, 1, 2]:
            self.main_window.press_key('Ctrl+g')
            self.assertThat(counter.current, Eventually(Equals(i)))
        for i in [1, 4, 3, 2, 1, 4, 3, 2]:
            self.main_window.press_key('Ctrl+Shift+g')
            self.assertThat(counter.current, Eventually(Equals(i)))

    def test_navigate_between_address_bar_and_new_tab_view(self):
        if not self.main_window.wide:
            self.skipTest("Only on wide form factors")

        address_bar = self.main_window.chrome.address_bar

        self.main_window.press_key('Ctrl+t')
        new_tab_view = self.main_window.get_new_tab_view()
        self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))

        self.main_window.press_key('Down')
        self.assertThat(address_bar.activeFocus, Eventually(Equals(False)))
        self.assertThat(new_tab_view.activeFocus, Eventually(Equals(True)))

        self.main_window.press_key('Up')
        self.assertThat(new_tab_view.activeFocus, Eventually(Equals(False)))
        self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))

    def test_ctrl_w_closes_tabs_only_from_main_view(self):
        # Verify that Ctrl+w doesn’t work when either the history
        # view, the bookmarks view or the settings view are shown
        # (https://launchpad.net/bugs/1524353).
        self.main_window.press_key('Ctrl+t')
        self.assert_number_webviews_eventually(2)

        history_view = self.open_history()
        self.main_window.press_key('Ctrl+w')
        self.main_window.press_key('Escape')
        history_view.wait_until_destroyed()
        self.assert_number_webviews_eventually(2)

        bookmarks_view = self.open_bookmarks()
        self.main_window.press_key('Ctrl+w')
        self.main_window.press_key('Escape')
        bookmarks_view.wait_until_destroyed()
        self.assert_number_webviews_eventually(2)

        settings_view = self.open_settings()
        self.main_window.press_key('Ctrl+w')
        self.main_window.press_key('Escape')
        settings_view.wait_until_destroyed()
        self.assert_number_webviews_eventually(2)

        self.main_window.press_key('Ctrl+w')
        self.assert_number_webviews_eventually(1)

    def test_addressbar_cleared_when_opening_new_tab(self):
        # Verify that when opening a new tab while the address bar was focused,
        # the address bar is cleared.
        self.main_window.press_key('Ctrl+l')
        self.address_bar.activeFocus.wait_for(True)
        self.assertThat(self.address_bar.text, Eventually(Equals(self.url)))
        self.main_window.press_key('Ctrl+t')
        self.address_bar.activeFocus.wait_for(True)
        self.assertThat(self.address_bar.text, Eventually(Equals("")))

    def test_addressbar_cleared_when_switching_between_new_tabs(self):
        # Verify that when opening a new tab while a new tab was already open
        # with text input in the address bar, the address bar is cleared.
        self.main_window.press_key('Ctrl+t')
        self.address_bar.activeFocus.wait_for(True)
        self.assertThat(self.address_bar.text, Eventually(Equals("")))
        self.address_bar.write("abc")
        self.main_window.press_key('Ctrl+t')
        self.address_bar.activeFocus.wait_for(True)
        self.assertThat(self.address_bar.text, Eventually(Equals("")))

    def test_zoom_in_and_out(self):
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.zoomFactor, Eventually(AlmostEquals(1.0)))

        zooms = [1.1, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 4.0, 5.0]
        for zoom in zooms:
            self.main_window.press_key('Ctrl+plus')
            self.assertThat(webview.zoomFactor, Eventually(AlmostEquals(zoom)))

        self.main_window.press_key('Ctrl+0')
        self.assertThat(webview.zoomFactor, Eventually(AlmostEquals(1.0)))

        zooms = [0.9, 0.75, 0.666, 0.5, 0.333, 0.25]
        for zoom in zooms:
            self.main_window.press_key('Ctrl+minus')
            self.assertThat(webview.zoomFactor, Eventually(AlmostEquals(zoom)))

        self.main_window.press_key('Ctrl+0')
        self.assertThat(webview.zoomFactor, Eventually(AlmostEquals(1.0)))

    def test_zoom_qwerty_compatibility_shortcuts(self):
        # Ref: https://launchpad.net/bugs/1624381
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.zoomFactor, Eventually(AlmostEquals(1.0)))

        self.main_window.press_key('Ctrl+equal')
        self.assertThat(webview.zoomFactor, Eventually(AlmostEquals(1.1)))

        self.main_window.press_key('Ctrl+underscore')
        self.assertThat(webview.zoomFactor, Eventually(AlmostEquals(1.0)))

    def test_zoom_affects_domain(self):
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.zoomFactor, Eventually(AlmostEquals(1.0)))

        self.open_tabs(1)
        self.check_tab_number(1)
        self.main_window.press_key('Ctrl+plus')
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.zoomFactor, Eventually(AlmostEquals(1.1)))

        self.main_window.press_key('Ctrl+Tab')
        self.check_tab_number(0)
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.zoomFactor, Eventually(AlmostEquals(1.1)))

    def test_new_window(self):
        self.main_window.press_key('Ctrl+n')
        self.assertThat(lambda: len(self.app.get_windows(incognito=False)),
                        Eventually(Equals(2)))
        window = self.app.get_windows(activeFocus=True)[0]
        if window.wide:
            window.press_key('Ctrl+w')
            window.wait_until_destroyed()
            windows = self.app.get_windows(activeFocus=True, incognito=False)
            self.assertThat(len(windows), Equals(1))

    def test_new_private_window(self):
        self.main_window.press_key('Ctrl+Shift+n')
        self.assertThat(lambda: len(self.app.get_windows(incognito=True)),
                        Eventually(Equals(1)))
        window = self.app.get_windows(activeFocus=True, incognito=True)[0]
        if window.wide:
            window.press_key('Ctrl+w')
            window.wait_until_destroyed()
            windows = self.app.get_windows(activeFocus=True, incognito=False)
            self.assertThat(len(windows), Equals(1))

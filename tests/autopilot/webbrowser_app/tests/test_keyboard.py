# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2015 Canonical
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
import unittest

from testtools.matchers import Contains, Equals, NotEquals, GreaterThan
from autopilot.matchers import Eventually
from autopilot.platform import model

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase
from . import http_server

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
                              created INTEGER);""")
        rows = [
            ("http://www.rsc.org/periodic-table/element/77/iridium",
             "Iridium - Element Information")
        ]

        for i, row in enumerate(rows):
            timestamp = int(time.time()) - i * 10
            query = "INSERT INTO bookmarks \
                     VALUES ('{}', '{}', '', {});"
            query = query.format(row[0], row[1], timestamp)
            connection.execute(query)

        connection.commit()
        connection.close()


# Use PrepopulatedDatabaseTestCaseBase to ensure that at least one suggestion
# will appear in the suggestions menu by creating a bookmark we can search for
class TestKeyboard(PrepopulatedDatabaseTestCaseBase):

    """Test keyboard interaction"""

    def setUp(self):
        super(TestKeyboard, self).setUp()
        self.address_bar = self.main_window.address_bar

    def open_tab(self, url):
        self.main_window.press_key('Ctrl+T')
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

    @unittest.skipIf(model() != "Desktop", "on desktop only")
    def test_new_tab(self):
        self.main_window.press_key('Ctrl+T')

        webview = self.main_window.get_current_webview()
        self.assertThat(webview.url, Equals(""))
        new_tab_view = self.main_window.get_new_tab_view()
        self.assertThat(new_tab_view.visible, Eventually(Equals(True)))

    @unittest.skipIf(model() != "Desktop", "on desktop only")
    def test_switch_tabs(self):
        self.open_tabs(2)
        self.check_tab_number(2)
        self.main_window.press_key('Ctrl+Tab')
        self.check_tab_number(0)
        self.main_window.press_key('Ctrl+Tab')
        self.check_tab_number(1)
        self.main_window.press_key('Ctrl+Tab')
        self.check_tab_number(2)

    @unittest.skipIf(model() != "Desktop", "on desktop only")
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

    @unittest.skipIf(model() != "Desktop", "on desktop only")
    def test_close_tabs_ctrl_f4(self):
        self.open_tabs(1)
        self.check_tab_number(1)
        self.main_window.press_key('Ctrl+F4')
        self.check_tab_number(0)
        self.main_window.press_key('Ctrl+F4')
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.url, Equals(""))

    @unittest.skipIf(model() != "Desktop", "on desktop only")
    def test_close_tabs_ctrl_w(self):
        self.open_tabs(1)
        self.check_tab_number(1)
        self.main_window.press_key('Ctrl+w')
        self.check_tab_number(0)
        self.main_window.press_key('Ctrl+w')
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.url, Equals(""))

    @unittest.skipIf(model() != "Desktop", "on desktop only")
    def test_select_address_bar_ctrl_l(self):
        self.main_window.press_key('Ctrl+L')
        self.assertThat(self.address_bar.text_field.selectedText,
                        Eventually(Equals(self.address_bar.text_field.text)))

    @unittest.skipIf(model() != "Desktop", "on desktop only")
    def test_select_address_bar_ctrl_l(self):
        self.main_window.press_key('Ctrl+L')
        self.assertThat(self.address_bar.text_field.selectedText,
                        Eventually(Equals(self.address_bar.text_field.text)))

    @unittest.skipIf(model() != "Desktop", "on desktop only")
    def test_select_address_bar_alt_d(self):
        self.main_window.press_key('Alt+D')
        self.assertThat(self.address_bar.text_field.selectedText,
                        Eventually(Equals(self.address_bar.text_field.text)))

    @unittest.skipIf(model() != "Desktop", "on desktop only")
    def test_escape_from_address_bar(self):
        self.main_window.press_key('Alt+D')
        self.assertThat(self.address_bar.text_field.selectedText,
                        Eventually(Equals(self.address_bar.text_field.text)))
        self.main_window.press_key('Escape')
        self.assertThat(self.address_bar.text_field.selectedText,
                        Eventually(Equals("")))
        self.assertThat(self.address_bar.activeFocus, Eventually(Equals(False)))

    @unittest.skipIf(model() != "Desktop", "on desktop only")
    def test_reload(self):
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.loading, Eventually(Equals(False)))

        watcher = webview.watch_signal('loadingStateChanged()')
        previous = watcher.num_emissions

        self.main_window.press_key('Ctrl+R')
        self.assertThat(
            lambda: watcher.num_emissions,
            Eventually(GreaterThan(previous)))

        self.assertThat(webview.loading, Eventually(Equals(False)))

    @unittest.skipIf(model() != "Desktop", "on desktop only")
    def test_bookmark(self):
        chrome = self.main_window.chrome
        self.assertThat(chrome.bookmarked, Equals(False))
        self.main_window.press_key('Ctrl+D')
        self.assertThat(chrome.bookmarked, Eventually(Equals(True)))
        self.main_window.press_key('Ctrl+D')
        self.assertThat(chrome.bookmarked, Eventually(Equals(False)))

    @unittest.skipIf(model() != "Desktop", "on desktop only")
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

    @unittest.skipIf(model() != "Desktop", "on desktop only")
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

    @unittest.skipIf(model() != "Desktop", "on desktop only")
    def test_toggle_history(self):
        self.assertThat(self.main_window.get_history_view(), Equals(None))
        self.main_window.press_key('Ctrl+H')
        self.assertThat(lambda: self.main_window.get_history_view(),
                        Eventually(NotEquals(None)))
        history_view = self.main_window.get_history_view()

        self.main_window.press_key('Escape')
        history_view.wait_until_destroyed()

    @unittest.skipIf(model() != "Desktop", "on desktop only")
    def test_toggle_history_from_menu(self):
        self.assertThat(self.main_window.get_history_view(), Equals(None))
        self.open_history()
        history_view = self.main_window.get_history_view()
        self.assertThat(history_view.activeFocus, Eventually(Equals(True)))

        self.main_window.press_key('Escape')
        history_view.wait_until_destroyed()

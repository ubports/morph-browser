# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2013-2015 Canonical
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
import random
import sqlite3
import time

from testtools.matchers import Contains, Equals
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class PrepopulatedDatabaseTestCaseBase(StartOpenRemotePageTestCaseBase):

    """Helper test class that pre-populates history and bookmarks databases."""

    def setUp(self):
        self.clear_datadir()
        self.populate_history()
        self.populate_bookmarks()
        super(PrepopulatedDatabaseTestCaseBase, self).setUp()

    def populate_history(self):
        db_path = os.path.join(os.path.expanduser("~"), ".local", "share",
                               "webbrowser-app", "history.sqlite")
        connection = sqlite3.connect(db_path)
        connection.execute("""CREATE TABLE IF NOT EXISTS history
                              (url VARCHAR, domain VARCHAR, title VARCHAR,
                               icon VARCHAR, visits INTEGER,
                               lastVisit DATETIME);""")
        search_uri = \
            "http://www.google.com/search?client=ubuntu&q={}&ie=utf-8&oe=utf-8"
        rows = [
            ("http://www.ubuntu.com/", "ubuntu.com", "Home | Ubuntu"),
            (search_uri.format("ubuntu"), "google.com",
             "ubuntu - Google Search"),
            ("http://en.wikipedia.org/wiki/Ubuntu_(operating_system)",
             "wikipedia.org",
             "Ubuntu (operating system) - Wikipedia, the free encyclopedia"),
            ("http://en.wikipedia.org/wiki/Ubuntu_(philosophy)",
             "wikipedia.org",
             "Ubuntu (philosophy) - Wikipedia, the free encyclopedia"),
            (search_uri.format("example"), "google.com",
             "example - Google Search"),
            ("http://example.iana.org/", "iana.org", "Example Domain"),
            ("http://www.iana.org/domains/special", "iana.org",
             "IANA — Special Use Domains"),
            ("http://doc.qt.io/qt-5/qtqml-index.html", "qt.io",
             "Qt QML 5.4 - Qt Documentation")
        ]
        for i, row in enumerate(rows):
            visits = random.randint(1, 5)
            timestamp = int(time.time()) - i * 10
            query = "INSERT INTO history \
                     VALUES ('{}', '{}', '{}', '', {}, {});"
            query = query.format(row[0], row[1], row[2], visits, timestamp)
            connection.execute(query)
        connection.commit()
        connection.close()

    def populate_bookmarks(self):
        db_path = os.path.join(os.path.expanduser("~"), ".local", "share",
                               "webbrowser-app", "bookmarks.sqlite")
        connection = sqlite3.connect(db_path)
        connection.execute("""CREATE TABLE IF NOT EXISTS bookmarks
                              (url VARCHAR, title VARCHAR, icon VARCHAR,
                              created INTEGER);""")
        rows = [
            ("http://www.rsc.org/periodic-table/element/24/chromium",
             "Chromium - Element Information"),
            ("http://www.rsc.org/periodic-table/element/77/iridium",
             "Iridium - Element Information"),
            ("http://www.rsc.org/periodic-table/element/31/gallium",
             "Gallium - Element Information"),
            ("http://www.rsc.org/periodic-table/element/116/livermorium",
             "Livermorium - Element Information"),
            ("http://www.rsc.org/periodic-table/element/62/samarium",
             "Samarium - Element Information"),
            ("http://en.wikipedia.org/wiki/Linux",
             "Linux - Wikipedia, the free encyclopedia"),
            ("https://www.linux.com/",
             "Linux.com | The source for Linux information"),
            ("http://doc.qt.io/qt-5/qtqml-index.html",
             "Qt QML 5.4 - Qt Documentation")
        ]

        for i, row in enumerate(rows):
            timestamp = int(time.time()) - i * 10
            query = "INSERT INTO bookmarks \
                     VALUES ('{}', '{}', '', {});"
            query = query.format(row[0], row[1], timestamp)
            connection.execute(query)

        connection.commit()
        connection.close()


class TestSuggestions(PrepopulatedDatabaseTestCaseBase):

    """Test the address bar suggestions (based on history and bookmarks)."""

    def setUp(self):
        super().setUp()
        self.address_bar = self.main_window.address_bar

    def assert_suggestions_eventually_shown(self):
        suggestions = self.main_window.get_suggestions()
        self.assertThat(suggestions.opacity, Eventually(Equals(1)))

    def assert_suggestions_eventually_hidden(self):
        suggestions = self.main_window.get_suggestions()
        self.assertThat(suggestions.opacity, Eventually(Equals(0)))

    def test_show_list_of_suggestions(self):
        suggestions = self.main_window.get_suggestions()
        self.assert_suggestions_eventually_hidden()
        self.assert_suggestions_eventually_hidden()
        self.address_bar.focus()
        self.assert_suggestions_eventually_shown()
        self.assertThat(suggestions.count, Eventually(Equals(1)))
        self.address_bar.clear()
        self.assert_suggestions_eventually_hidden()

    def test_list_of_suggestions_case_insensitive(self):
        suggestions = self.main_window.get_suggestions()
        self.address_bar.write('xaMPL')
        self.assertThat(suggestions.count, Eventually(Equals(2)))

    def test_list_of_suggestions_history_limits(self):
        suggestions = self.main_window.get_suggestions()
        self.address_bar.write('ubuntu')
        self.assert_suggestions_eventually_shown()
        self.assertThat(suggestions.count, Eventually(Equals(4)))
        self.address_bar.write('bleh', clear=False)
        self.assertThat(suggestions.count, Eventually(Equals(0)))
        self.address_bar.write('iana')
        self.assertThat(suggestions.count, Eventually(Equals(2)))

    def test_list_of_suggestions_bookmark_limits(self):
        suggestions = self.main_window.get_suggestions()
        self.address_bar.write('element')
        self.assert_suggestions_eventually_shown()
        self.assertThat(suggestions.count, Eventually(Equals(4)))
        self.address_bar.write('bleh', clear=False)
        self.assertThat(suggestions.count, Eventually(Equals(0)))
        self.address_bar.write('linux')
        self.assertThat(suggestions.count, Eventually(Equals(2)))

    def test_list_of_suggestions_order(self):
        suggestions = self.main_window.get_suggestions()
        self.address_bar.write('QML')
        self.assert_suggestions_eventually_shown()
        self.assertThat(suggestions.count, Eventually(Equals(2)))
        entries = suggestions.get_ordered_entries()
        self.assertThat(len(entries), Equals(2))
        self.assertThat(entries[0].icon, Equals("history"))
        self.assertThat(entries[1].icon, Equals("non-starred"))

    def test_clear_address_bar_dismisses_suggestions(self):
        self.address_bar.focus()
        self.assert_suggestions_eventually_shown()
        self.address_bar.clear()
        self.address_bar.write('ubuntu')
        self.assert_suggestions_eventually_shown()
        self.address_bar.clear()
        self.assert_suggestions_eventually_hidden()

    def test_addressbar_loosing_focus_dismisses_suggestions(self):
        self.address_bar.focus()
        self.assert_suggestions_eventually_shown()
        suggestions = self.main_window.get_suggestions()
        cs = suggestions.globalRect
        webview = self.main_window.get_current_webview()
        cw = webview.globalRect
        # Click somewhere in the webview but outside the suggestions list
        self.pointing_device.move(cs[0] + cs[2] // 2,
                                  (cs[1] + cs[3] + cw[1] + cw[3]) // 2)
        self.pointing_device.click()
        self.assert_suggestions_eventually_hidden()

    def test_suggestions_hidden_while_drawer_open(self):
        self.address_bar.focus()
        self.assert_suggestions_eventually_shown()
        chrome = self.main_window.chrome
        drawer_button = chrome.get_drawer_button()
        self.pointing_device.click_object(drawer_button)
        drawer = chrome.get_drawer()
        self.assert_suggestions_eventually_hidden()
        self.pointing_device.click_object(drawer_button)
        drawer.wait_until_destroyed()
        self.assert_suggestions_eventually_shown()

    def test_select_suggestion(self):
        suggestions = self.main_window.get_suggestions()
        self.address_bar.focus()
        self.assert_suggestions_eventually_shown()
        self.address_bar.clear()
        self.address_bar.write('ubuntu')
        self.assert_suggestions_eventually_shown()
        self.assertThat(suggestions.count, Eventually(Equals(4)))
        entries = suggestions.get_ordered_entries()
        highlight = '<b><font color="#dd4814">Ubuntu</font></b>'
        url = "http://en.wikipedia.org/wiki/{}_(operating_system)"
        url = url.format(highlight)
        entries = [entry for entry in entries if url in entry.subtitle]
        entry = entries[0] if len(entries) == 1 else None
        self.assertIsNotNone(entry)
        self.pointing_device.click_object(entry)
        webview = self.main_window.get_current_webview()
        url = "wikipedia.org/wiki/Ubuntu_(operating_system)"
        self.assertThat(webview.url, Eventually(Contains(url)))
        self.assert_suggestions_eventually_hidden()

    def test_special_characters(self):
        self.address_bar.clear()
        self.address_bar.write('(phil')
        self.assert_suggestions_eventually_shown()
        suggestions = self.main_window.get_suggestions()
        self.assertThat(suggestions.count, Eventually(Equals(1)))
        entry = suggestions.get_ordered_entries()[0]
        highlight = '<b><font color="#dd4814">(phil</font></b>'
        url = "http://en.wikipedia.org/wiki/Ubuntu_{}osophy)".format(highlight)
        self.assertThat(entry.subtitle, Contains(url))

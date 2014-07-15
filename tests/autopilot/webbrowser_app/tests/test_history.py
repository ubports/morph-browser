# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2013-2014 Canonical
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


class PrepopulatedHistoryDatabaseTestCaseBase(StartOpenRemotePageTestCaseBase):

    """Helper test class that pre-populates the history database."""

    def setUp(self):
        self.clear_cache()
        db_path = os.path.join(os.path.expanduser("~"), ".local", "share",
                               "webbrowser-app", "history.sqlite")
        connection = sqlite3.connect(db_path)
        connection.execute("""CREATE TABLE IF NOT EXISTS history
                              (url VARCHAR, title VARCHAR, icon VARCHAR,
                               visits INTEGER, lastVisit DATETIME);""")
        search_uri = \
            "http://www.google.com/search?client=ubuntu&q={}&ie=utf-8&oe=utf-8"
        rows = [
            ("http://www.ubuntu.com/", "Home | Ubuntu"),
            (search_uri.format("ubuntu"), "ubuntu - Google Search"),
            ("http://en.wikipedia.org/wiki/Ubuntu_(operating_system)",
             "Ubuntu (operating system) - Wikipedia, the free encyclopedia"),
            ("http://en.wikipedia.org/wiki/Ubuntu_(philosophy)",
             "Ubuntu (philosophy) - Wikipedia, the free encyclopedia"),
            (search_uri.format("example"), "example - Google Search"),
            ("http://example.iana.org/", "Example Domain"),
            ("http://www.iana.org/domains/special",
             "IANA — Special Use Domains")
        ]
        for i, row in enumerate(rows):
            visits = random.randint(1, 5)
            timestamp = int(time.time()) - i * 10
            query = "INSERT INTO history VALUES ('{}', '{}', '', {}, {});"
            query = query.format(row[0], row[1], visits, timestamp)
            connection.execute(query)
        connection.commit()
        connection.close()
        super(PrepopulatedHistoryDatabaseTestCaseBase, self).setUp()


class TestHistorySuggestions(PrepopulatedHistoryDatabaseTestCaseBase):

    """Test the address bar suggestions based on navigation history."""

    def assert_suggestions_eventually_shown(self):
        suggestions = self.main_window.get_address_bar_suggestions()
        self.assertThat(suggestions.opacity, Eventually(Equals(1)))

    def assert_suggestions_eventually_hidden(self):
        suggestions = self.main_window.get_address_bar_suggestions()
        self.assertThat(suggestions.opacity, Eventually(Equals(0)))

    def test_show_list_of_suggestions(self):
        listview = self.main_window.get_address_bar_suggestions_listview()
        self.assert_suggestions_eventually_hidden()
        self.assert_suggestions_eventually_hidden()
        self.focus_address_bar()
        self.assert_suggestions_eventually_shown()
        self.assertThat(listview.count, Eventually(Equals(1)))
        self.clear_address_bar()
        self.assert_suggestions_eventually_hidden()
        self.type_in_address_bar("u")
        self.assert_suggestions_eventually_shown()
        self.assertThat(listview.count, Eventually(Equals(7)))
        self.type_in_address_bar("b")
        self.assertThat(listview.count, Eventually(Equals(5)))
        self.type_in_address_bar("leh")
        self.assertThat(listview.count, Eventually(Equals(0)))
        self.clear_address_bar()
        self.type_in_address_bar("xaMPL")
        self.assertThat(listview.count, Eventually(Equals(2)))

    def test_clear_address_bar_dismisses_suggestions(self):
        self.focus_address_bar()
        self.assert_suggestions_eventually_shown()
        self.clear_address_bar()
        self.type_in_address_bar("ubuntu")
        self.assert_suggestions_eventually_shown()
        self.clear_address_bar()
        self.assert_suggestions_eventually_hidden()

    def test_addressbar_loosing_focus_dismisses_suggestions(self):
        self.focus_address_bar()
        self.assert_suggestions_eventually_shown()
        suggestions = self.main_window.get_address_bar_suggestions()
        coord = suggestions.globalRect
        webview = self.main_window.get_current_webview()
        self.pointing_device.move(
            coord[0] + coord[2] // 2,
            (coord[1] + webview.globalRect[1]) // 2)
        self.pointing_device.click()
        self.assert_suggestions_eventually_hidden()

    def test_select_suggestion(self):
        listview = self.main_window.get_address_bar_suggestions_listview()
        self.focus_address_bar()
        self.assert_suggestions_eventually_shown()
        self.clear_address_bar()
        self.type_in_address_bar("ubuntu")
        self.assert_suggestions_eventually_shown()
        self.assertThat(listview.count, Eventually(Equals(5)))
        entries = \
            self.main_window.get_address_bar_suggestions_listview_entries()
        highlight = '<b><font color="#dd4814">Ubuntu</font></b>'
        url = "http://en.wikipedia.org/wiki/{}_(operating_system)"
        url = url.format(highlight)
        entries = [entry for entry in entries if url in entry.subText]
        entry = entries[0] if len(entries) == 1 else None
        self.assertIsNotNone(entry)
        self.pointing_device.click_object(entry)
        webview = self.main_window.get_current_webview()
        url = "wikipedia.org/wiki/Ubuntu_(operating_system)"
        self.assertThat(webview.url, Eventually(Contains(url)))
        self.assert_suggestions_eventually_hidden()

    def test_special_characters(self):
        self.clear_address_bar()
        self.type_in_address_bar("(phil")
        self.assert_suggestions_eventually_shown()
        listview = self.main_window.get_address_bar_suggestions_listview()
        self.assertThat(listview.count, Eventually(Equals(1)))
        entry = \
            self.main_window.get_address_bar_suggestions_listview_entries()[0]
        highlight = '<b><font color="#dd4814">(phil</font></b>'
        url = "http://en.wikipedia.org/wiki/Ubuntu_{}osophy)".format(highlight)
        self.assertThat(entry.subText, Contains(url))

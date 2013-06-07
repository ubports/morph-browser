# -*- coding: utf-8 -*-
#
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

from __future__ import absolute_import

import os.path
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
            "http://www.google.com/search?client=ubuntu&q=%s&ie=utf-8&oe=utf-8"
        rows = [
            ("http://www.ubuntu.com/", "Home | Ubuntu"),
            (search_uri % "ubuntu", "ubuntu - Google Search"),
            ("http://en.wikipedia.org/wiki/Ubuntu_(operating_system)",
             "Ubuntu (operating system) - Wikipedia, the free encyclopedia"),
            ("http://en.wikipedia.org/wiki/Ubuntu_(philosophy)",
             "Ubuntu (philosophy) - Wikipedia, the free encyclopedia"),
            (search_uri % "example", "example - Google Search"),
            ("http://example.iana.org/", "Example Domain"),
            ("http://www.iana.org/domains/special",
             "IANA — Special Use Domains")
        ]
        for i, row in enumerate(rows):
            visits = random.randint(1, 5)
            timestamp = int(time.time()) - i * 10
            query = "INSERT INTO history VALUES ('%s', '%s', '', %d, %d);" % \
                    (row[0], row[1], visits, timestamp)
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
        self.assert_chrome_eventually_hidden()
        self.reveal_chrome()
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
        self.assert_chrome_eventually_hidden()
        self.reveal_chrome()
        self.focus_address_bar()
        self.assert_suggestions_eventually_shown()
        self.clear_address_bar()
        self.type_in_address_bar("ubuntu")
        self.assert_suggestions_eventually_shown()
        self.clear_address_bar()
        self.assert_suggestions_eventually_hidden()

    def test_addressbar_loosing_focus_dismisses_suggestions(self):
        self.assert_chrome_eventually_hidden()
        self.reveal_chrome()
        self.focus_address_bar()
        self.assert_suggestions_eventually_shown()
        suggestions = self.main_window.get_address_bar_suggestions()
        coord = suggestions.globalRect
        webview = self.main_window.get_current_webview()
        self.pointing_device.move(
            coord[0] + int(coord[2] / 2),
            int((coord[1] + webview.globalRect[1]) / 2))
        self.pointing_device.click()
        self.assert_suggestions_eventually_hidden()

    def test_hiding_chrome_dismisses_suggestions(self):
        self.assert_chrome_eventually_hidden()
        self.reveal_chrome()
        self.focus_address_bar()
        self.assert_suggestions_eventually_shown()
        self.hide_chrome()
        self.assert_chrome_eventually_hidden()
        self.assert_suggestions_eventually_hidden()
        self.reveal_chrome()
        self.assert_suggestions_eventually_shown()

    def test_select_suggestion(self):
        listview = self.main_window.get_address_bar_suggestions_listview()
        self.assert_chrome_eventually_hidden()
        self.reveal_chrome()
        self.focus_address_bar()
        self.assert_suggestions_eventually_shown()
        self.clear_address_bar()
        self.type_in_address_bar("ubuntu")
        self.assert_suggestions_eventually_shown()
        self.assertThat(listview.count, Eventually(Equals(5)))
        entries = \
            self.main_window.get_address_bar_suggestions_listview_entries()
        entry = entries[2]
        highlight = '<b><font color="#DD4814">Ubuntu</font></b>'
        url = "http://en.wikipedia.org/wiki/%s_(operating_system)" % highlight
        self.assertThat(entry.subText, Contains(url))
        self.pointing_device.move_to_object(entry)
        self.pointing_device.click()
        webview = self.main_window.get_current_webview()
        url = "http://en.wikipedia.org/wiki/Ubuntu_(operating_system)"
        self.assertThat(webview.url, Eventually(Equals(url)))
        self.assert_suggestions_eventually_hidden()

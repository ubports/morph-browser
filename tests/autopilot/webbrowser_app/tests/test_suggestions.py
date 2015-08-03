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
import unittest

from testtools.matchers import Contains, Equals, GreaterThan
from autopilot.matchers import Eventually
from autopilot.platform import model

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase
from . import http_server


class PrepopulatedDatabaseTestCaseBase(StartOpenRemotePageTestCaseBase):

    """Helper test class that pre-populates history and bookmarks databases."""

    def setUp(self):
        self.populate_history()
        self.populate_bookmarks()
        super(PrepopulatedDatabaseTestCaseBase, self).setUp()

    def populate_history(self):
        db_path = os.path.join(self.data_location, "history.sqlite")
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
        db_path = os.path.join(self.data_location, "bookmarks.sqlite")
        connection = sqlite3.connect(db_path)
        connection.execute("""CREATE TABLE IF NOT EXISTS bookmarks
                              (url VARCHAR, title VARCHAR, icon VARCHAR,
                              created INTEGER, folderId INTEGER);""")
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
            ("http://test/wiki/Linux",
             "Linux - Wikipedia, the free encyclopedia"),
            ("http://doc.qt.io/qt-5/qtqml-index.html",
             "Qt QML 5.4 - Qt Documentation")
        ]

        for i, row in enumerate(rows):
            timestamp = int(time.time()) - i * 10
            query = "INSERT INTO bookmarks \
                     VALUES ('{}', '{}', '', {}, '');"
            query = query.format(row[0], row[1], timestamp)
            connection.execute(query)

        connection.commit()
        connection.close()


class TestSuggestions(PrepopulatedDatabaseTestCaseBase):

    """Test the address bar suggestions (based on history and bookmarks)."""

    def setup_suggestions_source(self, server):
        search_engines_path = os.path.join(self.data_location, "searchengines")
        os.makedirs(search_engines_path, exist_ok=True)
        with open(os.path.join(search_engines_path, "test.xml"), "w") as f:
            f.write("""
            <OpenSearchDescription>
             <Url type="application/x-suggestions+json"
                  template="http://localhost:{}/suggest?q={searchTerms}"/>
              <Url type="text/html"
                   template="http://aserver.somewhere/search?q={searchTerms}"/>
            </OpenSearchDescription>
            """.replace("{}", str(server.port)))

        with open(os.path.join(self.config_location, "webbrowser-app.conf"),
                  "w") as f:
            f.write("""
            [General]
            searchEngine=test
            """)
        server.set_suggestions_data({
            "high": ["high", ["highlight"]],
            "foo": ["foo", ["food", "foot", "fool", "foobar", "foo five"]],
            "QML": ["QML", ["qt qml", "qml documentation", "qml rocks"]]
        })

    def setUp(self):
        self.suggest_http_server = http_server.HTTPServerInAThread()
        self.ping_server(self.suggest_http_server)
        self.addCleanup(self.suggest_http_server.cleanup)

        self.create_temporary_profile()
        self.setup_suggestions_source(self.suggest_http_server)

        super(TestSuggestions, self).setUp()

        self.address_bar = self.main_window.address_bar

    def highlight_term(self, text, term):
        parts = text.split(term)
        if len(parts) < 2:
            return text
        else:
            pattern = '<html>{}{}{}</html>'
            return pattern.format(parts[0], self.highlight(term), parts[1])

    def highlight(self, text):
        return '<font color="#752571">{}</font>'.format(text)

    def assert_suggestions_eventually_shown(self):
        suggestions = self.main_window.get_suggestions()
        self.assertThat(suggestions.opacity, Eventually(Equals(1)))

    def assert_suggestions_eventually_hidden(self):
        suggestions = self.main_window.get_suggestions()
        self.assertThat(suggestions.opacity, Eventually(Equals(0)))

    def test_show_list_of_suggestions(self):
        suggestions = self.main_window.get_suggestions()
        self.assert_suggestions_eventually_hidden()
        self.address_bar.focus()
        self.assert_suggestions_eventually_shown()
        self.assertThat(suggestions.count, Eventually(GreaterThan(0)))
        self.address_bar.clear()
        self.assert_suggestions_eventually_hidden()

    def test_list_of_suggestions_case_insensitive(self):
        suggestions = self.main_window.get_suggestions()
        self.address_bar.write('SpEciAl')
        self.assertThat(suggestions.count, Eventually(Equals(1)))

    def test_list_of_suggestions_history_limits(self):
        suggestions = self.main_window.get_suggestions()
        self.address_bar.write('ubuntu')
        self.assert_suggestions_eventually_shown()
        self.assertThat(suggestions.count, Eventually(Equals(2)))
        self.address_bar.write('bleh', clear=False)
        self.assertThat(suggestions.count, Eventually(Equals(0)))
        self.address_bar.write('iana')
        self.assertThat(suggestions.count, Eventually(Equals(1)))

    def test_list_of_suggestions_bookmark_limits(self):
        suggestions = self.main_window.get_suggestions()
        self.address_bar.write('element')
        self.assert_suggestions_eventually_shown()
        self.assertThat(suggestions.count, Eventually(Equals(2)))
        self.address_bar.write('bleh', clear=False)
        self.assertThat(suggestions.count, Eventually(Equals(0)))
        self.address_bar.write('linux')
        self.assertThat(suggestions.count, Eventually(Equals(1)))

    def test_list_of_suggestions_search_limits(self):
        suggestions = self.main_window.get_suggestions()
        self.address_bar.write('foo')
        self.assert_suggestions_eventually_shown()
        self.assertThat(suggestions.count, Eventually(Equals(4)))
        self.address_bar.write('bleh', clear=False)
        self.assertThat(suggestions.count, Eventually(Equals(0)))

    def test_list_of_suggestions_order(self):
        suggestions = self.main_window.get_suggestions()
        self.address_bar.write('QML')
        self.assert_suggestions_eventually_shown()
        self.assertThat(suggestions.count, Eventually(Equals(5)))
        entries = suggestions.get_ordered_entries()
        self.assertThat(len(entries), Equals(5))
        self.assertThat(entries[0].icon, Equals("history"))
        self.assertThat(entries[1].icon, Equals("non-starred"))
        self.assertThat(entries[2].icon, Equals("search"))

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
        self.address_bar.write('linux')
        self.assert_suggestions_eventually_shown()
        self.assertThat(suggestions.count, Eventually(Equals(1)))
        entries = suggestions.get_ordered_entries()
        url = "http://test/wiki/Linux"
        self.pointing_device.click_object(entries[0])
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.url, Eventually(Equals(url)))
        self.assert_suggestions_eventually_hidden()

    def test_select_search_suggestion(self):
        suggestions = self.main_window.get_suggestions()
        self.address_bar.focus()
        self.assert_suggestions_eventually_shown()
        self.address_bar.clear()
        self.address_bar.write('high')
        self.assert_suggestions_eventually_shown()
        self.assertThat(suggestions.count, Eventually(Equals(1)))
        entries = suggestions.get_ordered_entries()
        self.pointing_device.click_object(entries[0])
        webview = self.main_window.get_current_webview()
        url = "aserver.somewhere/search?q=highlight"
        self.assertThat(webview.url, Eventually(Contains(url)))

    def test_special_characters(self):
        self.address_bar.clear()
        self.address_bar.write('(phil')
        self.assert_suggestions_eventually_shown()
        suggestions = self.main_window.get_suggestions()
        self.assertThat(suggestions.count, Eventually(Equals(1)))
        entry = suggestions.get_ordered_entries()[0]
        url = "http://en.wikipedia.org/wiki/Ubuntu_(philosophy)"
        highlighted = self.highlight_term(url, "(phil")
        self.assertThat(entry.subtitle, Equals(highlighted))

    def test_search_suggestions(self):
        self.address_bar.write('high')
        suggestions = self.main_window.get_suggestions()
        self.assertThat(suggestions.count, Eventually(Equals(1)))
        entries = suggestions.get_ordered_entries()
        highlighted = self.highlight_term("highlight", "high")
        self.assertThat(entries[0].title, Equals(highlighted))
        self.assertThat(entries[0].subtitle, Equals(''))

    @unittest.skipIf(model() != "Desktop", "on desktop only")
    def test_keyboard_navigation(self):
        suggestions = self.main_window.get_suggestions()
        address_bar = self.address_bar
        address_bar.write('element')
        self.assert_suggestions_eventually_shown()
        self.assertThat(suggestions.count, Eventually(Equals(2)))
        entries = suggestions.get_ordered_entries()
        self.assertThat(entries[0].selected, Equals(False))
        self.assertThat(entries[1].selected, Equals(False))

        address_bar.press_key('Down')
        self.assertThat(address_bar.activeFocus, Eventually(Equals(False)))
        self.assertThat(suggestions.activeFocus, Eventually(Equals(True)))
        self.assertThat(entries[0].selected, Equals(True))

        self.main_window.press_key('Down')
        self.assertThat(entries[0].selected, Equals(False))
        self.assertThat(entries[1].selected, Equals(True))

        # verify that selection does not wrap around
        self.main_window.press_key('Down')
        self.assertThat(entries[0].selected, Equals(False))
        self.assertThat(entries[1].selected, Equals(True))

        self.main_window.press_key('Up')
        self.assertThat(entries[0].selected, Equals(True))
        self.assertThat(entries[1].selected, Equals(False))

        self.main_window.press_key('Up')
        self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))
        self.assertThat(suggestions.activeFocus, Eventually(Equals(False)))
        self.assertThat(entries[0].selected, Equals(False))
        self.assertThat(entries[1].selected, Equals(False))

    @unittest.skipIf(model() != "Desktop", "on desktop only")
    def test_suggestions_escape(self):
        suggestions = self.main_window.get_suggestions()
        previous_text = self.address_bar.text
        self.address_bar.write('element')
        self.assert_suggestions_eventually_shown()
        self.main_window.press_key('Down')
        self.assertThat(suggestions.activeFocus, Eventually(Equals(True)))
        self.assertThat(self.address_bar.text, Equals("element"))

        self.main_window.press_key('Escape')
        self.assert_suggestions_eventually_hidden()
        self.assertThat(self.address_bar.text, Equals(previous_text))

    @unittest.skipIf(model() != "Desktop", "on desktop only")
    def test_suggestions_escape_on_addressbar(self):
        suggestions = self.main_window.get_suggestions()
        previous_text = self.address_bar.text
        self.address_bar.write('element')
        self.assert_suggestions_eventually_shown()
        self.main_window.press_key('Down')
        self.assertThat(suggestions.activeFocus, Eventually(Equals(True)))
        self.main_window.press_key('Up')
        self.assertThat(suggestions.activeFocus, Eventually(Equals(False)))

        self.main_window.press_key('Escape')
        self.assert_suggestions_eventually_hidden()
        self.assertThat(self.address_bar.text, Equals(previous_text))

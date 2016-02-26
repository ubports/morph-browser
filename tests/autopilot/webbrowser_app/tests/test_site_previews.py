# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2015-2016 Canonical
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

import hashlib
import os
from os import path as path
import sqlite3
import time

from autopilot.matchers import Eventually
from testtools.matchers import Not, Equals, DirExists, DirContains

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestSitePreviewsBase(StartOpenRemotePageTestCaseBase):

    def setUp(self):
        super(TestSitePreviewsBase, self).setUp(launch=False)
        self.captures_dir = path.join(self.cache_location, "captures")

    def file_in_dir(self, file, dir):
        return path.exists(path.join(dir, file))

    def capture_file(self, url):
        return hashlib.md5(url.encode()).hexdigest() + ".png"


class TestSitePreviewsNoLaunch(TestSitePreviewsBase):

    def populate_captures_dir(self, capture_names):
        # captures dir should not exist on fresh run
        self.assertThat(self.captures_dir, Not(DirExists()))

        # create some random files and ensure they get cleaned up
        os.mkdir(self.captures_dir)
        for capture_name in capture_names:
            open(path.join(self.captures_dir, capture_name), 'w').close()
        self.assertThat(self.captures_dir,
                        DirContains(capture_names))

    def populate_history(self):
        self.countries = [
            "Japan", "Russia", "France", "Italy", "Argentina",
            "Canada", "Mexico", "Peru", "Congo", "Brazil",
            "China", "Mali", "Morocco"
        ]
        db_path = os.path.join(self.data_location, "history.sqlite")
        connection = sqlite3.connect(db_path)
        connection.execute("""CREATE TABLE IF NOT EXISTS history
                              (url VARCHAR, domain VARCHAR, title VARCHAR,
                               icon VARCHAR, visits INTEGER,
                               lastVisit DATETIME);""")
        visits = 50
        for country in self.countries:
            timestamp = int(time.time())
            query = "INSERT INTO history \
                     VALUES ('{}', '{}', '{}', '', {}, {});"
            query = query.format("http://en.wikipedia.org/wiki/" + country,
                                 "wikipedia.org", country, visits, timestamp)
            connection.execute(query)
            visits -= 1
        connection.commit()
        connection.close()

    def test_cleanup_previews_on_startup(self):
        self.populate_history()

        # populate the captures dir with correct thumbnail names for all
        # the sites in history...
        history = ["http://en.wikipedia.org/wiki/" + c for c in self.countries]
        history = [self.capture_file(url) for url in history]

        # ...plus some other files to verify possible corner cases
        other_url = self.capture_file("http://google.com/")
        not_hash = "not_a_preview.jpg"
        not_image = "not_an_image.xxx"
        self.populate_captures_dir(history + [other_url, not_hash, not_image])

        self.launch_app()
        time.sleep(1)  # wait for file system to settle

        # verify that non-image files and top 10 sites are left alone,
        # everything else is cleaned up
        topsites = history[0:10]
        current_tab = self.capture_file(self.url)
        self.assertThat(self.captures_dir,
                        DirContains(topsites + [not_image, current_tab]))


class TestSitePreviews(TestSitePreviewsBase):

    def setUp(self):
        super(TestSitePreviews, self).setUp()
        self.launch_and_wait_for_page_loaded()

    def close_tab(self, index):
        if self.main_window.wide:
            self.main_window.chrome.get_tabs_bar().close_tab(index)
        else:
            tabs_view = self.open_tabs_view()
            tabs_view.get_previews()[index].close()
            toolbar = self.main_window.get_recent_view_toolbar()
            toolbar.click_button("doneButton")

    def get_captures(self):
        if not path.exists(self.captures_dir):
            return []

        all = os.listdir(self.captures_dir)
        cap = [f for f in all if path.isfile(path.join(self.captures_dir, f))]
        return cap

    def remove_top_site(self, new_tab_view, url):
        top_sites = new_tab_view.get_top_site_items()
        top_sites = [d for d in top_sites if d.url == url]
        self.assertThat(len(top_sites), Equals(1))
        delegate = top_sites[0]
        delegate.hide_from_history(self.main_window)

    def test_save_on_switch_tab_and_not_delete_if_topsite(self):
        previous = self.main_window.get_current_webview().url

        # switching away from tab should save a capture
        self.open_new_tab(open_tabs_view=True)
        self.assertThat(self.captures_dir,
                        DirContains([self.capture_file(previous)]))

        # closing the captured tab should not delete the capture since it is
        # now part of the top sites (being the only one we opened so far)
        self.close_tab(0)
        time.sleep(0.5)  # wait for file system to settle
        self.assertThat(self.captures_dir,
                        DirContains([self.capture_file(previous)]))

    def test_save_on_switch_tab_and_delete_if_not_topsite(self):
        previous = self.main_window.get_current_webview().url
        new_tab_view = self.open_new_tab(open_tabs_view=True)
        self.remove_top_site(new_tab_view, previous)
        self.close_tab(0)
        self.assertThat(lambda: self.file_in_dir(self.capture_file(previous),
                                                 self.captures_dir),
                        Eventually(Equals(False)))

    def test_delete_when_tab_closed_and_removed_from_topsites(self):
        previous = self.main_window.get_current_webview().url
        capture = self.capture_file(previous)
        new_tab_view = self.open_new_tab(open_tabs_view=True)
        self.close_tab(0)
        time.sleep(0.5)  # wait for file system to settle
        self.assertThat(self.captures_dir, DirContains([capture]))

        if not self.main_window.wide:
            new_tab_view = self.open_new_tab(open_tabs_view=True)
        self.remove_top_site(new_tab_view, previous)
        self.assertThat(lambda: self.file_in_dir(capture, self.captures_dir),
                        Eventually(Equals(False)))

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

from testtools.matchers import Equals
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestPrivateView(StartOpenRemotePageTestCaseBase):

    def get_url_list_from_history(self):
        self.open_tabs_view()
        self.open_new_tab()
        new_tab_view = self.main_window.get_new_tab_view()
        top_sites = self.main_window.get_top_sites_list()

        db_path = os.path.join(self.data_location, "history.sqlite")
        connection = sqlite3.connect(db_path)
        cur = connection.cursor()
        cur.execute("""SELECT url FROM history;""")
        ret = [row[0] for row in cur]
        connection.close()
        return ret

    def test_going_in_and_out_private_mode(self):
        self.main_window.enter_private_mode()
        self.assertTrue(self.main_window.is_in_private_mode())
        self.assertTrue(self.main_window.is_new_private_tab_view_visible())
        self.main_window.leave_private_mode()
        self.assertFalse(self.main_window.is_in_private_mode())

    def test_cancel_leaving_private_mode(self):
        self.main_window.enter_private_mode()
        self.assertTrue(self.main_window.is_in_private_mode())
        self.assertTrue(self.main_window.is_new_private_tab_view_visible())
        self.main_window.leave_private_mode(confirm=False)
        self.assertTrue(self.main_window.is_in_private_mode())
        self.assertTrue(self.main_window.is_new_private_tab_view_visible())

    def test_url_must_not_be_stored_in_history_in_private_mode(self):
        history = self.get_url_list_from_history()
        url = self.base_url + "/test2"
        self.assertNotIn(url, history)

        self.main_window.enter_private_mode()
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)

        history = self.get_url_list_from_history()
        self.assertNotIn(url, history)

    def test_url_must_be_stored_in_history_after_leaving_private_mode(self):
        history = self.get_url_list_from_history()
        url = self.base_url + "/test2"
        self.assertNotIn(url, history)

        self.main_window.enter_private_mode()
        self.main_window.leave_private_mode()
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)

        history = self.get_url_list_from_history()
        self.assertIn(url, history)

    def test_previews_tabs_must_not_be_visible_after_entering_private_mode(
            self):
        self.open_tabs_view()
        self.open_new_tab()
        new_tab_view = self.main_window.get_new_tab_view()
        url = self.base_url + "/test1"
        self.main_window.go_to_url(url)
        new_tab_view.wait_until_destroyed()
        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = tabs_view.get_previews()
        self.assertThat(len(previews), Equals(2))
        tabs_view.get_previews()[1].select()
        tabs_view.visible.wait_for(False)
        self.assertThat(lambda: self.main_window.get_current_webview().url,
                        Eventually(Equals(url)))

        self.main_window.enter_private_mode()
        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = tabs_view.get_previews()
        self.assertThat(len(previews), Equals(1))

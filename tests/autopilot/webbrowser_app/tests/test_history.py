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

import time

from testtools.matchers import EndsWith, Equals, StartsWith
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestHistory(StartOpenRemotePageTestCaseBase):

    def expect_history_entries(self, ordered_urls):
        history = self.main_window.get_history_view()
        if self.main_window.wide:
            self.assertThat(lambda: len(history.get_entries()),
                            Eventually(Equals(len(ordered_urls))))
            entries = history.get_entries()
        else:
            self.assertThat(lambda: len(history.get_domain_entries()),
                            Eventually(Equals(1)))
            self.pointing_device.click_object(history.get_domain_entries()[0])
            expanded_history = self.main_window.get_expanded_history_view()
            self.assertThat(lambda: len(expanded_history.get_entries()),
                            Eventually(Equals(len(ordered_urls))))
            entries = expanded_history.get_entries()
        self.assertThat([entry.url for entry in entries], Equals(ordered_urls))
        return entries

    def test_404_not_saved(self):
        url = self.base_url + "/notfound"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)

        # A valid url to be sure the fact the 404 page isn't present in the
        # history view isn't a timing issue.
        url = self.base_url + "/test2"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)

        self.open_history()
        self.expect_history_entries([url, self.url])

    def test_expanded_history_view_header_swallows_clicks(self):
        # Regression test for https://launchpad.net/bugs/1518904
        if self.main_window.wide:
            self.skipTest("Only on narrow form factors")
        history = self.open_history()
        self.pointing_device.click_object(history.get_domain_entries()[0])
        expanded_history = self.main_window.get_expanded_history_view()
        hr = expanded_history.get_header().globalRect
        self.pointing_device.move(hr.x + hr.width // 2, hr.y + hr.height - 5)
        self.pointing_device.click()
        time.sleep(1)
        # There should be only one instance on the expanded history view.
        # If there’s more, the following call will raise an exception.
        self.main_window.get_expanded_history_view()

    def test_favicon_saved(self):
        # Regression test for https://launchpad.net/bugs/1549780
        url = self.base_url + "/favicon"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        self.open_history()
        first = self.expect_history_entries([url, self.url])[0]
        self.assertThat(first.url, Equals(url))
        favicon = self.base_url + "/assets/icon1.png"
        self.assertThat(first.icon, Equals(favicon))

    def test_favicon_updated(self):
        # Verify that a page dynamically updating its favicon
        # triggers an update in the history database.
        url = self.base_url + "/changingfavicon"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        self.open_history()
        first = self.expect_history_entries([url, self.url])[0]
        indexes = set()
        while len(indexes) < 3:
            self.assertThat(first.url, Equals(url))
            icon = first.icon
            self.assertThat(icon, StartsWith(self.base_url))
            self.assertThat(icon, EndsWith(".png"))
            indexes.add(int(first.icon[(len(self.base_url)+1):-4]))

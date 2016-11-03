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
from autopilot.platform import model

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase

import testtools


class TestHistory(StartOpenRemotePageTestCaseBase):

    def expect_history_entries(self, ordered_urls, window=None):
        if window is None:
            window = self.main_window

        history = window.get_history_view()
        if window.wide:
            self.assertThat(lambda: len(history.get_entries()),
                            Eventually(Equals(len(ordered_urls))))
            entries = history.get_entries()
        else:
            self.assertThat(lambda: len(history.get_domain_entries()),
                            Eventually(Equals(1)))
            self.pointing_device.click_object(history.get_domain_entries()[0])
            expanded_history = window.get_expanded_history_view()
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

    def test_title_saved(self):
        self.open_history()
        entry = self.expect_history_entries([self.url])[0]
        self.assertThat(entry.title, Equals("test page 1"))

    def test_title_not_updated(self):
        # Verify that a page dynamically updating its title
        # does NOT trigger an update in the history database.
        url = self.base_url + "/changingtitle"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        self.open_history()
        first = self.expect_history_entries([url, self.url])[0]
        for i in range(10):
            self.assertThat(first.title, Equals("title0"))
            time.sleep(0.5)

    def test_pushstate_updates_history(self):
        url = self.base_url + "/pushstate"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        pushed = self.base_url + "/statepushed"
        self.main_window.wait_until_page_loaded(pushed)
        self.open_history()
        self.expect_history_entries([pushed, url, self.url])

    @testtools.skipIf(model() != "Desktop",
                      "Desktop only due to switch_to_unfocused_window")
    def test_private_window_no_history(self):
        self.open_new_private_window()

        public_window = self.app.get_windows(incognito=False)[0]
        private_window = self.app.get_windows(incognito=True)[0]

        # Open link in private window
        url = self.base_url + "/test2"
        private_window.go_to_url(url)
        private_window.wait_until_page_loaded(url)

        # Focus public window
        self.switch_to_unfocused_window(public_window)

        # Check link is not in history of public window
        self.open_history(window=public_window)
        self.expect_history_entries([self.url], window=public_window)

    def test_title_correct_redirect_header(self):
        # Regression test for https://launchpad.net/bugs/1603835
        url_redirect = self.base_url + "/redirect-no-title-header"
        url_destination = self.base_url + "/redirect-destination"
        url_test = self.base_url + "/test1"

        self.main_window.go_to_url(url_redirect)
        self.main_window.wait_until_page_loaded(url_destination)

        self.open_history()

        entries = self.expect_history_entries(
            [url_destination, url_test]
        )
        self.assertThat(entries[0].title, Equals("test/redirect-destination"))
        self.assertThat(entries[1].title, Equals("test page 1"))

    def test_title_correct_redirect_js(self):
        # Regression test for https://launchpad.net/bugs/1603835
        url_redirect = self.base_url + "/redirect-no-title-js"
        url_destination = self.base_url + "/redirect-destination"
        url_test = self.base_url + "/test1"

        self.main_window.go_to_url(url_redirect)
        self.main_window.wait_until_page_loaded(url_destination)

        self.open_history()

        entries = self.expect_history_entries(
            [url_destination, url_redirect, url_test]
        )
        self.assertThat(entries[0].title, Equals("test/redirect-destination"))
        self.assertThat(entries[1].title, Equals("test/redirect-no-title-js"))
        self.assertThat(entries[2].title, Equals("test page 1"))

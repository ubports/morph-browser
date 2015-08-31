# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2014-2015 Canonical
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

from testtools.matchers import Equals
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestAddressBarBookmark(StartOpenRemotePageTestCaseBase):

    def test_switching_tabs_updates_bookmark_toggle(self):
        chrome = self.main_window.chrome
        address_bar = self.main_window.address_bar
        bookmark_toggle = address_bar.get_bookmark_toggle()
        self.pointing_device.click_object(bookmark_toggle)
        bookmark_options = self.main_window.get_bookmark_options()
        bookmark_options.click_dismiss_button()
        bookmark_options.wait_until_destroyed()
        self.assertThat(chrome.bookmarked, Eventually(Equals(True)))

        self.open_new_tab(open_tabs_view=True)
        url = self.base_url + "/test2"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        self.assertThat(chrome.bookmarked, Eventually(Equals(False)))

        if self.main_window.wide:
            self.main_window.chrome.get_tabs_bar().select_tab(0)
        else:
            tabs_view = self.open_tabs_view()
            tabs_view.get_previews()[1].select()
            tabs_view.visible.wait_for(False)
        self.assertThat(chrome.bookmarked, Eventually(Equals(True)))

        if self.main_window.wide:
            self.main_window.chrome.get_tabs_bar().select_tab(1)
        else:
            tabs_view = self.open_tabs_view()
            tabs_view.get_previews()[1].select()
            tabs_view.visible.wait_for(False)
        self.assertThat(chrome.bookmarked, Eventually(Equals(False)))

    def test_cannot_bookmark_empty_page(self):
        self.open_new_tab(open_tabs_view=True)

        if self.main_window.wide:
            self.main_window.chrome.get_tabs_bar().select_tab(0)
        else:
            tabs_view = self.open_tabs_view()
            tabs_view.get_previews()[1].select()
            tabs_view.visible.wait_for(False)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        address_bar = self.main_window.address_bar
        bookmark_toggle = address_bar.get_bookmark_toggle()
        self.assertThat(bookmark_toggle.visible, Eventually(Equals(True)))

        if self.main_window.wide:
            self.main_window.chrome.get_tabs_bar().select_tab(1)
        else:
            tabs_view = self.open_tabs_view()
            tabs_view.get_previews()[1].select()
            tabs_view.visible.wait_for(False)
        self.assertThat(bookmark_toggle.visible, Eventually(Equals(False)))

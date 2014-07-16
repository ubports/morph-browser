# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2014 Canonical
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

    def setUp(self):
        self.clear_cache()
        super(TestAddressBarBookmark, self).setUp()

    def test_initially_not_bookmarked(self):
        chrome = self.main_window.get_chrome()
        self.assertThat(chrome.bookmarked, Equals(False))

    def test_bookmark_current_page(self):
        chrome = self.main_window.get_chrome()
        address_bar = chrome.get_address_bar()
        bookmark_toggle = address_bar.get_bookmark_toggle()
        self.pointing_device.click_object(bookmark_toggle)
        self.assertThat(chrome.bookmarked, Eventually(Equals(True)))
        self.pointing_device.click_object(bookmark_toggle)
        self.assertThat(chrome.bookmarked, Eventually(Equals(False)))

    def test_cannot_bookmark_while_focused(self):
        self.focus_address_bar()
        chrome = self.main_window.get_chrome()
        address_bar = chrome.get_address_bar()
        bookmark_toggle = address_bar.get_bookmark_toggle()
        self.assertThat(bookmark_toggle.visible, Eventually(Equals(False)))
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        self.assertThat(bookmark_toggle.visible, Eventually(Equals(True)))

    def test_switching_tabs_updates_bookmark_toggle(self):
        chrome = self.main_window.get_chrome()
        address_bar = chrome.get_address_bar()
        bookmark_toggle = address_bar.get_bookmark_toggle()
        self.pointing_device.click_object(bookmark_toggle)
        self.assertThat(chrome.bookmarked, Eventually(Equals(True)))

        self.open_tabs_view()
        self.open_new_tab()
        url = self.base_url + "/aleaiactaest"
        self.type_in_address_bar(url)
        self.keyboard.press_and_release("Enter")
        self.assert_page_eventually_loaded(url)
        self.assertThat(chrome.bookmarked, Eventually(Equals(False)))

        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = self.main_window.get_tabs_view().get_ordered_previews()
        self.pointing_device.click_object(previews[0])
        tabs_view.wait_until_destroyed()
        self.assertThat(chrome.bookmarked, Eventually(Equals(True)))

        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = self.main_window.get_tabs_view().get_ordered_previews()
        self.pointing_device.click_object(previews[1])
        tabs_view.wait_until_destroyed()
        self.assertThat(chrome.bookmarked, Eventually(Equals(False)))

    def test_cannot_bookmark_empty_page(self):
        self.open_tabs_view()
        self.open_new_tab()

        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = self.main_window.get_tabs_view().get_ordered_previews()
        self.pointing_device.click_object(previews[0])
        tabs_view.wait_until_destroyed()
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        chrome = self.main_window.get_chrome()
        address_bar = chrome.get_address_bar()
        bookmark_toggle = address_bar.get_bookmark_toggle()
        self.assertThat(address_bar.activeFocus, Eventually(Equals(False)))
        self.assertThat(bookmark_toggle.visible, Eventually(Equals(True)))

        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = self.main_window.get_tabs_view().get_ordered_previews()
        self.pointing_device.click_object(previews[1])
        tabs_view.wait_until_destroyed()
        self.assertThat(address_bar.activeFocus, Equals(False))
        self.assertThat(bookmark_toggle.visible, Eventually(Equals(False)))

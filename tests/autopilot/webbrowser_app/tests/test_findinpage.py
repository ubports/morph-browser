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

from autopilot.exceptions import StateNotFoundError
from autopilot.matchers import Eventually
from testtools.matchers import Equals

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestFindInPage(StartOpenRemotePageTestCaseBase):

    """Tests the find in page functionality."""

    def setUp(self):
        super().setUp()
        self.chrome = self.main_window.chrome
        self.url = self.base_url + "/findinpage"

    def activate_find_in_page(self, navigateFirst=True):
        if navigateFirst:
            self.main_window.go_to_url(self.url)
            self.main_window.wait_until_page_loaded(self.url)

        drawer_button = self.chrome.get_drawer_button()
        self.pointing_device.click_object(drawer_button)
        self.chrome.get_drawer()
        action = self.chrome.get_drawer_action("findinpage")
        self.pointing_device.click_object(action)

    def test_activation(self):
        next = self.chrome.get_find_next_button()
        prev = self.chrome.get_find_prev_button()
        bar = self.chrome.address_bar
        counter = bar.get_find_in_page_counter()

        self.assertThat(bar.findInPageMode, Equals(False))
        self.assertThat(next.visible, Equals(False))
        self.assertThat(prev.visible, Equals(False))
        self.assertThat(counter.visible, Equals(False))
        self.assertThat(bar.activeFocus, Equals(False))

        previous_text = bar.text

        self.activate_find_in_page(False)
        self.assertThat(bar.findInPageMode, Eventually(Equals(True)))
        self.assertThat(next.visible, Eventually(Equals(True)))
        self.assertThat(prev.visible, Eventually(Equals(True)))
        self.assertThat(counter.visible, Eventually(Equals(True)))
        self.assertThat(bar.activeFocus, Eventually(Equals(True)))

        self.assertThat(self.chrome.is_back_button_enabled(), Equals(True))
        self.assertThat(self.chrome.is_forward_button_enabled(), Equals(False))
        self.chrome.go_back()

        self.assertThat(bar.findInPageMode, Eventually(Equals(False)))
        self.assertThat(next.visible, Eventually(Equals(False)))
        self.assertThat(prev.visible, Eventually(Equals(False)))
        self.assertThat(counter.visible, Eventually(Equals(False)))
        self.assertThat(bar.activeFocus, Eventually(Equals(False)))
        self.assertThat(bar.text, Eventually(Equals(previous_text)))

    def test_counter(self):
        bar = self.chrome.address_bar
        counter = bar.get_find_in_page_counter()

        self.activate_find_in_page()
        bar.write("text")
        self.assertThat(counter.current, Eventually(Equals(1)))
        self.assertThat(counter.count, Eventually(Equals(2)))

        bar.write("hello")
        self.assertThat(counter.current, Eventually(Equals(1)))
        self.assertThat(counter.count, Eventually(Equals(1)))

        bar.write("")
        self.assertThat(counter.current, Eventually(Equals(0)))
        self.assertThat(counter.count, Eventually(Equals(0)))

    def test_navigation(self):
        bar = self.chrome.address_bar
        counter = bar.get_find_in_page_counter()
        next = self.chrome.get_find_next_button()
        prev = self.chrome.get_find_prev_button()

        self.activate_find_in_page()
        self.assertThat(next.enabled, Eventually(Equals(False)))
        self.assertThat(prev.enabled, Eventually(Equals(False)))

        bar.write("text")
        self.assertThat(next.enabled, Eventually(Equals(True)))
        self.assertThat(prev.enabled, Eventually(Equals(True)))

        self.pointing_device.click_object(next)
        self.assertThat(counter.current, Eventually(Equals(2)))
        self.assertThat(counter.count, Eventually(Equals(2)))
        self.pointing_device.click_object(next)
        self.assertThat(counter.current, Eventually(Equals(1)))
        self.assertThat(counter.count, Eventually(Equals(2)))
        self.pointing_device.click_object(prev)
        self.assertThat(counter.current, Eventually(Equals(2)))
        self.assertThat(counter.count, Eventually(Equals(2)))
        self.pointing_device.click_object(next)
        self.assertThat(counter.current, Eventually(Equals(1)))
        self.assertThat(counter.count, Eventually(Equals(2)))

        bar.write("hello")
        self.assertThat(next.enabled, Eventually(Equals(False)))
        self.assertThat(prev.enabled, Eventually(Equals(False)))

    def test_navigation_exits_findinpage_mode(self):
        url = self.base_url + "/link"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        self.activate_find_in_page(False)
        bar = self.chrome.address_bar
        self.assertThat(bar.findInPageMode, Eventually(Equals(True)))
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        self.assertThat(bar.findInPageMode, Eventually(Equals(False)))

    def test_opening_new_tab_exits_findinpage_mode(self):
        self.activate_find_in_page(False)
        bar = self.chrome.address_bar
        self.assertThat(bar.findInPageMode, Eventually(Equals(True)))
        if not self.main_window.wide:
            # Remove focus from the address bar to hide the OSK
            # (that would otherwise prevent a bottom edge swipe gesture)
            webview = self.main_window.get_current_webview()
            self.pointing_device.click_object(webview)
        self.open_new_tab(open_tabs_view=True)
        self.assertThat(bar.findInPageMode, Eventually(Equals(False)))

    def test_navigation_in_new_tab_exits_findinpage_mode(self):
        url = self.base_url + "/blanktargetlink"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        self.activate_find_in_page(False)
        bar = self.chrome.address_bar
        self.assertThat(bar.findInPageMode, Eventually(Equals(True)))
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        self.assertThat(bar.findInPageMode, Eventually(Equals(False)))

    def test_history_exits_findinpage_mode(self):
        bar = self.chrome.address_bar
        self.activate_find_in_page(False)
        self.assertThat(bar.findInPageMode, Eventually(Equals(True)))
        self.open_history()
        self.assertThat(bar.findInPageMode, Eventually(Equals(False)))

    def test_settings_exits_findinpage_mode(self):
        bar = self.chrome.address_bar
        self.activate_find_in_page(False)
        self.assertThat(bar.findInPageMode, Eventually(Equals(True)))
        self.open_settings()
        self.assertThat(bar.findInPageMode, Eventually(Equals(False)))

    def test_find_in_page_not_in_menu_in_new_tab(self):
        if not self.main_window.wide:
            self.open_tabs_view()
        self.open_new_tab()

        drawer_button = self.chrome.get_drawer_button()
        self.pointing_device.click_object(drawer_button)
        self.chrome.get_drawer()
        action_missing = False
        try:
            self.chrome.get_drawer_action("findinpage")
        except StateNotFoundError:
            action_missing = True

        self.assertThat(action_missing, Equals(True))

    # See http://pad.lv/1508130
    def test_focus_on_enter(self):
        bar = self.main_window.address_bar
        self.activate_find_in_page(False)
        self.assertThat(bar.findInPageMode, Eventually(Equals(True)))
        self.assertThat(bar.activeFocus, Eventually(Equals(True)))
        self.chrome.go_back()
        self.assertThat(bar.findInPageMode, Eventually(Equals(False)))
        self.activate_find_in_page(False)
        self.assertThat(bar.findInPageMode, Eventually(Equals(True)))
        self.assertThat(bar.activeFocus, Eventually(Equals(True)))

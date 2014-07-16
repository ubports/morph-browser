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

from testtools.matchers import Equals
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestTabs(StartOpenRemotePageTestCaseBase):

    def open_tabs_view(self):
        chrome = self.main_window.get_chrome()
        drawer_button = chrome.get_drawer_button()
        self.pointing_device.click_object(drawer_button)
        chrome.get_drawer()
        tabs_action = chrome.get_drawer_action("tabs")
        self.pointing_device.click_object(tabs_action)
        self.main_window.get_tabs_view()

    def setUp(self):
        super(TestTabs, self).setUp()
        self.open_tabs_view()

    def open_new_tab(self):
        tabs_view = self.main_window.get_tabs_view()
        add_button = tabs_view.get_add_button()
        self.pointing_device.click_object(add_button)
        tabs_view.wait_until_destroyed()
        self.main_window.get_new_tab_view()
        address_bar = self.main_window.get_chrome().get_address_bar()
        self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))

    def test_tabs_model(self):
        previews = self.main_window.get_tabs_view().get_previews()
        self.assertThat(len(previews), Equals(1))

    def test_close_tabs_view(self):
        tabs_view = self.main_window.get_tabs_view()
        done_button = tabs_view.get_done_button()
        self.pointing_device.click_object(done_button)
        tabs_view.wait_until_destroyed()

    def test_open_new_tab(self):
        self.open_new_tab()
        new_tab_view = self.main_window.get_new_tab_view()
        url = self.base_url + "/aleaiactaest"
        self.type_in_address_bar(url)
        self.keyboard.press_and_release("Enter")
        new_tab_view.wait_until_destroyed()

    def test_close_last_open_tab(self):
        tabs_view = self.main_window.get_tabs_view()
        preview = tabs_view.get_previews()[0]
        close_button = preview.get_close_button()
        self.pointing_device.click_object(close_button)
        tabs_view.wait_until_destroyed()
        self.main_window.get_new_tab_view()
        address_bar = self.main_window.get_chrome().get_address_bar()
        self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.url, Equals(""))

    def test_close_current_tab(self):
        self.open_new_tab()
        new_tab_view = self.main_window.get_new_tab_view()
        url = self.base_url + "/aleaiactaest"
        self.type_in_address_bar(url)
        self.keyboard.press_and_release("Enter")
        new_tab_view.wait_until_destroyed()
        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = tabs_view.get_ordered_previews()
        self.assertThat(len(previews), Equals(2))
        preview = previews[1]
        close_button = preview.get_close_button()
        self.pointing_device.click_object(close_button)
        self.assertThat(lambda: len(tabs_view.get_previews()),
                        Eventually(Equals(1)))
        preview = tabs_view.get_previews()[0]
        webview = self.main_window.get_current_webview()
        self.assertThat(preview.title, Equals(webview.title))

    """
    def test_switch_tabs(self):
        self.ensure_activity_view_visible()
        self.open_new_tab()
        url = self.base_url + "/aleaiactaest"
        self.type_in_address_bar(url)
        self.keyboard.press_and_release("Enter")
        self.assert_page_eventually_loaded(url)
        self.assert_current_url(url)

        self.ensure_activity_view_visible()
        tabs = self.main_window.get_tabslist_view_delegates()
        self.assertThat(len(tabs), Equals(2))
        view = self.main_window.get_tabslist_view()
        self.assertThat(view.currentIndex, Equals(1))
        self.pointing_device.click_object(tabs[0])
        self.assertThat(self.main_window.currentIndex, Eventually(Equals(0)))
        self.assert_current_url(self.url)
        self.assert_activity_view_eventually_hidden()
        self.assert_chrome_eventually_hidden()

        self.ensure_activity_view_visible()
        tabs = self.main_window.get_tabslist_view_delegates()
        self.pointing_device.click_object(tabs[1])
        self.assertThat(self.main_window.currentIndex, Eventually(Equals(1)))
        self.assert_current_url(url)
        self.assert_activity_view_eventually_hidden()
        self.assert_chrome_eventually_hidden()

    def test_open_target_blank_in_new_tab(self):
        url = self.base_url + "/blanktargetlink"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        self.assertThat(self.main_window.currentIndex, Eventually(Equals(1)))
        self.assert_current_url(self.base_url + "/aleaiactaest")

    def test_open_iframe_target_blank_in_new_tab(self):
        url = self.base_url + "/fulliframewithblanktargetlink"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        self.assertThat(self.main_window.currentIndex, Eventually(Equals(1)))
        self.assert_current_url(self.base_url + "/aleaiactaest")

    def test_error_only_for_current_tab(self):
        self.ensure_activity_view_visible()
        self.open_new_tab()
        self.type_in_address_bar("htpp://invalid")
        self.keyboard.press_and_release("Enter")
        error = self.main_window.get_error_sheet()
        self.assertThat(error.visible, Eventually(Equals(True)))
        self.ensure_activity_view_visible()
        tabs = self.main_window.get_tabslist_view_delegates()
        self.pointing_device.click_object(tabs[0])
        self.assertThat(error.visible, Eventually(Equals(False)))
    """

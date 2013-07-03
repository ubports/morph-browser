# -*- coding: utf-8 -*-
#
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

from __future__ import absolute_import

from testtools.matchers import Equals
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestTabs(StartOpenRemotePageTestCaseBase):

    """Tests tabs management."""

    def ensure_activity_view_visible(self):
        self.ensure_chrome_is_hidden()
        self.reveal_chrome()
        tabs_button = self.main_window.get_tabs_button()
        self.pointing_device.move_to_object(tabs_button)
        self.pointing_device.click()
        activity_view = self.main_window.get_activity_view()
        self.assertThat(activity_view.visible, Eventually(Equals(True)))

    def open_new_tab(self):
        # assumes the activity view is already visible
        view = self.main_window.get_tabslist_view()
        count = view.count
        newtab_delegate = self.main_window.get_tabslist_newtab_delegate()
        # XXX: This assumes the new tab delegate is in sight, which might not
        # always be the case if there is a large number of tabs open. However
        # this should be good enough for our tests that never open more than
        # two tabs.
        self.pointing_device.move_to_object(newtab_delegate)
        self.pointing_device.click()
        self.assertThat(view.count, Eventually(Equals(count + 1)))

    def close_tab(self, index):
        # assumes the activity view is already visible
        # XXX: because of http://pad.lv/1187476, tabs have to be swiped
        # left/right instead of up/down to be removed.
        tab = self.main_window.get_tabslist_view_delegates()[index]
        x, y, w, h = tab.globalRect
        y_line = int(y + h / 2)
        start_x = int(x + w / 2)
        stop_x = int(start_x + w / 3)
        self.pointing_device.drag(start_x, y_line, stop_x, y_line)

    def assert_current_url(self, url):
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.url, Eventually(Equals(url)))
        addressbar = self.main_window.get_address_bar()
        self.assertThat(addressbar.actualUrl, Eventually(Equals(url)))

    def test_tabs_model(self):
        view = self.main_window.get_tabslist_view()
        self.assertThat(view.count, Eventually(Equals(1)))

    def test_toggle_activity_view(self):
        activity_view = self.main_window.get_activity_view()
        self.assertThat(activity_view.visible, Equals(False))
        tabs_button = self.main_window.get_tabs_button()
        self.ensure_activity_view_visible()
        self.assert_chrome_eventually_hidden()
        self.reveal_chrome()
        self.pointing_device.move_to_object(tabs_button)
        self.pointing_device.click()
        self.assertThat(activity_view.visible, Eventually(Equals(False)))

    def test_open_new_tab(self):
        self.ensure_activity_view_visible()
        view = self.main_window.get_tabslist_view()
        self.assertThat(view.currentIndex, Equals(0))
        self.open_new_tab()
        self.assertThat(view.currentIndex, Eventually(Equals(1)))
        activity_view = self.main_window.get_activity_view()
        self.assertThat(activity_view.visible, Eventually(Equals(False)))
        self.assert_chrome_eventually_shown()
        address_bar = self.main_window.get_address_bar()
        self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))

    def test_switch_tabs(self):
        self.ensure_activity_view_visible()
        self.open_new_tab()
        url = self.base_url + "/aleaiactaest"
        self.type_in_address_bar(url)
        self.keyboard.press_and_release("Enter")
        self.assert_page_eventually_loaded(url)
        self.assert_current_url(url)

        self.ensure_activity_view_visible()
        view = self.main_window.get_tabslist_view()
        tabs = self.main_window.get_tabslist_view_delegates()
        self.assertThat(len(tabs), Equals(2))
        self.assertThat(view.currentIndex, Equals(1))
        self.pointing_device.move_to_object(tabs[0])
        self.pointing_device.click()
        self.assertThat(view.currentIndex, Eventually(Equals(0)))
        self.assert_current_url(self.url)
        activity_view = self.main_window.get_activity_view()
        self.assertThat(activity_view.visible, Eventually(Equals(False)))
        self.assert_chrome_eventually_hidden()

        self.ensure_activity_view_visible()
        self.pointing_device.move_to_object(tabs[1])
        self.pointing_device.click()
        self.assertThat(view.currentIndex, Eventually(Equals(1)))
        self.assert_current_url(url)
        self.assertThat(activity_view.visible, Eventually(Equals(False)))
        self.assert_chrome_eventually_hidden()

    def test_close_tab(self):
        self.ensure_activity_view_visible()
        self.open_new_tab()
        url = self.base_url + "/aleaiactaest"
        self.type_in_address_bar(url)
        self.keyboard.press_and_release("Enter")
        self.assert_page_eventually_loaded(url)

        self.ensure_activity_view_visible()
        self.close_tab(0)
        self.assertThat(
            lambda: len(self.main_window.get_tabslist_view_delegates()),
            Eventually(Equals(1)))
        view = self.main_window.get_tabslist_view()
        self.assertThat(view.count, Eventually(Equals(1)))
        self.assertThat(view.currentIndex, Eventually(Equals(0)))
        self.assert_current_url(url)

    def test_close_last_open_tab(self):
        self.ensure_activity_view_visible()
        self.close_tab(0)
        view = self.main_window.get_tabslist_view()
        self.assertThat(view.currentIndex, Eventually(Equals(0)))
        self.assertThat(view.count, Eventually(Equals(1)))
        activity_view = self.main_window.get_activity_view()
        self.assertThat(activity_view.visible, Eventually(Equals(False)))
        self.assert_chrome_eventually_shown()
        address_bar = self.main_window.get_address_bar()
        self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))

    def test_open_target_blank_in_new_tab(self):
        url = self.base_url + "/blanktargetlink"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.move_to_object(webview)
        self.pointing_device.click()
        view = self.main_window.get_tabslist_view()
        self.assertThat(view.count, Eventually(Equals(2)))
        self.assertThat(view.currentIndex, Eventually(Equals(1)))
        self.assert_current_url(self.base_url + "/aleaiactaest")

    def test_open_iframe_target_blank_in_new_tab(self):
        url = self.base_url + "/fulliframewithblanktargetlink"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.move_to_object(webview)
        self.pointing_device.click()
        view = self.main_window.get_tabslist_view()
        self.assertThat(view.count, Eventually(Equals(2)))
        self.assertThat(view.currentIndex, Eventually(Equals(1)))
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
        self.pointing_device.move_to_object(tabs[0])
        self.pointing_device.click()
        self.assertThat(error.visible, Eventually(Equals(False)))

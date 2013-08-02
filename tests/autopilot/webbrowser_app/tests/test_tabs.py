# -*- coding: utf-8 -*-
#
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

from __future__ import absolute_import

import time
from testtools.matchers import Equals, Is, Not
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestTabs(StartOpenRemotePageTestCaseBase):

    """Tests tabs management."""

    def assert_activity_view_eventually_visible(self):
        self.assertThat(lambda: self.main_window.get_activity_view(),
                        Eventually(Not(Is(None))))

    def assert_activity_view_eventually_hidden(self):
        self.assertThat(lambda: self.main_window.get_activity_view(),
                        Eventually(Is(None)))

    def ensure_activity_view_visible(self):
        self.ensure_chrome_is_hidden()
        self.reveal_chrome()
        tabs_button = self.main_window.get_activity_button()
        self.pointing_device.click_object(tabs_button)
        self.assert_activity_view_eventually_visible()

    def open_new_tab(self):
        # assumes the activity view is already visible
        self.assertIsNotNone(self.main_window.get_activity_view())
        newtab_delegate = self.main_window.get_tabslist_newtab_delegate()
        # XXX: This assumes the new tab delegate is in sight, which might not
        # always be the case if there is a large number of tabs open. However
        # this should be good enough for our tests that never open more than
        # two tabs.
        self.pointing_device.click_object(newtab_delegate)
        self.assert_activity_view_eventually_hidden()
        self.assert_osk_eventually_shown()
        self.assert_chrome_eventually_shown()
        address_bar = self.main_window.get_address_bar()
        self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))

    def toggle_close_tab_mode(self):
        view = self.main_window.get_tabslist_view()
        previous_state = view.state
        self.assertIn(previous_state, ('', 'close'))
        tab = self.main_window.get_tabslist_view_delegates()[0]
        self.pointing_device.move_to_object(tab)
        self.pointing_device.press()
        time.sleep(1)
        self.pointing_device.release()
        if (previous_state == ''):
            self.assertThat(view.state, Eventually(Equals('close')))
        elif (previous_state == 'close'):
            self.assertThat(view.state, Eventually(Equals('')))

    def assert_current_url(self, url):
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.url, Eventually(Equals(url)))
        addressbar = self.main_window.get_address_bar()
        self.assertThat(addressbar.actualUrl, Eventually(Equals(url)))

    def test_tabs_model(self):
        self.ensure_activity_view_visible()
        view = self.main_window.get_tabslist_view()
        self.assertThat(view.count, Eventually(Equals(1)))

    def test_toggle_activity_view(self):
        self.assertIsNone(self.main_window.get_activity_view())
        tabs_button = self.main_window.get_activity_button()
        self.ensure_activity_view_visible()
        self.assert_chrome_eventually_hidden()
        self.reveal_chrome()
        self.pointing_device.click_object(tabs_button)
        self.assert_activity_view_eventually_hidden()

    def test_open_new_tab(self):
        self.ensure_activity_view_visible()
        browser = self.main_window.get_browser()
        self.assertThat(browser.currentIndex, Equals(0))
        self.open_new_tab()
        self.assertThat(browser.currentIndex, Eventually(Equals(1)))

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
        browser = self.main_window.get_browser()
        self.assertThat(browser.currentIndex, Eventually(Equals(0)))
        self.assert_current_url(self.url)
        self.assert_activity_view_eventually_hidden()
        self.assert_chrome_eventually_hidden()

        self.ensure_activity_view_visible()
        tabs = self.main_window.get_tabslist_view_delegates()
        self.pointing_device.click_object(tabs[1])
        self.assertThat(browser.currentIndex, Eventually(Equals(1)))
        self.assert_current_url(url)
        self.assert_activity_view_eventually_hidden()
        self.assert_chrome_eventually_hidden()

    def test_close_tab(self):
        self.ensure_activity_view_visible()
        self.open_new_tab()
        url = self.base_url + "/aleaiactaest"
        self.type_in_address_bar(url)
        self.keyboard.press_and_release("Enter")
        self.assert_osk_eventually_hidden()
        self.assert_page_eventually_loaded(url)
        self.ensure_activity_view_visible()
        self.toggle_close_tab_mode()
        tab = self.main_window.get_tabslist_view_delegates()[0]
        self.pointing_device.click_object(tab)
        self.assertThat(
            lambda: len(self.main_window.get_tabslist_view_delegates()),
            Eventually(Equals(1)))
        view = self.main_window.get_tabslist_view()
        self.assertThat(view.count, Eventually(Equals(1)))
        self.assertThat(view.currentIndex, Eventually(Equals(0)))
        self.assert_current_url(url)

    def test_close_last_open_tab(self):
        self.ensure_activity_view_visible()
        self.toggle_close_tab_mode()
        tab = self.main_window.get_tabslist_view_delegates()[0]
        self.pointing_device.click_object(tab)
        browser = self.main_window.get_browser()
        self.assertThat(browser.currentIndex, Eventually(Equals(0)))
        self.assert_activity_view_eventually_hidden()
        self.assert_osk_eventually_shown()
        self.assert_chrome_eventually_shown()
        address_bar = self.main_window.get_address_bar()
        self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))

    def test_open_target_blank_in_new_tab(self):
        url = self.base_url + "/blanktargetlink"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        browser = self.main_window.get_browser()
        self.assertThat(browser.currentIndex, Eventually(Equals(1)))
        self.assert_current_url(self.base_url + "/aleaiactaest")

    def test_open_iframe_target_blank_in_new_tab(self):
        url = self.base_url + "/fulliframewithblanktargetlink"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        browser = self.main_window.get_browser()
        self.assertThat(browser.currentIndex, Eventually(Equals(1)))
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

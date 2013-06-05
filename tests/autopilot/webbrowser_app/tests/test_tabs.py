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

    def test_tabs_model(self):
        listview = self.main_window.get_tabslist_listview()
        self.assertThat(listview.count, Eventually(Equals(1)))

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
        listview = self.main_window.get_tabslist_listview()
        self.assertThat(listview.currentIndex, Equals(0))
        newtab_delegate = self.main_window.get_tabslist_newtab_delegate()
        self.pointing_device.move_to_object(newtab_delegate)
        self.pointing_device.click()
        self.assertThat(listview.count, Eventually(Equals(2)))
        self.assertThat(listview.currentIndex, Eventually(Equals(1)))
        activity_view = self.main_window.get_activity_view()
        self.assertThat(activity_view.visible, Eventually(Equals(False)))
        self.assert_chrome_eventually_shown()
        address_bar = self.main_window.get_address_bar()
        self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))

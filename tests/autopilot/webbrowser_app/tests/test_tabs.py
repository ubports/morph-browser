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

from webbrowser_app.tests import BrowserTestCaseBase


class TestTabs(BrowserTestCaseBase):

    """Tests tabs management."""

    def test_tabs_model(self):
        listview = self.main_window.get_tabslist_listview()
        self.assertThat(listview.count, Eventually(Equals(1)))

    def test_toggle_activity_view(self):
        self.ensure_chrome_is_hidden()
        self.reveal_chrome()
        activity_view = self.main_window.get_activity_view()
        self.assertThat(activity_view.visible, Equals(False))
        tabs_button = self.main_window.get_tabs_button()
        self.pointing_device.move_to_object(tabs_button)
        self.pointing_device.click()
        self.assertThat(activity_view.visible, Eventually(Equals(True)))
        self.assert_chrome_eventually_hidden()
        self.reveal_chrome()
        self.pointing_device.move_to_object(tabs_button)
        self.pointing_device.click()
        self.assertThat(activity_view.visible, Eventually(Equals(False)))

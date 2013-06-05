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
        listview = self.main_window.get_tabs_list_listview()
        self.assertThat(listview.count, Eventually(Equals(1)))

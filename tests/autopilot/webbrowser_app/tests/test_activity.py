# -*- coding: utf-8 -*-
#
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

from __future__ import absolute_import

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestActivity(StartOpenRemotePageTestCaseBase):

    """Tests the activity view."""

    def test_validating_url_hides_activity_view(self):
        self.ensure_activity_view_visible()
        self.assert_chrome_eventually_hidden()
        self.main_window.open_toolbar()
        self.clear_address_bar()
        url = self.base_url + "/aleaiactaest"
        self.type_in_address_bar(url)
        self.keyboard.press_and_release("Enter")
        self.assert_activity_view_eventually_hidden()
        self.assert_page_eventually_loaded(url)

# -*- coding: utf-8 -*-
#
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

from __future__ import absolute_import

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestContentPick(StartOpenRemotePageTestCaseBase):

    """Tests that picking content works properly."""

    def test_pick_image(self):
        url = self.base_url + "/uploadform"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)

        # How does one get the content picking dialog that gets opened
        # by the browser ?
        # self.main_window.wait_select_single("ContentPickerDialog")




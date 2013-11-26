# -*- coding: utf-8 -*-
#
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

from __future__ import absolute_import

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase
from unity8 import process_helpers as helpers
from autopilot.introspection import get_proxy_object_for_existing_process
from autopilot.matchers import Eventually
from testtools.matchers import Equals
import os

class TestContentPick(StartOpenRemotePageTestCaseBase):

    """Tests that picking content works properly."""

    def test_pick_image(self):
        url = self.base_url + "/uploadform"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)

        # I don't know how to wait until the dialog is up,
        # because I can't access the dialog ;)
        self.main_window.print_tree("/tmp/tree")

#@skipIf(model() == 'Desktop', "Phablet only")
class TestContentPickerIntegration(StartOpenRemotePageTestCaseBase):

    def tearDown(self):
        os.system("pkill gallery-app")
        super(StartOpenRemotePageTestCaseBase, self).tearDown()

    def get_unity8_proxy_object(self):
        pid = helpers._get_unity_pid()
        return get_proxy_object_for_existing_process(pid)

    def get_current_focused_appid(self, unity8):
        return unity8.select_single("Shell").currentFocusedAppId

    def test_image_picker_is_gallery(self):
        url = self.base_url + "/uploadform"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)

        unity8 = self.get_unity8_proxy_object()
        self.assertThat(
            lambda: self.get_current_focused_appid(unity8),
            Eventually(Equals("gallery-app"))
        )

        self.main_window.print_tree("/tmp/tree")



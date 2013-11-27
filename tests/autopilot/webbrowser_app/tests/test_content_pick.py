# -*- coding: utf-8 -*-
#
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

from __future__ import absolute_import

from autopilot.introspection import get_proxy_object_for_existing_process
from autopilot.platform import model
from autopilot.matchers import Eventually
from testtools.matchers import Equals, NotEquals
from testtools import skipIf, skip
from webbrowser_app.tests import StartOpenRemotePageTestCaseBase
from unity8 import process_helpers as helpers
from ubuntuuitoolkit import emulators as toolkit_emulators
import os, subprocess

@skip("Will not work until bug #1255077 is solved")
class TestContentPick(StartOpenRemotePageTestCaseBase):

    """Tests that content picking dialog show up."""

    def test_pick_image(self):
        url = self.base_url + "/uploadform"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)

        # I don't know how to wait until the dialog is up,
        # because I can't access the dialog ;)
        # TODO: access the ContentPickerDialog here

@skipIf(model() == 'Desktop', "Phablet only")
class TestContentPickerIntegration(StartOpenRemotePageTestCaseBase):

    """Tests that the gallery app is brought up to choose image content"""

    def tearDown(self):
        os.system("pkill gallery-app")
        os.system("pkill webbrowser-app")
        super(StartOpenRemotePageTestCaseBase, self).tearDown()

    def get_unity8_proxy_object(self):
        pid = helpers._get_unity_pid()
        return get_proxy_object_for_existing_process(pid)

    def get_current_focused_appid(self, unity8):
        return unity8.select_single("Shell").currentFocusedAppId

    def set_testability_environment_variable(self):
        """Makes sure every app opened in the environment loads the
        testability driver."""

        subprocess.check_call([
            "/sbin/initctl",
            "set-env",
            "QT_LOAD_TESTABILITY=1"
        ])

    def get_app_pid(self, app):
        try:
            return int(subprocess.check_output(["pidof", app]).strip())
        except CalledProcessError:
            return -1

    def test_image_picker_is_gallery(self):
        url = self.base_url + "/uploadform"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)

        unity8 = self.get_unity8_proxy_object()
        shell = unity8.select_single("Shell")
        self.assertThat(
            lambda: self.get_current_focused_appid(unity8),
            Eventually(Equals("gallery-app"))
        )

    def test_image_picker_pick_image(self):
        self.set_testability_environment_variable()
        self.test_image_picker_is_gallery()

        unity8 = self.get_unity8_proxy_object()
        self.assertThat(lambda: self.get_app_pid("gallery-app"), Eventually(NotEquals(-1)))

        gallery_proxy = get_proxy_object_for_existing_process(
            self.get_app_pid("gallery-app"),
            emulator_base = toolkit_emulators.UbuntuUIToolkitEmulatorBase
        )

        print gallery_proxy
        print gallery_proxy.wait_select_single("QQuickView") # This works
        print gallery_proxy.wait_select_single("Loader", objectName="pickLoader") # This doesn't
        print gallery_proxy.wait_select_single("PickerMainView", objectName="pickerMainView") # This doesn't too
        print gallery_proxy.wait_select_single("MainView", objectName="pickerMainView") # This doesn't too




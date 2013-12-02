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
        except subprocess.CalledProcessError:
            return -1

    def wait_app_focused(self, name):
        unity8 = self.get_unity8_proxy_object()
        shell = unity8.select_single("Shell")
        self.assertThat(
            lambda: self.get_current_focused_appid(unity8),
            Eventually(Equals(name))
        )

    def test_image_picker_is_gallery(self):
        """ Tests that the gallery shows up when we are picking images """

        # Go to a page where clicking anywhere equals clicking on the
        # file selection button of an upload form
        url = self.base_url + "/uploadform"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)

        # Verify that such a click brings up the gallery to select images
        self.wait_app_focused("gallery-app")

    def test_image_picker_pick_image(self):
        """ Tests that the we can select an image in the gallery and
            control will return to the browser with the choosen image
            picked."""
        self.set_testability_environment_variable()
        self.test_image_picker_is_gallery()

        unity8 = self.get_unity8_proxy_object()
        self.assertThat(lambda: self.get_app_pid("gallery-app"), Eventually(NotEquals(-1)))

        gallery = get_proxy_object_for_existing_process(
            self.get_app_pid("gallery-app"),
            emulator_base = toolkit_emulators.UbuntuUIToolkitEmulatorBase
        )

        view = gallery.wait_select_single("QQuickView")
        self.assertThat(view.visible, Eventually(Equals(True)))

        # Select the first picture on the picker by clicking on it
        grid = gallery.wait_select_single("MediaGrid")
        photo = grid.select_many("OrganicItemInteraction")[0]
        self.pointing_device.move_to_object(photo)
        self.pointing_device.click()
        self.assertThat(photo.isSelected, Eventually(Equals(True)))

        # This will enable the "Pick" button, and we will click on it
        button = gallery.select_single("Button", objectName="pickButton")
        self.assertThat(button.enabled, Eventually(Equals(True)))
        self.pointing_device.move_to_object(button)
        self.pointing_device.click()

        # The gallery should close and focus returned to the browser
        self.wait_app_focused("webbrowser-app")

        # Verify that an image has actually been selected
#         This will currently fail because of bug #184753, so it's
#         disabled for now.
#        dialog = self.main_window.select_single("ContentPickerDialog")
#        self.assertThat(dialog.visible, Equals(True))
#        preview = dialog.select_single("Image", objectName="mediaPreview")
#        self.assertThat(preview.source, Eventually(NotEquals("")))

#        # Verify that now we can click the "OK" button and it closes the dialog
#        button = dialog.select_single("Button", objectName="ok")
#        self.assertThat(button.enabled, Eventually(Equals(True)))
#        self.pointing_device.move_to_object(button)
#        self.pointing_device.click()

#        self.assertThat(dialog.visible, Eventually(Equals(False)))

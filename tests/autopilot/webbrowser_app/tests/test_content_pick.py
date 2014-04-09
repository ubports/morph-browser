# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2014 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

from __future__ import absolute_import

from autopilot.introspection import get_proxy_object_for_existing_process
from autopilot.matchers import Eventually
from testtools.matchers import Equals, NotEquals
from testtools import skip
from webbrowser_app.tests import StartOpenRemotePageTestCaseBase
from unity8 import process_helpers as helpers
from ubuntuuitoolkit import emulators as toolkit_emulators
import os
import subprocess


@skip("Will not work until bug #1218971 is solved")
class TestContentPick(StartOpenRemotePageTestCaseBase):

    """Tests that content picking dialog show up."""

    def test_pick_image(self):
        url = self.base_url + "/uploadform"
        self.go_to_url(url)
        self.assert_page_eventually_loaded(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)

        dialog = self.app.wait_select_single("ContentPickerDialog")
        self.assertThat(dialog.visible, Equals(True))


#@skipIf(model() == 'Desktop', "Phablet only")
@skip("Currently unable to fetch dynamically created dialogs (bug #1218971)")
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
        """Return the PID of the named app, or -1 if it's not
        running"""

        try:
            return int(subprocess.check_output(["pidof", app]).strip())
        except subprocess.CalledProcessError:
            return -1

    def wait_app_focused(self, name):
        """Wait until the app with the specified name is the
        currently focused one"""

        unity8 = self.get_unity8_proxy_object()
        self.assertThat(
            lambda: self.get_current_focused_appid(unity8),
            Eventually(Equals(name))
        )

    def test_image_picker_is_gallery(self):
        """ Tests that the gallery shows up when we are picking
        images """

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

        # First run the previous test to bring up the content picker
        self.set_testability_environment_variable()
        self.test_image_picker_is_gallery()

        # Now wait until the gallery-app process is up.
        # NOTE: this will not work unless run on a device where unity8 runs in
        # testability mode. To manually restart unity8 in this mode run from a
        # python shell:
        # from unity8 import process_helpers as p
        # p.restart_unity_with_testability()
        self.assertThat(lambda: self.get_app_pid("gallery-app"),
                        Eventually(NotEquals(-1)))

        gallery = get_proxy_object_for_existing_process(
            self.get_app_pid("gallery-app"),
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase
        )

        # Wait for the gallery UI to completely display
        view = gallery.wait_select_single("QQuickView")
        self.assertThat(view.visible, Eventually(Equals(True)))

        # Select the first picture on the picker by clicking on it
        # NOTE: this is currently failing if there is anything except two
        # pictures in the gallery (at least on a Maguro device), so I'm
        # putting a temporary stop to the test here so that it won't break
        # in Jenkins
        return

        grid = gallery.wait_select_single("MediaGrid")
        photo = grid.select_many("OrganicItemInteraction")[0]
        self.pointing_device.click_object(photo)
        self.assertThat(photo.isSelected, Eventually(Equals(True)))

        # Now the "Pick" button will be enabled and we click on it
        button = gallery.select_single("Button", objectName="pickButton")
        self.assertThat(button.enabled, Eventually(Equals(True)))
        self.pointing_device.click_object(button)

        # The gallery should close and focus returned to the browser
        self.wait_app_focused("webbrowser-app")

        # Verify that an image has actually been selected
        dialog = self.app.wait_select_single("ContentPickerDialog")
        self.assertThat(dialog.visible, Equals(True))
        preview = dialog.wait_select_single("QQuickImage",
                                            objectName="mediaPreview")
        self.assertThat(preview.source, Eventually(NotEquals("")))

        # Verify that now we can click the "OK" button and it closes the dialog
        button = dialog.wait_select_single("Button", objectName="ok")
        self.assertThat(button.enabled, Eventually(Equals(True)))
        self.pointing_device.click_object(button)
        self.assertThat(dialog.visible, Eventually(Equals(False)))

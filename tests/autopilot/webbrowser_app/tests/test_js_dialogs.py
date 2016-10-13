# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2016 Canonical
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

from testtools.matchers import Equals
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestJSDialogs(StartOpenRemotePageTestCaseBase):

    def test_alert(self):
        url = self.base_url + "/js-alert-dialog"
        self.main_window.go_to_url(url)

        dialog = self.main_window.get_alert_dialog()
        dialog.visible.wait_for(True)

        # Check alert text is correct
        self.assertThat(dialog.text, Equals("Alert Dialog"))

        # Click OK, check dialog is destroyed
        self.pointing_device.click_object(dialog.get_ok_button())
        dialog.wait_until_destroyed()

    def test_before_unload_leave(self):
        beforeUnloadUrl = self.base_url + "/js-before-unload-dialog"
        testUrl = self.base_url + "/test1"

        self.main_window.go_to_url(beforeUnloadUrl)
        self.main_window.wait_until_page_loaded(beforeUnloadUrl)

        # Change the url to trigger window.onBeforeUnload
        self.main_window.go_to_url(testUrl)

        dialog = self.main_window.get_before_unload_dialog()
        dialog.visible.wait_for(True)

        # Click leave, wait for dialog to close and check that url changes
        self.pointing_device.click_object(dialog.get_leave_button())
        dialog.wait_until_destroyed()

        self.assertThat(self.main_window.get_current_webview().url,
                        Eventually(Equals(testUrl)))

    def test_before_unload_stay(self):
        beforeUnloadUrl = self.base_url + "/js-before-unload-dialog"
        testUrl = self.base_url + "/test1"

        self.main_window.go_to_url(beforeUnloadUrl)
        self.main_window.wait_until_page_loaded(beforeUnloadUrl)

        # Change the url to trigger window.onBeforeUnload
        self.main_window.go_to_url(testUrl)

        dialog = self.main_window.get_before_unload_dialog()
        dialog.visible.wait_for(True)

        # Click stay, wait for dialog to close and check url does not change
        self.pointing_device.click_object(dialog.get_stay_button())
        dialog.wait_until_destroyed()

        self.assertThat(self.main_window.get_current_webview().url,
                        Eventually(Equals(beforeUnloadUrl)))

    def test_confirm_cancel(self):
        url = self.base_url + "/js-confirm-dialog"
        self.main_window.go_to_url(url)

        dialog = self.main_window.get_confirm_dialog()
        dialog.visible.wait_for(True)

        # Check that confirm text is correct
        self.assertThat(dialog.text, Equals("Confirm Dialog"))

        # Click cancel and check that dialog is destroyed
        self.pointing_device.click_object(dialog.get_cancel_button())
        dialog.wait_until_destroyed()

        # Check that title changes to cancel
        self.assertThat(self.main_window.get_current_webview().title,
                        Eventually(Equals("CANCEL")))

    def test_confirm_ok(self):
        url = self.base_url + "/js-confirm-dialog"
        self.main_window.go_to_url(url)

        dialog = self.main_window.get_confirm_dialog()
        dialog.visible.wait_for(True)

        # Check that confirm text is correct
        self.assertThat(dialog.text, Equals("Confirm Dialog"))

        # Click OK and check that dialog is destroyed
        self.pointing_device.click_object(dialog.get_ok_button())
        dialog.wait_until_destroyed()

        # Check that title changes to OK
        self.assertThat(self.main_window.get_current_webview().title,
                        Eventually(Equals("OK")))

    def test_prompt_cancel(self):
        url = self.base_url + "/js-prompt-dialog"
        self.main_window.go_to_url(url)

        dialog = self.main_window.get_prompt_dialog()
        dialog.visible.wait_for(True)

        # Check that prompt text is correct and default textfield
        self.assertThat(dialog.text, Equals("Prompt Dialog"))
        self.assertThat(dialog.get_input_textfield().text,
                        Equals("Default"))

        # Click cancel and check that dialog is destroyed
        self.pointing_device.click_object(dialog.get_cancel_button())
        dialog.wait_until_destroyed()

        # Check that title changes to cancel
        self.assertThat(self.main_window.get_current_webview().title,
                        Eventually(Equals("CANCEL")))

    def test_prompt_ok(self):
        url = self.base_url + "/js-prompt-dialog"
        self.main_window.go_to_url(url)

        dialog = self.main_window.get_prompt_dialog()
        dialog.visible.wait_for(True)

        # Check that prompt text is correct and default textfield
        self.assertThat(dialog.text, Equals("Prompt Dialog"))
        self.assertThat(dialog.get_input_textfield().text,
                        Equals("Default"))

        # Enter text into textfield
        text = "TEST"
        entry = dialog.get_input_textfield()
        entry.write(text)

        # Click ok and check that dialog is destroyed
        self.pointing_device.click_object(dialog.get_ok_button())
        dialog.wait_until_destroyed()

        # Check that title changes to text entered in textfield
        self.assertThat(self.main_window.get_current_webview().title,
                        Eventually(Equals(text)))

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

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase

from testtools.matchers import Equals
from autopilot.matchers import Eventually


class DialogWrapper(object):
    def __init__(self, dialog):
        self.dialog = dialog

        self.text = self.dialog.text
        self.wait_until_destroyed = self.dialog.wait_until_destroyed
        self.visible = self.dialog.visible


class AlertDialog(DialogWrapper):
    def get_ok_button(self):
        return self.dialog.select_single("Button", objectName="okButton")


class BeforeUnloadDialog(DialogWrapper):
    def get_leave_button(self):
        return self.dialog.select_single("Button", objectName="leaveButton")

    def get_stay_button(self):
        return self.dialog.select_single("Button", objectName="stayButton")


class ConfirmDialog(DialogWrapper):
    def get_cancel_button(self):
        return self.dialog.select_single("Button", objectName="cancelButton")

    def get_ok_button(self):
        return self.dialog.select_single("Button", objectName="okButton")


class PromptDialog(DialogWrapper):
    def get_cancel_button(self):
        return self.dialog.select_single("Button", objectName="cancelButton")

    def get_input_textfield(self):
        return self.dialog.select_single("TextField",
                                         objectName="inputTextField")

    def get_ok_button(self):
        return self.dialog.select_single("Button", objectName="okButton")


class TestJSDialogs(WebappContainerTestCaseWithLocalContentBase):

    def test_alert(self):
        self.launch_webcontainer_app_with_local_http_server(
            [], '/js-alert-dialog', ignore_focus=True)

        dialog = AlertDialog(
            self.app.wait_select_single("Dialog", objectName="alertDialog")
        )
        dialog.visible.wait_for(True)

        # Check alert text is correct
        self.assertThat(dialog.text, Equals("Alert Dialog"))

        # Click OK, check dialog is destroyed
        self.pointing_device.click_object(dialog.get_ok_button())
        dialog.wait_until_destroyed()

    def test_before_unload_leave(self):
        testUrl = self.base_url + "/"

        self.launch_webcontainer_app_with_local_http_server(
            [], '/js-before-unload-dialog', ignore_focus=True)

        # Change the url to trigger window.onBeforeUnload
        self.browse_to(testUrl, wait_for_load=False)

        dialog = BeforeUnloadDialog(
            self.app.wait_select_single("Dialog",
                                        objectName="beforeUnloadDialog")
        )
        dialog.visible.wait_for(True)

        # Click leave, wait for dialog to close and check that url changes
        self.pointing_device.click_object(dialog.get_leave_button())
        dialog.wait_until_destroyed()

        self.assertThat(self.get_oxide_webview().url,
                        Eventually(Equals(testUrl)))

    def test_before_unload_stay(self):
        page = '/js-before-unload-dialog'
        beforeUnloadUrl = self.base_url + page
        testUrl = self.base_url + "/"

        self.launch_webcontainer_app_with_local_http_server(
            [], page, ignore_focus=True)

        # Change the url to trigger window.onBeforeUnload
        self.browse_to(testUrl, wait_for_load=False)

        dialog = BeforeUnloadDialog(
            self.app.wait_select_single("Dialog",
                                        objectName="beforeUnloadDialog")
        )
        dialog.visible.wait_for(True)

        # Click stay, wait for dialog to close and check url does not change
        self.pointing_device.click_object(dialog.get_stay_button())
        dialog.wait_until_destroyed()

        self.assertThat(self.get_oxide_webview().url,
                        Eventually(Equals(beforeUnloadUrl)))

    def test_confirm_cancel(self):
        self.launch_webcontainer_app_with_local_http_server(
            [], '/js-confirm-dialog', ignore_focus=True)

        dialog = ConfirmDialog(
            self.app.wait_select_single("Dialog", objectName="confirmDialog")
        )
        dialog.visible.wait_for(True)

        # Check that confirm text is correct
        self.assertThat(dialog.text, Equals("Confirm Dialog"))

        # Click cancel and check that dialog is destroyed
        self.pointing_device.click_object(dialog.get_cancel_button())
        dialog.wait_until_destroyed()

        # Check that title changes to cancel
        self.assertThat(self.get_webcontainer_webview().title,
                        Eventually(Equals("CANCEL")))

    def test_confirm_ok(self):
        self.launch_webcontainer_app_with_local_http_server(
            [], '/js-confirm-dialog', ignore_focus=True)

        dialog = ConfirmDialog(
            self.app.wait_select_single("Dialog", objectName="confirmDialog")
        )
        dialog.visible.wait_for(True)

        # Check that confirm text is correct
        self.assertThat(dialog.text, Equals("Confirm Dialog"))

        # Click OK and check that dialog is destroyed
        self.pointing_device.click_object(dialog.get_ok_button())
        dialog.wait_until_destroyed()

        # Check that title changes to OK
        self.assertThat(self.get_webcontainer_webview().title,
                        Eventually(Equals("OK")))

    def test_prompt_cancel(self):
        self.launch_webcontainer_app_with_local_http_server(
            [], '/js-prompt-dialog', ignore_focus=True)

        dialog = PromptDialog(
            self.app.wait_select_single("Dialog", objectName="promptDialog")
        )
        dialog.visible.wait_for(True)

        # Check that prompt text is correct and default textfield
        self.assertThat(dialog.text, Equals("Prompt Dialog"))
        self.assertThat(dialog.get_input_textfield().text,
                        Equals("Default"))

        # Click cancel and check that dialog is destroyed
        self.pointing_device.click_object(dialog.get_cancel_button())
        dialog.wait_until_destroyed()

        # Check that title changes to cancel
        self.assertThat(self.get_webcontainer_webview().title,
                        Eventually(Equals("CANCEL")))

    def test_prompt_ok(self):
        self.launch_webcontainer_app_with_local_http_server(
            [], '/js-prompt-dialog', ignore_focus=True)

        dialog = PromptDialog(
            self.app.wait_select_single("Dialog", objectName="promptDialog")
        )
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
        self.assertThat(self.get_webcontainer_webview().title,
                        Eventually(Equals(text)))

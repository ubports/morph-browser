# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2015 Canonical
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

from datetime import datetime

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase

from testtools.matchers import Equals, NotEquals
from autopilot.matchers import Eventually

import ubuntuuitoolkit as uitk

from webbrowser_app.emulators import browser


class TestSettings(StartOpenRemotePageTestCaseBase):

    def get_homepage_dialog(self):
        return self.main_window.wait_select_single("Dialog",
                                                   objectName="homepageDialog")

    def test_open_close_settings_page(self):
        settings = self.open_settings()
        settings.get_header().click_back_button()
        settings.wait_until_destroyed()

    def test_change_homepage(self):
        settings = self.open_settings()
        homepage = settings.get_homepage_entry()
        old = homepage.subText
        self.assertThat(old, NotEquals(""))

        # First test cancelling the edition
        self.pointing_device.click_object(homepage)
        dialog = self.get_homepage_dialog()
        textField = dialog.select_single(uitk.TextField,
                                         objectName="homepageDialog.text")
        self.assertThat(textField.text, Eventually(Equals(old)))
        cancel_button = dialog.select_single(
            "Button",
            objectName="homepageDialog.cancelButton")
        self.pointing_device.click_object(cancel_button)
        dialog.wait_until_destroyed()
        self.assertThat(homepage.subText, Equals(old))

        # Then test actually changing the homepage
        self.pointing_device.click_object(homepage)
        dialog = self.get_homepage_dialog()
        textField = dialog.select_single(uitk.TextField,
                                         objectName="homepageDialog.text")
        self.assertThat(textField.text, Eventually(Equals(old)))
        self.pointing_device.click_object(textField)
        textField.activeFocus.wait_for(True)
        new = "http://example.org/{}".format(int(datetime.now().timestamp()))
        textField.write(new, True)
        save_button = dialog.select_single(
            "Button",
            objectName="homepageDialog.saveButton")
        self.pointing_device.click_object(save_button)
        dialog.wait_until_destroyed()
        self.assertThat(homepage.subText, Eventually(Equals(new)))

    def test_open_close_privacy_settings(self):
        settings = self.open_settings()
        privacy = settings.get_privacy_entry()
        self.pointing_device.click_object(privacy)
        privacy_page = settings.get_privacy_page()
        privacy_header = privacy_page.select_single(browser.SettingsPageHeader)
        privacy_header.click_back_button()
        privacy_page.wait_until_destroyed()

    def test_clear_browsing_history(self):
        settings = self.open_settings()
        privacy = settings.get_privacy_entry()
        self.pointing_device.click_object(privacy)
        privacy_page = settings.get_privacy_page()
        clear_history = privacy_page.select_single(
            "Standard",
            objectName="privacy.clearHistory")
        self.assertThat(clear_history.enabled, Equals(True))
        self.pointing_device.click_object(clear_history)
        self.assertThat(clear_history.enabled, Eventually(Equals(False)))

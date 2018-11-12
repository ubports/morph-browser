# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2015-2016 Canonical
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

from testtools.matchers import Equals, GreaterThan, NotEquals
from autopilot.matchers import Eventually

import ubuntuuitoolkit as uitk

from webbrowser_app.emulators import browser


class TestSettings(StartOpenRemotePageTestCaseBase):

    def get_homepage_dialog(self):
        return self.main_window.wait_select_single("Dialog",
                                                   objectName="homepageDialog")

    def get_privacy_confirm_dialog(self):
        return self.main_window.wait_select_single(
            "Dialog", objectName="privacyConfirmDialog")

    def test_open_close_settings_page(self):
        settings = self.open_settings()
        settings.get_header().click_back_button()
        settings.wait_until_destroyed()

    def test_open_close_searchengine_page(self):
        settings = self.open_settings()
        searchengine = settings.get_searchengine_entry()
        old_engine = searchengine.currentSearchEngineDisplayName
        self.assertThat(old_engine, NotEquals(""))
        self.pointing_device.click_object(searchengine)
        searchengine_page = settings.get_searchengine_page()
        searchengine_header = searchengine_page.select_single(
            browser.PageHeader)
        searchengine_header.click_back_button()
        searchengine_page.wait_until_destroyed()
        self.assertThat(searchengine.currentSearchEngineDisplayName,
                        Equals(old_engine))

    def test_change_searchengine(self):
        settings = self.open_settings()
        searchengine = settings.get_searchengine_entry()
        old_engine = searchengine.currentSearchEngineDisplayName
        self.assertThat(old_engine, NotEquals(""))
        self.pointing_device.click_object(searchengine)
        searchengine_page = settings.get_searchengine_page()
        self.assertThat(lambda: len(searchengine_page.select_many(
            objectName="searchEngineDelegate")),
            Eventually(GreaterThan(1)))
        delegates = searchengine_page.select_many(
            objectName="searchEngineDelegate")
        delegates.sort(key=lambda delegate: delegate.objectName)
        new_index = -1
        for (i, delegate) in enumerate(delegates):
            checkbox = delegate.select_single(uitk.CheckBox)
            if (new_index == -1) and not checkbox.checked:
                new_index = i
            self.assertThat(checkbox.checked,
                            Equals(delegate.displayName == old_engine))
        new_engine = delegates[new_index].displayName
        self.assertThat(new_engine, NotEquals(old_engine))
        self.pointing_device.click_object(
            delegates[new_index].select_single(uitk.CheckBox))
        searchengine_page.wait_until_destroyed()
        self.assertThat(searchengine.currentSearchEngineDisplayName,
                        Eventually(Equals(new_engine)))

    def test_change_homepage(self):
        settings = self.open_settings()
        homepage = settings.get_homepage_entry()
        old = homepage.currentHomepage
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
        self.assertThat(homepage.currentHomepage, Equals(old))

        # Then test actually changing the homepage
        self.pointing_device.click_object(homepage)
        dialog = self.get_homepage_dialog()
        textField = dialog.select_single(uitk.TextField,
                                         objectName="homepageDialog.text")
        self.assertThat(textField.text, Eventually(Equals(old)))
        textField.activeFocus.wait_for(True)
        new = "http://test/{}".format(int(datetime.now().timestamp()))
        textField.write(new, True)
        save_button = dialog.select_single(
            "Button",
            objectName="homepageDialog.saveButton")
        self.pointing_device.click_object(save_button)
        dialog.wait_until_destroyed()
        self.assertThat(homepage.currentHomepage, Eventually(Equals(new)))

    def test_open_close_privacy_settings(self):
        settings = self.open_settings()
        privacy = settings.get_privacy_entry()
        self.pointing_device.click_object(privacy)
        privacy_page = settings.get_privacy_page()
        privacy_header = privacy_page.select_single(browser.PageHeader)
        privacy_header.click_back_button()
        privacy_page.wait_until_destroyed()

    def test_clear_browsing_history(self):
        settings = self.open_settings()
        privacy = settings.get_privacy_entry()
        self.pointing_device.click_object(privacy)
        privacy_page = settings.get_privacy_page()
        clear_history = privacy_page.select_single(
            objectName="privacy.clearHistory")
        self.assertThat(clear_history.enabled, Equals(True))

        # First test cancelling the action
        self.pointing_device.click_object(clear_history)
        dialog = self.get_privacy_confirm_dialog()
        cancel_button = dialog.select_single(
            "Button", objectName="privacyConfirmDialog.cancelButton")
        self.pointing_device.click_object(cancel_button)
        dialog.wait_until_destroyed()
        self.assertThat(clear_history.enabled, Equals(True))

        # Then confirm the action
        self.pointing_device.click_object(clear_history)
        dialog = self.get_privacy_confirm_dialog()
        confirm_button = dialog.select_single(
            "Button", objectName="privacyConfirmDialog.confirmButton")
        self.pointing_device.click_object(confirm_button)
        dialog.wait_until_destroyed()
        self.assertThat(clear_history.enabled, Eventually(Equals(False)))

    def test_clear_cache(self):
        settings = self.open_settings()
        privacy = settings.get_privacy_entry()
        self.pointing_device.click_object(privacy)
        privacy_page = settings.get_privacy_page()
        clear_cache = privacy_page.select_single(
            objectName="privacy.clearCache")
        self.assertThat(clear_cache.enabled, Equals(True))

        # First test cancelling the action
        self.pointing_device.click_object(clear_cache)
        dialog = self.get_privacy_confirm_dialog()
        cancel_button = dialog.select_single(
            "Button", objectName="privacyConfirmDialog.cancelButton")
        self.pointing_device.click_object(cancel_button)
        dialog.wait_until_destroyed()
        self.assertThat(clear_cache.enabled, Equals(True))

        # Then confirm the action
        self.pointing_device.click_object(clear_cache)
        dialog = self.get_privacy_confirm_dialog()
        confirm_button = dialog.select_single(
            "Button", objectName="privacyConfirmDialog.confirmButton")
        self.pointing_device.click_object(confirm_button)
        dialog.wait_until_destroyed()
        self.assertThat(clear_cache.enabled, Eventually(Equals(True)))

    def test_reset_browser_settings(self):
        settings = self.open_settings()
        reset = settings.get_reset_settings_entry()
        self.pointing_device.click_object(reset)

        searchengine = settings.get_searchengine_entry()
        self.assertThat(searchengine.currentSearchEngineDisplayName,
                        Eventually(Equals("Google")))

        homepage = settings.get_homepage_entry()
        self.assertThat(homepage.currentHomepage,
                        Eventually(Equals("https://start.duckduckgo.com")))

        restore_session = settings.get_restore_session_entry()
        checkbox = restore_session.select_single(uitk.CheckBox)
        self.assertThat(checkbox.checked, Eventually(Equals(True)))

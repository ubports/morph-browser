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

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase

from autopilot.matchers import Eventually

from testtools.matchers import Equals


class TestDownloads(StartOpenRemotePageTestCaseBase):

    def test_open_close_downloads_page(self):
        downloads_page = self.open_downloads()
        downloads_page.get_header().click_back_button()
        downloads_page.wait_until_destroyed()

    def test_mimetype_download(self):
        self.main_window.go_to_url(self.base_url + "/downloadpdf")
        dialog = self.main_window.get_download_dialog()
        self.assertThat(dialog.visible, Eventually(Equals(True)))
        self.assertThat(dialog.mimeType, Eventually(Equals("application/pdf")))

    def test_generic_mimetype_download(self):
        self.main_window.go_to_url(self.base_url + "/downloadpdfgenericmime")
        dialog = self.main_window.get_download_dialog()
        self.assertThat(dialog.visible, Eventually(Equals(True)))
        self.assertThat(dialog.mimeType, Eventually(Equals("application/pdf")))

    def test_close_dialog(self):
        self.main_window.go_to_url(self.base_url + "/downloadpdf")
        dialog = self.main_window.get_download_dialog()
        self.assertThat(dialog.visible, Eventually(Equals(True)))
        dialog.click_cancel_button()
        self.assertThat(dialog.visible, Eventually(Equals(False)))

    def test_picker(self):
        self.main_window.go_to_url(self.base_url + "/downloadpdf")
        dialog = self.main_window.get_download_dialog()
        self.assertThat(dialog.visible, Eventually(Equals(True)))
        dialog.click_choose_app_button()

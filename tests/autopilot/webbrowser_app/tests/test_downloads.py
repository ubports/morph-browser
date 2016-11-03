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

from glob import glob
import subprocess


class TestDownloads(StartOpenRemotePageTestCaseBase):
    def test_open_close_downloads_page(self):
        downloads_page = self.open_downloads()
        downloads_page.get_header().click_back_button()
        downloads_page.wait_until_destroyed()

    def test_mimetype_download(self):
        self.main_window.go_to_url(self.base_url + "/downloadpdf")
        dialog = self.main_window.get_download_dialog()
        options_dialog = self.main_window.get_download_options_dialog()
        self.assertThat(options_dialog.visible, Eventually(Equals(True)))
        self.assertThat(dialog.mimeType, Eventually(Equals("application/pdf")))

    def test_generic_mimetype_download(self):
        self.main_window.go_to_url(self.base_url + "/downloadpdfgenericmime")
        dialog = self.main_window.get_download_dialog()
        options_dialog = self.main_window.get_download_options_dialog()
        self.assertThat(options_dialog.visible, Eventually(Equals(True)))
        self.assertThat(dialog.mimeType, Eventually(Equals("application/pdf")))

    def test_filename(self):
        self.main_window.go_to_url(self.base_url + "/downloadpdf")
        dialog = self.main_window.get_download_dialog()
        options_dialog = self.main_window.get_download_options_dialog()
        self.assertThat(options_dialog.visible, Eventually(Equals(True)))
        self.assertThat(dialog.filename, Eventually(Equals("test.pdf")))

    def test_close_dialog(self):
        self.main_window.go_to_url(self.base_url + "/downloadpdf")
        options_dialog = self.main_window.get_download_options_dialog()
        self.assertThat(options_dialog.visible, Eventually(Equals(True)))
        self.main_window.click_cancel_download_button()

    def test_download(self):
        self.main_window.go_to_url(self.base_url + "/downloadpdf")
        options_dialog = self.main_window.get_download_options_dialog()
        self.assertThat(options_dialog.visible, Eventually(Equals(True)))
        self.main_window.click_download_file_button()
        downloads_page = self.main_window.get_downloads_page()
        self.assertThat(downloads_page.visible, Eventually(Equals(True)))


class TestDownloadsWithContentHubTestability(TestDownloads):
    def setUp(self):
        # Run content-hub-peer-hook-wrapper which ensures that
        # content-hub-testability has been register for the ContentPeersModel

        # Find arch path of content-hub-peer-hook-wrapper
        path = glob("/usr/lib/*/content-hub/content-hub-peer-hook-wrapper")

        if len(path) > 0:
            proc = subprocess.run([path[0]])
            self.assertThat(proc.returncode, Equals(0))
        else:
            raise FileNotFoundError(
                "Could not find content-hub-peer-hook-wrapper, have you "
                "installed content-hub-testability?")

        super(TestDownloadsWithContentHubTestability, self).setUp()

    def test_picker(self):
        self.main_window.go_to_url(self.base_url + "/downloadpdf")
        options_dialog = self.main_window.get_download_options_dialog()
        self.assertThat(options_dialog.visible, Eventually(Equals(True)))
        self.main_window.click_choose_app_button()
        picker = self.main_window.get_peer_picker()
        self.assertThat(picker.visible, Eventually(Equals(True)))

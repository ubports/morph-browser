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
from autopilot.platform import model

from testtools.matchers import Equals

import ubuntuuitoolkit as uitk

import subprocess
import testtools


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

    @testtools.skipIf(model() != "Desktop",
                      "Desktop only due to switch_to_unfocused_window")
    def test_private_download(self):
        self.open_new_private_window()

        public_window = self.app.get_windows(incognito=False)[0]
        private_window = self.app.get_windows(incognito=True)[0]
        pdf_download_url = self.base_url + "/downloadpdf"

        # Download pdf in private window
        private_window.go_to_url(pdf_download_url)
        options_dialog = private_window.get_download_options_dialog()
        self.assertThat(options_dialog.visible, Eventually(Equals(True)))
        private_window.click_download_file_button()

        # Open downloads page in private window
        private_downloads_page = private_window.get_downloads_page()
        private_downloads_page.visible.wait_for(True)

        # Check that there is one url in the private downloads window
        entries = private_downloads_page.get_download_entries()
        self.assertThat(len(entries), Equals(1))
        self.assertThat(entries[0].url, Equals(pdf_download_url))
        self.assertThat(entries[0].incognito, Equals(True))

        # Focus public window
        self.switch_to_unfocused_window(public_window)

        # Open downloads page in public window
        public_downloads_page = self.open_downloads(public_window)
        public_downloads_page.visible.wait_for(True)

        # Check that there are no entries in the public downloads window
        entries = public_downloads_page.get_download_entries()
        self.assertThat(len(entries), Equals(0))


class TestDownloadsWithContentHubTestability(StartOpenRemotePageTestCaseBase):
    def setUp(self):
        # Run content-hub-peer-hook-wrapper which ensures that
        # content-hub-testability has been register for the ContentPeersModel

        # Find arch path of content-hub-peer-hook-wrapper
        path = ("/usr/lib/%s/content-hub/content-hub-peer-hook-wrapper" %
                uitk.base.get_host_multiarch())

        return_code = subprocess.check_call([path])
        self.assertThat(return_code, Equals(0))

        super(TestDownloadsWithContentHubTestability, self).setUp()

    def test_picker(self):
        self.main_window.go_to_url(self.base_url + "/downloadpdf")
        options_dialog = self.main_window.get_download_options_dialog()
        self.assertThat(options_dialog.visible, Eventually(Equals(True)))
        self.main_window.click_choose_app_button()
        picker = self.main_window.get_peer_picker()
        self.assertThat(picker.visible, Eventually(Equals(True)))

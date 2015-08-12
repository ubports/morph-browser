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

import os.path
import sqlite3
import time
import testtools

from autopilot.matchers import Eventually
from testtools.matchers import Equals

import ubuntuuitoolkit as uitk

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestBookmarkOptions(StartOpenRemotePageTestCaseBase):

    def setUp(self):
        self.create_temporary_profile()
        self.populate_bookmarks()
        super(TestBookmarkOptions, self).setUp()

    def populate_bookmarks(self):
        db_path = os.path.join(self.data_location, "bookmarks.sqlite")
        connection = sqlite3.connect(db_path)

        connection.execute("""CREATE TABLE IF NOT EXISTS folders
                              (folderId INTEGER PRIMARY KEY,
                              folder VARCHAR);""")
        rows = [
            "Actinide",
            "NobleGas",
        ]

        for row in rows:
            query = "INSERT INTO folders (folder) VALUES ('{}');"
            query = query.format(row)
            connection.execute(query)

        foldersId = dict(connection.execute("""SELECT folder, folderId
                                               FROM folders;"""))

        connection.execute("""CREATE TABLE IF NOT EXISTS bookmarks
                              (url VARCHAR, title VARCHAR, icon VARCHAR,
                              created INTEGER, folderId INTEGER);""")
        rows = [
            ("http://test/periodic-table/element/24/chromium",
             "Chromium - Element Information",
             0),
            ("http://test/periodic-table/element/77/iridium",
             "Iridium - Element Information",
             0),
            ("http://test/periodic-table/element/31/gallium",
             "Gallium - Element Information",
             0),
            ("http://test/periodic-table/element/116/livermorium",
             "Livermorium - Element Information",
             0),
            ("http://test/periodic-table/element/89/actinium",
             "Actinium - Element Information",
             foldersId['Actinide']),
            ("http://test/periodic-table/element/2/helium",
             "Helium - Element Information",
             foldersId['NobleGas']),
        ]
        for i, row in enumerate(rows):
            timestamp = int(time.time()) - i * 10
            query = "INSERT INTO bookmarks \
                     VALUES ('{}', '{}', '', {}, {});"
            query = query.format(row[0], row[1], timestamp, row[2])
            connection.execute(query)
        connection.commit()
        connection.close()

    def _get_bookmark_options(self):
        address_bar = self.main_window.address_bar
        bookmark_toggle = address_bar.get_bookmark_toggle()
        self.pointing_device.click_object(bookmark_toggle)
        return self.main_window.get_bookmark_options()

    def _assert_bookmark_count_in_folder(self, tab, folder_name, count):
        # in wide mode the list of urls in the default folder has the homepage
        # bookmark in it, but it does not in narrow mode
        if self.main_window.wide and folder_name == "":
            count += 1

        urls = tab.get_bookmarks(folder_name)
        self.assertThat(lambda: len(urls), Eventually(Equals(count)))

    def test_save_bookmarked_url_in_default_folder(self):
        new_tab = self.open_new_tab(open_tabs_view = True, expand_view = True)
        self._assert_bookmark_count_in_folder(new_tab, "", 4)

        url = self.base_url + "/test2"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)

        chrome = self.main_window.chrome
        self.assertThat(chrome.bookmarked, Eventually(Equals(False)))

        bookmark_options = self._get_bookmark_options()
        bookmark_options.click_dismiss_button()
        bookmark_options.wait_until_destroyed()

        self.assertThat(chrome.bookmarked, Eventually(Equals(True)))

        new_tab = self.open_new_tab(open_tabs_view = True, expand_view = True)
        self._assert_bookmark_count_in_folder(new_tab, "", 5)

    def test_save_bookmarked_url_in_existing_folder(self):
        new_tab = self.open_new_tab(open_tabs_view = True, expand_view = True)
        self.assertThat(lambda: len(new_tab.get_folder_names()),
                        Eventually(Equals(3)))
        self._assert_bookmark_count_in_folder(new_tab, "Actinide", 1)

        url = self.base_url + "/test2"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)

        chrome = self.main_window.chrome
        self.assertThat(chrome.bookmarked, Eventually(Equals(False)))

        bookmark_options = self._get_bookmark_options()

        option_selector = bookmark_options.get_save_in_option_selector()
        self.pointing_device.click_object(option_selector)
        option_selector.currentlyExpanded.wait_for(True)
        option_selector_delegate = option_selector.select_single(
            "OptionSelectorDelegate", text="Actinide")
        self.pointing_device.click_object(option_selector_delegate)
        option_selector.currentlyExpanded.wait_for(False)

        bookmark_options.click_dismiss_button()
        bookmark_options.wait_until_destroyed()

        self.assertThat(chrome.bookmarked, Eventually(Equals(True)))

        new_tab = self.open_new_tab(open_tabs_view = True, expand_view = True)
        self.assertThat(lambda: len(new_tab.get_folder_names()),
                        Eventually(Equals(3)))
        self._assert_bookmark_count_in_folder(new_tab, "Actinide", 2)

    def test_save_bookmarked_url_in_new_folder(self):
        new_tab = self.open_new_tab(open_tabs_view = True, expand_view = True)
        self.assertThat(lambda: len(new_tab.get_folder_names()),
                        Eventually(Equals(3)))

        url = self.base_url + "/test2"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)

        chrome = self.main_window.chrome
        self.assertThat(chrome.bookmarked, Eventually(Equals(False)))

        bookmark_options = self._get_bookmark_options()

        # First test cancelling the creation of a new folder
        bookmark_options.click_new_folder_button()
        dialog = self.main_window.get_new_bookmarks_folder_dialog()
        cancel_button = dialog.select_single(
            "Button", objectName="newFolderDialog.cancelButton")
        self.pointing_device.click_object(cancel_button)
        dialog.wait_until_destroyed()

        # Then test actually creating a new folder
        bookmark_options.click_new_folder_button()
        dialog = self.main_window.get_new_bookmarks_folder_dialog()
        text_field = dialog.select_single(uitk.TextField,
                                          objectName="newFolderDialog.text")
        text_field.activeFocus.wait_for(True)
        text_field.write("NewFolder", True)
        save_button = dialog.select_single(
            "Button", objectName="newFolderDialog.saveButton")
        self.pointing_device.click_object(save_button)
        dialog.wait_until_destroyed()

        bookmark_options.click_dismiss_button()
        bookmark_options.wait_until_destroyed()

        self.assertThat(chrome.bookmarked, Eventually(Equals(True)))

        new_tab = self.open_new_tab(open_tabs_view = True, expand_view = True)
        self.assertThat(lambda: len(new_tab.get_folder_names()),
                        Eventually(Equals(4)))
        self._assert_bookmark_count_in_folder(new_tab, "NewFolder", 1)

    @testtools.skip("Temporarily skipped until popover going out of view with"
                    " OSK is fixed http://pad.lv/1466222")
    def test_set_bookmark_title(self):
        url = self.base_url + "/test2"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)

        chrome = self.main_window.chrome
        self.assertThat(chrome.bookmarked, Eventually(Equals(False)))

        bookmark_options = self._get_bookmark_options()

        title_text_field = bookmark_options.get_title_text_field()
        self.pointing_device.click_object(title_text_field)
        title_text_field.activeFocus.wait_for(True)
        title_text_field.write("NewTitle", True)

        bookmark_options.click_dismiss_button()
        bookmark_options.wait_until_destroyed()

        self.assertThat(chrome.bookmarked, Eventually(Equals(True)))

        new_tab = self.open_new_tab(open_tabs_view = True, expand_view = True)
        self._assert_bookmark_count_in_folder(new_tab, "", 5)

        index = 0
        if self.main_view.wide:
            index += 1
        bookmark = new_tab.get_bookmarks("")[index]
        self.assertThat(bookmark.title, Equals("NewTitle"))

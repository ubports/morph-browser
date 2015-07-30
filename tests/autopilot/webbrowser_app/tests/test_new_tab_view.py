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

from autopilot.platform import model
from autopilot.matchers import Eventually
from testtools.matchers import Equals, NotEquals

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase

from ubuntuuitoolkit import ToolkitException

class TestNewTabViewLifetime(StartOpenRemotePageTestCaseBase):

    def test_new_tab_view_destroyed_when_browsing(self):
        if not self.main_window.wide:
            self.open_tabs_view()
        new_tab_view = self.open_new_tab()
        self.main_window.go_to_url(self.base_url + "/test2")
        new_tab_view.wait_until_destroyed()

    def test_new_tab_view_destroyed_when_closing_tab(self):
        if not self.main_window.wide:
            self.open_tabs_view()
        new_tab_view = self.open_new_tab()
        if self.main_window.wide:
            self.main_window.chrome.get_tabs_bar().close_tab(1)
        else:
            tabs_view = self.open_tabs_view()
            tabs_view.get_previews()[0].close()
            toolbar = self.main_window.get_recent_view_toolbar()
            toolbar.click_button("doneButton")
        new_tab_view.wait_until_destroyed()

    def test_new_tab_view_is_shared_between_tabs(self):
        # Open one new tab
        if not self.main_window.wide:
            self.open_tabs_view()
        new_tab_view = self.open_new_tab()
        # Open a second new tab
        if not self.main_window.wide:
            self.open_tabs_view()
        new_tab_view_2 = self.open_new_tab()
        # Verify that they share the same NewTabView instance
        self.assertThat(new_tab_view_2.id, Equals(new_tab_view.id))
        # Close the second new tab, and verify that the NewTabView instance
        # is still there
        if self.main_window.wide:
            self.main_window.chrome.get_tabs_bar().close_tab(2)
        else:
            tabs_view = self.open_tabs_view()
            tabs_view.get_previews()[0].close()
            toolbar = self.main_window.get_recent_view_toolbar()
            toolbar.click_button("doneButton")
            tabs_view.visible.wait_for(False)
        self.assertThat(new_tab_view.visible, Equals(True))
        # Close the first new tab, and verify that the NewTabView instance
        # is destroyed
        if self.main_window.wide:
            self.main_window.chrome.get_tabs_bar().close_tab(1)
        else:
            tabs_view = self.open_tabs_view()
            tabs_view.get_previews()[0].close()
            toolbar = self.main_window.get_recent_view_toolbar()
            toolbar.click_button("doneButton")
        new_tab_view.wait_until_destroyed()

    @testtools.skipIf(model() == "Desktop",
                      "Closing the last open tab on desktop quits the app")
    def test_new_tab_view_not_destroyed_when_closing_last_open_tab(self):
        if self.main_window.wide:
            self.main_window.chrome.get_tabs_bar().close_tab(0)
        else:
            tabs_view = self.open_tabs_view()
            tabs_view.get_previews()[0].close()
            tabs_view.visible.wait_for(False)
        new_tab_view = self.main_window.get_new_tab_view()
        # Verify that the new tab view is not destroyed and then re-created
        # when closing the last open tab if it was a blank one
        if self.main_window.wide:
            self.main_window.chrome.get_tabs_bar().close_tab(0)
        else:
            tabs_view = self.open_tabs_view()
            tabs_view.get_previews()[0].close()
            tabs_view.visible.wait_for(False)
        self.assertThat(new_tab_view.visible, Equals(True))


class TestNewPrivateTabViewLifetime(StartOpenRemotePageTestCaseBase):

    def test_new_private_tab_view_destroyed_when_browsing(self):
        self.main_window.enter_private_mode()
        new_private_tab_view = self.main_window.get_new_private_tab_view()
        self.main_window.go_to_url(self.base_url + "/test2")
        new_private_tab_view.wait_until_destroyed()

    def test_new_private_tab_view_destroyed_when_leaving_private_mode(self):
        self.main_window.enter_private_mode()
        new_private_tab_view = self.main_window.get_new_private_tab_view()
        self.main_window.leave_private_mode()
        new_private_tab_view.wait_until_destroyed()

    def test_new_private_tab_view_is_shared_between_tabs(self):
        self.main_window.enter_private_mode()
        new_private_tab_view = self.main_window.get_new_private_tab_view()
        self.main_window.go_to_url(self.base_url + "/test2")
        new_private_tab_view.wait_until_destroyed()
        # Open one new private tab
        if not self.main_window.wide:
            self.open_tabs_view()
        new_private_tab_view = self.open_new_tab()
        # Open a second new private tab
        if not self.main_window.wide:
            self.open_tabs_view()
        new_private_tab_view_2 = self.open_new_tab()
        # Verify that they share the same NewPrivateTabView instance
        self.assertThat(new_private_tab_view_2.id,
                        Equals(new_private_tab_view.id))
        # Close the second new private tab, and verify that the
        # NewPrivateTabView instance is still there
        if self.main_window.wide:
            self.main_window.chrome.get_tabs_bar().close_tab(2)
        else:
            tabs_view = self.open_tabs_view()
            tabs_view.get_previews()[0].close()
            toolbar = self.main_window.get_recent_view_toolbar()
            toolbar.click_button("doneButton")
            tabs_view.visible.wait_for(False)
        self.assertThat(new_private_tab_view.visible, Equals(True))
        # Close the first new private tab, and verify that the
        # NewPrivateTabView instance is destroyed
        if self.main_window.wide:
            self.main_window.chrome.get_tabs_bar().close_tab(1)
        else:
            tabs_view = self.open_tabs_view()
            tabs_view.get_previews()[0].close()
            toolbar = self.main_window.get_recent_view_toolbar()
            toolbar.click_button("doneButton")
        new_private_tab_view.wait_until_destroyed()


class TestNewTabViewContentsBase(StartOpenRemotePageTestCaseBase):

    def setUp(self):
        self.create_temporary_profile()
        self.populate_config()
        self.populate_bookmarks()
        super(TestNewTabViewContentsBase, self).setUp()
        if not self.main_window.wide:
            self.open_tabs_view()
        self.new_tab_view = self.open_new_tab()

    def populate_config(self):
        self.homepage = "http://test/test2"
        config_file = os.path.join(self.config_location, "webbrowser-app.conf")
        with open(config_file, "w") as f:
            f.write("[General]\n")
            f.write("homepage={}".format(self.homepage))

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


class TestNewTabViewContents(TestNewTabViewContentsBase):

    def test_default_home_bookmark(self):
        homepage_bookmark = self.new_tab_view.get_homepage_bookmark()
        self.assertThat(homepage_bookmark.url, Equals(self.homepage))
        self.pointing_device.click_object(homepage_bookmark)
        self.new_tab_view.wait_until_destroyed()
        self.main_window.wait_until_page_loaded(self.homepage)

    def test_open_top_site(self):
        top_sites = self.new_tab_view.get_top_sites_list()
        self.assertThat(lambda: len(top_sites.get_delegates()),
                        Eventually(Equals(1)))
        top_site = top_sites.get_delegates()[0]
        url = top_site.url
        self.pointing_device.click_object(top_site)
        self.new_tab_view.wait_until_destroyed()
        self.main_window.wait_until_page_loaded(url)

    def test_open_bookmark(self):
        bookmarks = self.new_tab_view.get_bookmarks_list()
        bookmark = bookmarks.get_delegates()[1]
        url = bookmark.url
        self.pointing_device.click_object(bookmark)
        self.new_tab_view.wait_until_destroyed()
        self.main_window.wait_until_page_loaded(url)


class TestNewTabViewContentsNarrow(TestNewTabViewContentsBase):

    def setUp(self):
        super(TestNewTabViewContentsNarrow, self).setUp()
        if self.main_window.wide:
            self.skipTest("Only on narrow form factors")

    def test_open_bookmark_when_expanded(self):
        more_button = self.new_tab_view.get_bookmarks_more_button()
        self.assertThat(more_button.visible, Equals(True))
        self.pointing_device.click_object(more_button)
        folders = self.main_window.get_bookmarks_folder_list_view()
        folder_delegate = folders.get_folder_delegate("")
        self.assertThat(lambda: len(folders.get_urls_from_folder(
                                    folder_delegate)),
                        Eventually(Equals(4)))
        bookmark = folders.get_urls_from_folder(folder_delegate)[0]
        url = bookmark.url
        self.pointing_device.click_object(bookmark)
        self.new_tab_view.wait_until_destroyed()
        self.main_window.wait_until_page_loaded(url)

    def test_bookmarks_section_expands_and_collapses(self):
        bookmarks = self.new_tab_view.get_bookmarks_list()
        top_sites = self.new_tab_view.get_top_sites_list()
        self.assertThat(top_sites.visible, Equals(True))
        # When the bookmarks list is collapsed, it shows a maximum of 4 entries
        self.assertThat(lambda: len(bookmarks.get_delegates()),
                        Eventually(Equals(4)))
        # When expanded, it shows all entries
        more_button = self.new_tab_view.get_bookmarks_more_button()
        self.assertThat(more_button.visible, Equals(True))
        self.pointing_device.click_object(more_button)
        folders = self.main_window.get_bookmarks_folder_list_view()
        folder_delegate = folders.get_folder_delegate("")
        self.assertThat(lambda: len(folders.get_urls_from_folder(
                                    folder_delegate)),
                        Eventually(Equals(4)))
        self.assertThat(top_sites.visible, Eventually(Equals(False)))
        # Collapse again
        self.assertThat(more_button.visible, Equals(True))
        self.pointing_device.click_object(more_button)
        self.assertThat(lambda: len(bookmarks.get_delegates()),
                        Eventually(Equals(4)))
        self.assertThat(top_sites.visible, Eventually(Equals(True)))

    def _remove_first_bookmark(self):
        bookmarks = self.new_tab_view.get_bookmarks_list()
        delegate = bookmarks.get_delegates()[0]
        url = delegate.url
        delegate.trigger_leading_action("leadingAction.delete",
                                        delegate.wait_until_destroyed)
        self.assertThat(lambda: bookmarks.get_urls()[0],
                        Eventually(NotEquals(url)))

    def _remove_first_bookmark_from_folder(self, folder):
        folders = self.main_window.get_bookmarks_folder_list_view()
        folder_delegate = folders.get_folder_delegate(folder)
        delegate = folders.get_urls_from_folder(folder_delegate)[0]
        url = delegate.url
        count = len(folders.get_urls_from_folder(folder_delegate))
        delegate.trigger_leading_action("leadingAction.delete",
                                        delegate.wait_until_destroyed)
        if ((count - 1) > 4):
            self.assertThat(
                lambda: folders.get_urls_from_folder(folder_delegate)[0],
                Eventually(NotEquals(url)))

    def test_remove_bookmarks_when_collapsed(self):
        bookmarks = self.new_tab_view.get_bookmarks_list()
        self.assertThat(lambda: len(bookmarks.get_delegates()),
                        Eventually(Equals(4)))
        more_button = self.new_tab_view.get_bookmarks_more_button()
        for i in range(3):
            self._remove_first_bookmark()
            self.assertThat(more_button.visible, Eventually(Equals(i < 1)))
            self.assertThat(len(bookmarks.get_delegates()),
                            Equals(4 if (i < 2) else 3))

    def test_remove_bookmarks_when_expanded(self):
        more_button = self.new_tab_view.get_bookmarks_more_button()
        self.assertThat(more_button.visible, Equals(True))
        self.pointing_device.click_object(more_button)
        folders = self.main_window.get_bookmarks_folder_list_view()
        folder_delegate = folders.get_folder_delegate("")
        self.assertThat(lambda: len(folders.get_urls_from_folder(
                                    folder_delegate)),
                        Eventually(Equals(4)))
        more_button = self.new_tab_view.get_bookmarks_more_button()
        top_sites = self.new_tab_view.get_top_sites_list()
        self._remove_first_bookmark_from_folder("Actinide")
        self._remove_first_bookmark_from_folder("NobleGas")
        self.assertThat(more_button.visible, Eventually(Equals(False)))
        self.assertThat(top_sites.visible, Eventually(Equals(True)))

    def test_show_bookmarks_folders_when_expanded(self):
        more_button = self.new_tab_view.get_bookmarks_more_button()
        self.assertThat(more_button.visible, Equals(True))
        self.pointing_device.click_object(more_button)
        folders = self.main_window.get_bookmarks_folder_list_view()
        self.assertThat(lambda: len(folders.get_delegates()),
                        Eventually(Equals(3)))
        folder_delegate = folders.get_folder_delegate("")
        self.assertThat(lambda: len(folders.get_urls_from_folder(
                                    folder_delegate)),
                        Eventually(Equals(4)))
        folder_delegate = folders.get_folder_delegate("Actinide")
        self.assertThat(lambda: len(folders.get_urls_from_folder(
                                    folder_delegate)),
                        Eventually(Equals(1)))
        folder_delegate = folders.get_folder_delegate("NobleGas")
        self.assertThat(lambda: len(folders.get_urls_from_folder(
                                    folder_delegate)),
                        Eventually(Equals(1)))

    def test_hide_empty_bookmarks_folders_when_expanded(self):
        more_button = self.new_tab_view.get_bookmarks_more_button()
        self.assertThat(more_button.visible, Equals(True))
        self.pointing_device.click_object(more_button)
        folders = self.main_window.get_bookmarks_folder_list_view()
        self.assertThat(lambda: len(folders.get_delegates()),
                        Eventually(Equals(3)))
        folder_delegate = folders.get_folder_delegate("Actinide")
        self.assertThat(lambda: len(folders.get_urls_from_folder(
                                    folder_delegate)),
                        Eventually(Equals(1)))
        self._remove_first_bookmark_from_folder("Actinide")
        self.assertThat(lambda: len(folders.get_delegates()),
                        Eventually(Equals(2)))
        folder_delegate = folders.get_folder_delegate("")
        self.assertThat(lambda: len(folders.get_urls_from_folder(
                                    folder_delegate)),
                        Eventually(Equals(4)))
        folder_delegate = folders.get_folder_delegate("NobleGas")
        self.assertThat(lambda: len(folders.get_urls_from_folder(
                                    folder_delegate)),
                        Eventually(Equals(1)))

    def test_bookmarks_folder_expands_and_collapses(self):
        more_button = self.new_tab_view.get_bookmarks_more_button()
        self.assertThat(more_button.visible, Equals(True))
        self.pointing_device.click_object(more_button)
        folders = self.main_window.get_bookmarks_folder_list_view()
        self.assertThat(lambda: len(folders.get_delegates()),
                        Eventually(Equals(3)))
        folder_delegate = folders.get_folder_delegate("")
        self.assertThat(lambda: len(folders.get_urls_from_folder(
                                    folder_delegate)),
                        Eventually(Equals(4)))
        self.pointing_device.click_object(
            folders.get_header_from_folder(folder_delegate))
        self.assertThat(lambda: len(folders.get_urls_from_folder(
                                    folder_delegate)),
                        Eventually(Equals(0)))
        self.pointing_device.click_object(
            folders.get_header_from_folder(folder_delegate))
        self.assertThat(lambda: len(folders.get_urls_from_folder(
                                    folder_delegate)),
                        Eventually(Equals(4)))

    def test_remove_top_sites(self):
        top_sites = self.new_tab_view.get_top_sites_list()
        self.assertThat(lambda: len(top_sites.get_delegates()),
                        Eventually(Equals(1)))
        notopsites_label = self.new_tab_view.get_notopsites_label()
        self.assertThat(notopsites_label.visible, Eventually(Equals(False)))
        delegate = top_sites.get_delegates()[0]
        delegate.trigger_leading_action("leadingAction.delete",
                                        delegate.wait_until_destroyed)
        self.assertThat(lambda: len(top_sites.get_delegates()),
                        Eventually(Equals(0)))
        self.assertThat(notopsites_label.visible, Eventually(Equals(True)))


class TestNewTabViewContentsWide(TestNewTabViewContentsBase):

    def setUp(self):
        super(TestNewTabViewContentsWide, self).setUp()
        if not self.main_window.wide:
            self.skipTest("Only on wide form factors")

    def test_remove_bookmarks(self):
        view = self.new_tab_view
        bookmarks = view.get_bookmarks_list()
        previous_count = len(bookmarks)
        bookmarks[1].trigger_leading_action("leadingAction.delete",
                                            bookmarks[1].wait_until_destroyed)
        bookmarks = view.get_bookmarks_list()
        self.assertThat(len(bookmarks), Equals(previous_count - 1))
        previous_count = len(bookmarks)

        # verify that trying to delete the homepage bookmark is not going to
        # do anything because there is no delete action on the delegate
        no_delete_action = False
        try:
            bookmarks[0].trigger_leading_action("leadingAction.delete")
        except ToolkitException:
            no_delete_action = True
        self.assertThat(no_delete_action, Equals(True))
        self.assertThat(len(view.get_bookmarks_list()), Equals(previous_count))

    def test_remove_top_sites(self):
        view = self.new_tab_view
        topsites = view.get_top_sites_list()
        previous_count = len(topsites)
        topsites[0].trigger_leading_action("leadingAction.delete",
                                            topsites[0].wait_until_destroyed)
        self.assertThat(len(view.get_top_sites_list()),
                        Equals(previous_count - 1))

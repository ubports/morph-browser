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

from testtools.matchers import Equals

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestNewTabViewLifetime(StartOpenRemotePageTestCaseBase):

    def test_new_tab_view_destroyed_when_browsing(self):
        self.open_tabs_view()
        new_tab_view = self.open_new_tab()
        self.main_window.go_to_url(self.base_url + "/test2")
        new_tab_view.wait_until_destroyed()

    def test_new_tab_view_destroyed_when_closing_tab(self):
        self.open_tabs_view()
        new_tab_view = self.open_new_tab()
        tabs_view = self.open_tabs_view()
        tabs_view.get_previews()[0].close()
        self.main_window.get_recent_view_toolbar().click_button("doneButton")
        new_tab_view.wait_until_destroyed()

    def test_new_tab_view_is_shared_between_tabs(self):
        # Open one new tab
        self.open_tabs_view()
        new_tab_view = self.open_new_tab()
        # Open a second new tab
        self.open_tabs_view()
        new_tab_view_2 = self.open_new_tab()
        # Verify that they share the same NewTabView instance
        self.assertThat(new_tab_view_2.id, Equals(new_tab_view.id))
        # Close the second new tab, and verify that the NewTabView instance
        # is still there
        tabs_view = self.open_tabs_view()
        tabs_view.get_previews()[0].close()
        self.main_window.get_recent_view_toolbar().click_button("doneButton")
        tabs_view.visible.wait_for(False)
        self.assertThat(new_tab_view.visible, Equals(True))
        # Close the first new tab, and verify that the NewTabView instance
        # is destroyed
        tabs_view = self.open_tabs_view()
        tabs_view.get_previews()[0].close()
        self.main_window.get_recent_view_toolbar().click_button("doneButton")
        new_tab_view.wait_until_destroyed()

    def test_new_tab_view_not_destroyed_when_closing_last_open_tab(self):
        tabs_view = self.open_tabs_view()
        tabs_view.get_previews()[0].close()
        tabs_view.visible.wait_for(False)
        new_tab_view = self.main_window.get_new_tab_view()
        # Verify that the new tab view is not destroyed and then re-created
        # when closing the last open tab if it was a blank one
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
        self.open_tabs_view()
        new_private_tab_view = self.open_new_tab()
        # Open a second new private tab
        self.open_tabs_view()
        new_private_tab_view_2 = self.open_new_tab()
        # Verify that they share the same NewPrivateTabView instance
        self.assertThat(new_private_tab_view_2.id,
                        Equals(new_private_tab_view.id))
        # Close the second new private tab, and verify that the
        # NewPrivateTabView instance is still there
        tabs_view = self.open_tabs_view()
        tabs_view.get_previews()[0].close()
        self.main_window.get_recent_view_toolbar().click_button("doneButton")
        tabs_view.visible.wait_for(False)
        self.assertThat(new_private_tab_view.visible, Equals(True))
        # Close the first new private tab, and verify that the
        # NewPrivateTabView instance is destroyed
        tabs_view = self.open_tabs_view()
        tabs_view.get_previews()[0].close()
        self.main_window.get_recent_view_toolbar().click_button("doneButton")
        new_private_tab_view.wait_until_destroyed()


class TestNewTabViewContents(StartOpenRemotePageTestCaseBase):

    def setUp(self):
        self.create_temporary_profile()
        self.homepage = "http://test/test2"
        config_file = os.path.join(self.config_location, "webbrowser-app.conf")
        with open(config_file, "w") as f:
            f.write("[General]\n")
            f.write("homepage={}".format(self.homepage))
        super(TestNewTabViewContents, self).setUp()

    def test_default_home_bookmark(self):
        self.open_tabs_view()
        new_tab_view = self.open_new_tab()
        homepage_bookmark = new_tab_view.get_homepage_bookmark()
        self.assertThat(homepage_bookmark.url, Equals(self.homepage))
        self.pointing_device.click_object(homepage_bookmark)
        new_tab_view.wait_until_destroyed()
        self.main_window.wait_until_page_loaded(self.homepage)

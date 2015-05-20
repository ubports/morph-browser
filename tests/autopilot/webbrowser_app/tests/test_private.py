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

from testtools.matchers import Equals, NotEquals
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestPrivateView(StartOpenRemotePageTestCaseBase):

    def get_url_list_from_top_sites(self):
        self.open_tabs_view()
        new_tab_view = self.open_new_tab()
        return new_tab_view.get_top_sites()

    def test_going_in_and_out_private_mode(self):
        address_bar = self.main_window.address_bar
        address_bar.focus()
        self.main_window.enter_private_mode()
        self.assertThat(self.main_window.is_in_private_mode,
                        Eventually(Equals(True)))
        self.assertTrue(self.main_window.is_new_private_tab_view_visible())
        self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))
        self.assertThat(address_bar.text, Eventually(Equals("")))

        self.main_window.leave_private_mode()
        self.assertThat(self.main_window.is_in_private_mode,
                        Eventually(Equals(False)))
        self.assertThat(address_bar.text, Eventually(NotEquals("")))
        self.assertThat(address_bar.activeFocus, Eventually(Equals(False)))

    def test_leaving_private_mode_with_multiples_tabs_ask_confirmation(self):
        self.main_window.enter_private_mode()
        self.assertThat(self.main_window.is_in_private_mode,
                        Eventually(Equals(True)))
        self.assertTrue(self.main_window.is_new_private_tab_view_visible())
        self.open_tabs_view()
        self.open_new_tab()
        self.main_window.leave_private_mode_with_confirmation()
        self.assertThat(self.main_window.is_in_private_mode,
                        Eventually(Equals(False)))

    def test_cancel_leaving_private_mode(self):
        self.main_window.enter_private_mode()
        self.assertThat(self.main_window.is_in_private_mode,
                        Eventually(Equals(True)))
        self.assertTrue(self.main_window.is_new_private_tab_view_visible())
        self.open_tabs_view()
        self.open_new_tab()
        self.main_window.leave_private_mode_with_confirmation(confirm=False)
        self.assertThat(self.main_window.is_in_private_mode,
                        Eventually(Equals(True)))
        self.assertTrue(self.main_window.is_new_private_tab_view_visible())

    def test_url_showing_in_top_sites_in_and_out_private_mode(self):
        top_sites = self.get_url_list_from_top_sites()
        self.assertIn(self.url, top_sites)

        self.main_window.enter_private_mode()
        self.assertThat(self.main_window.is_in_private_mode,
                        Eventually(Equals(True)))
        url = self.base_url + "/test2"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        self.main_window.leave_private_mode()
        self.assertThat(self.main_window.is_in_private_mode,
                        Eventually(Equals(False)))
        top_sites = self.get_url_list_from_top_sites()
        self.assertNotIn(url, top_sites)

    def test_public_tabs_should_not_be_visible_in_private_mode(self):
        self.open_tabs_view()
        self.open_new_tab()
        new_tab_view = self.main_window.get_new_tab_view()
        url = self.base_url + "/test2"
        self.main_window.go_to_url(url)
        new_tab_view.wait_until_destroyed()
        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = tabs_view.get_previews()
        self.assertThat(len(previews), Equals(2))
        self.main_window.get_recent_view_toolbar().click_button("doneButton")
        tabs_view.visible.wait_for(False)

        self.main_window.enter_private_mode()
        self.assertThat(self.main_window.is_in_private_mode,
                        Eventually(Equals(True)))
        self.assertTrue(self.main_window.is_new_private_tab_view_visible())
        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = tabs_view.get_previews()
        self.assertThat(len(previews), Equals(1))

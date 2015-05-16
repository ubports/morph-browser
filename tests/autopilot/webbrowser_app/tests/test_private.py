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

from testtools.matchers import Equals
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestPrivateView(StartOpenRemotePageTestCaseBase):

    def get_url_list_from_top_sites(self):
        self.open_tabs_view()
        new_tab_view = self.open_new_tab()
        return new_tab_view.get_top_sites()

    def test_going_in_and_out_private_mode(self):
        self.main_window.enter_private_mode()
        self.assertTrue(self.main_window.is_in_private_mode())
        self.assertTrue(self.main_window.is_new_private_tab_view_visible())
        self.main_window.leave_private_mode()
        self.assertFalse(self.main_window.is_in_private_mode())

    def test_cancel_leaving_private_mode(self):
        self.main_window.enter_private_mode()
        self.assertTrue(self.main_window.is_in_private_mode())
        self.assertTrue(self.main_window.is_new_private_tab_view_visible())
        self.main_window.leave_private_mode(confirm=False)
        self.assertTrue(self.main_window.is_in_private_mode())
        self.assertTrue(self.main_window.is_new_private_tab_view_visible())

    def test_url_must_not_be_shown_in_top_sites_in_private_mode(self):
        top_sites = self.get_url_list_from_top_sites()
        url = self.base_url + "/test2"
        self.assertNotIn(url, top_sites)

        self.main_window.enter_private_mode()
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        self.main_window.leave_private_mode()

        top_sites = self.get_url_list_from_top_sites()
        self.assertNotIn(url, top_sites)

    def test_url_must_be_shown_in_top_sites_after_leaving_private_mode(self):
        top_sites = self.get_url_list_from_top_sites()
        url = self.base_url + "/test2"
        self.assertNotIn(url, top_sites)

        self.main_window.enter_private_mode()
        self.main_window.leave_private_mode()
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)

        top_sites = self.get_url_list_from_top_sites()
        self.assertIn(url, top_sites)

    def test_address_bar_should_be_empty_after_going_in_private_mode(self):
        address_bar = self.main_window.address_bar
        address_bar.focus()
        self.main_window.enter_private_mode()
        self.assertTrue(self.main_window.is_in_private_mode())
        self.assertTrue(self.main_window.is_new_private_tab_view_visible())
        self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))
        self.assertFalse(address_bar.text)

    def test_address_bar_shouldnt_have_focus_when_leaving_private_mode(self):
        self.main_window.enter_private_mode()
        self.assertTrue(self.main_window.is_in_private_mode())
        self.assertTrue(self.main_window.is_new_private_tab_view_visible())
        address_bar = self.main_window.address_bar
        address_bar.focus()
        self.main_window.leave_private_mode()
        self.assertTrue(address_bar.text)
        self.assertThat(address_bar.activeFocus, Eventually(Equals(False)))

    def test_previews_tabs_must_not_be_visible_after_entering_private_mode(
            self):
        self.open_tabs_view()
        self.open_new_tab()
        new_tab_view = self.main_window.get_new_tab_view()
        url = self.base_url + "/test1"
        self.main_window.go_to_url(url)
        new_tab_view.wait_until_destroyed()
        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = tabs_view.get_previews()
        self.assertThat(len(previews), Equals(2))
        tabs_view.get_previews()[1].select()
        tabs_view.visible.wait_for(False)
        self.assertThat(lambda: self.main_window.get_current_webview().url,
                        Eventually(Equals(url)))

        self.main_window.enter_private_mode()
        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = tabs_view.get_previews()
        self.assertThat(len(previews), Equals(1))

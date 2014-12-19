# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2013-2014 Canonical
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
from autopilot.platform import model

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestTabsMixin(object):

    def check_current_tab(self, url):
        self.assertThat(lambda: self.main_window.get_current_webview().url,
                        Eventually(Equals(url)))


class TestTabsView(StartOpenRemotePageTestCaseBase, TestTabsMixin):

    def setUp(self):
        super(TestTabsView, self).setUp()
        self.open_tabs_view()

    def test_tabs_model(self):
        previews = self.main_window.get_tabs_view().get_previews()
        self.assertThat(len(previews), Equals(1))

    def test_close_tabs_view(self):
        tabs_view = self.main_window.get_tabs_view()
        done_button = tabs_view.get_done_button()
        self.pointing_device.click_object(done_button)
        tabs_view.wait_until_destroyed()

    def test_open_new_tab(self):
        self.open_new_tab()
        new_tab_view = self.main_window.get_new_tab_view()
        url = self.base_url + "/test2"
        self.main_window.go_to_url(url)
        new_tab_view.wait_until_destroyed()

    def test_close_last_open_tab(self):
        tabs_view = self.main_window.get_tabs_view()
        preview = tabs_view.get_previews()[0]
        close_button = preview.get_close_button()
        self.pointing_device.click_object(close_button)
        tabs_view.wait_until_destroyed()
        self.assert_number_webviews_eventually(1)
        self.main_window.get_new_tab_view()
        if model() == 'Desktop':
            address_bar = self.main_window.address_bar
            self.assertThat(address_bar.activeFocus, Eventually(Equals(True)))
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.url, Equals(""))

    def test_close_current_tab(self):
        self.open_new_tab()
        new_tab_view = self.main_window.get_new_tab_view()
        url = self.base_url + "/test2"
        self.main_window.go_to_url(url)
        new_tab_view.wait_until_destroyed()
        self.assert_number_webviews_eventually(2)
        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = tabs_view.get_ordered_previews()
        self.assertThat(len(previews), Equals(2))
        preview = previews[0]
        close_button = preview.get_close_button()
        self.pointing_device.click_object(close_button)
        self.assertThat(lambda: len(tabs_view.get_previews()),
                        Eventually(Equals(1)))
        preview = tabs_view.get_previews()[0]
        self.assert_number_webviews_eventually(1)
        webview = self.main_window.get_current_webview()
        self.assertThat(preview.title, Equals(webview.title))

    def test_switch_tabs(self):
        self.check_current_tab(self.url)
        self.open_new_tab()
        self.check_current_tab("")
        new_tab_view = self.main_window.get_new_tab_view()
        url = self.base_url + "/test2"
        self.main_window.go_to_url(url)
        new_tab_view.wait_until_destroyed()
        self.check_current_tab(url)

        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = tabs_view.get_ordered_previews()
        self.pointing_device.click_object(previews[1])
        tabs_view.wait_until_destroyed()
        self.check_current_tab(self.url)

        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = tabs_view.get_ordered_previews()
        self.pointing_device.click_object(previews[1])
        tabs_view.wait_until_destroyed()
        self.check_current_tab(url)

    def test_error_only_for_current_tab(self):
        self.open_new_tab()
        self.main_window.go_to_url('http://invalid')
        error = self.main_window.get_error_sheet()
        self.assertThat(error.visible, Eventually(Equals(True)))

        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = tabs_view.get_ordered_previews()
        self.pointing_device.click_object(previews[1])
        tabs_view.wait_until_destroyed()
        self.assertThat(error.visible, Eventually(Equals(False)))


class TestTabsManagement(StartOpenRemotePageTestCaseBase, TestTabsMixin):

    def test_open_target_blank_in_new_tab(self):
        url = self.base_url + "/blanktargetlink"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        self.check_current_tab(self.base_url + "/test2")
        self.assert_number_webviews_eventually(2)

    def test_open_iframe_target_blank_in_new_tab(self):
        url = self.base_url + "/fulliframewithblanktargetlink"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        webview = self.main_window.get_current_webview()
        self.pointing_device.click_object(webview)
        self.check_current_tab(self.base_url + "/test2")
        self.assert_number_webviews_eventually(2)

    def test_selecting_tab_focuses_webview(self):
        self.main_window.address_bar.focus()
        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = tabs_view.get_previews()
        self.pointing_device.click_object(previews[0])
        tabs_view.wait_until_destroyed()
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.activeFocus, Eventually(Equals(True)))
        address_bar = self.main_window.address_bar
        self.assertThat(address_bar.activeFocus, Eventually(Equals(False)))

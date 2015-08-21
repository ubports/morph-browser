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

import time
from autopilot.platform import model
from autopilot.matchers import Eventually
import testtools
from testtools.matchers import Equals, GreaterThan, StartsWith

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestContextMenuBase(StartOpenRemotePageTestCaseBase):

    def setUp(self, path):
        super(TestContextMenuBase, self).setUp(path)
        self.menu = self.open_context_menu()

    def open_context_menu(self):
        webview = self.main_window.get_current_webview()
        chrome = self.main_window.chrome
        x = webview.globalRect.x + webview.globalRect.width // 2
        y = webview.globalRect.y + \
            (webview.globalRect.height + chrome.height) // 2
        self.pointing_device.move(x, y)
        if model() == 'Desktop':
            self.pointing_device.click(button=3)
        else:
            self.pointing_device.press()
            time.sleep(1.5)
            self.pointing_device.release()
        return self.main_window.get_context_menu()

    def click_action(self, name):
        self.menu.click_action(name)
        self.menu.wait_until_destroyed()

    def verify_link_opened_in_a_new_tab(self):
        self.assert_number_webviews_eventually(2)
        webview = self.main_window.get_current_webview()
        new_url = self.base_url + "/test1"
        self.assertThat(webview.url, Eventually(Equals(new_url)))

    def verify_link_bookmarked(self):
        url = self.base_url + "/test1"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        self.main_window.chrome.bookmarked.wait_for(True)

    def verify_image_opened_in_a_new_tab(self):
        self.assert_number_webviews_eventually(2)
        webview = self.main_window.get_current_webview()
        data_uri_prefix = "data:image/png;base64,"
        self.assertThat(webview.url, Eventually(StartsWith(data_uri_prefix)))


class TestContextMenuLink(TestContextMenuBase):

    def setUp(self):
        super(TestContextMenuLink, self).setUp(path="/link")

    def test_dismiss_menu(self):
        if self.main_window.wide:
            # Verify that clicking outside the menu dismisses it
            webview_rect = self.main_window.get_current_webview().globalRect
            actions = self.menu.get_visible_actions()
            self.assertThat(actions[0].globalRect.x,
                            GreaterThan(webview_rect.x))
            outside_x = (webview_rect.x + actions[0].globalRect.x) // 2
            outside_y = webview_rect.y + webview_rect.height // 2
            self.pointing_device.move(outside_x, outside_y)
            self.pointing_device.click()
        else:
            # Verify that clicking the cancel action dismisses it
            self.menu.click_cancel_action()
        self.menu.wait_until_destroyed()

    def test_open_link_in_new_tab(self):
        self.click_action("openLinkInNewTabContextualAction")
        self.verify_link_opened_in_a_new_tab()

    def test_bookmark_link(self):
        self.click_action("bookmarkLinkContextualAction")
        self.verify_link_bookmarked()

    def test_copy_link(self):
        # There is no easy way to test the contents of the clipboard,
        # but we can at least verify that the context menu was dismissed.
        self.click_action("copyLinkContextualAction")

    @testtools.skipIf(model() == "Desktop", "on devices only")
    def test_share_link(self):
        self.click_action("ShareLinkContextualAction")
        self.main_window.wait_select_single("ContentShareDialog")


class TestContextMenuImage(TestContextMenuBase):

    def setUp(self):
        super(TestContextMenuImage, self).setUp(path="/image")

    def test_open_image_in_new_tab(self):
        self.click_action("OpenImageInNewTabContextualAction")
        self.verify_image_opened_in_a_new_tab()

    def test_copy_image(self):
        # There is no easy way to test the contents of the clipboard,
        # but we can at least verify that the context menu was dismissed.
        self.click_action("CopyImageContextualAction")


class TestContextMenuImageAndLink(TestContextMenuBase):

    def setUp(self):
        super(TestContextMenuImageAndLink, self).setUp(path="/imagelink")

    def test_open_link_in_new_tab(self):
        self.click_action("openLinkInNewTabContextualAction")
        self.verify_link_opened_in_a_new_tab()

    def test_bookmark_link(self):
        self.click_action("bookmarkLinkContextualAction")
        self.verify_link_bookmarked()

    def test_copy_link(self):
        # There is no easy way to test the contents of the clipboard,
        # but we can at least verify that the context menu was dismissed.
        self.click_action("copyLinkContextualAction")

    @testtools.skipIf(model() == "Desktop", "on devices only")
    def test_share_link(self):
        self.click_action("ShareLinkContextualAction")
        self.main_window.wait_select_single("ContentShareDialog")

    def test_open_image_in_new_tab(self):
        self.click_action("OpenImageInNewTabContextualAction")
        self.verify_image_opened_in_a_new_tab()

    def test_copy_image(self):
        # There is no easy way to test the contents of the clipboard,
        # but we can at least verify that the context menu was dismissed.
        self.click_action("CopyImageContextualAction")


class TestContextMenuTextArea(TestContextMenuBase):

    def setUp(self):
        super(TestContextMenuTextArea, self).setUp(path="/textarea")

    def test_actions(self):
        actions = ["SelectAll", "Cut", "Undo", "Redo",
                   "Paste", "SelectAll", "Copy", "Erase"]
        for action in actions:
            self.click_action("{}ContextualAction".format(action))
            self.menu = self.open_context_menu()

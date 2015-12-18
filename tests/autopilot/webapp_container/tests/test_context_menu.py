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
from testtools.matchers import Equals, StartsWith

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase

import ubuntuuitoolkit as uitk


class ContextMenuBase(uitk.UbuntuUIToolkitCustomProxyObjectBase):
    def get_title_label(self):
        return self.select_single(objectName="titleLabel")

    def get_visible_actions(self):
        return self.select_many("Empty", visible=True)

    def get_action(self, objectName):
        name = objectName + "_item"
        return self.select_single("Empty", objectName=name)

    def click_action(self, objectName):
        name = objectName + "_item"
        action = self.select_single("Empty", visible=True,
                                    enabled=True, objectName=name)
        self.pointing_device.click_object(action)
        self.wait_until_destroyed()


class ContextMenuWide(ContextMenuBase):
    pass


class ContextMenuMobile(ContextMenuBase):
    def click_cancel_action(self):
        action = self.select_single("Empty", objectName="cancelAction")
        self.pointing_device.click_object(action)


class TestContextMenuBase(WebappContainerTestCaseWithLocalContentBase):
    data_uri_prefix = "data:image/png;base64,"

    def _get_context_menu(self):
        if self.get_webcontainer_webview().wide:
            return self.app.wait_select_single(
                ContextMenuWide,
                objectName="contextMenuWide")
        else:
            return self.app.wait_select_single(
                ContextMenuMobile,
                objectName="contextMenuMobile")

    def _open_context_menu(self):
        webview = self.get_webview()
        x = webview.globalRect.x + webview.globalRect.width // 2
        y = webview.globalRect.y + webview.globalRect.height // 2
        self.pointing_device.move(x, y)
        if model() == 'Desktop':
            self.pointing_device.click(button=3)
        else:
            self.pointing_device.press()
            time.sleep(1.5)
            self.pointing_device.release()
        return self._get_context_menu()

    def _dismiss_context_menu(self, menu):
        if self.get_webcontainer_webview().wide:
            # Dismiss by clicking outside of the menu
            webview_rect = self.get_webview().globalRect
            actions = menu.get_visible_actions()
            outside_x = (webview_rect.x + actions[0].globalRect.x) // 2
            outside_y = webview_rect.y + webview_rect.height // 2
            self.pointing_device.move(outside_x, outside_y)
            self.pointing_device.click()
        else:
            # Dismiss by clicking the cancel action
            menu.click_cancel_action()
        menu.wait_until_destroyed()

    def setUp(self, path):
        super(TestContextMenuBase, self).setUp()
        args = []
        self.launch_webcontainer_app_with_local_http_server(
            args,
            path,
            {'WEBAPP_CONTAINER_BLOCK_OPEN_URL_EXTERNALLY': '1'})
        self.get_webcontainer_window().visible.wait_for(True)
        self.menu = self._open_context_menu()


class TestContextMenuLink(TestContextMenuBase):

    def setUp(self):
        super(TestContextMenuLink, self).setUp(path="/with-external-link")
        self.assertThat(self.menu.get_title_label().text,
                        Equals("http://www.ubuntu.com/"))

    def test_open_link_(self):
        main_webview = self.get_oxide_webview()
        signal = main_webview.watch_signal(
            'openExternalUrlTriggered(QString)')
        self.assertThat(signal.was_emitted, Equals(False))

        self.menu.click_action("OpenLinkInWebBrowser")

        self.assertThat(lambda: signal.was_emitted, Eventually(Equals(True)))
        self.assertThat(signal.num_emissions, Equals(1))

    def test_copy_link(self):
        self.menu.click_action("CopyLinkContextualAction")


class TestContextMenuImage(TestContextMenuBase):

    def setUp(self):
        super(TestContextMenuImage, self).setUp(path="/image")
        self.assertThat(self.menu.get_title_label().text,
                        StartsWith(self.data_uri_prefix))

    def test_copy_image(self):
        # There is no easy way to test the contents of the clipboard,
        # but we can at least verify that the context menu was dismissed.
        self.menu.click_action("CopyImageContextualAction")


class TestContextMenuImageAndLink(TestContextMenuBase):

    def setUp(self):
        super(TestContextMenuImageAndLink, self).setUp(path="/imagelink")
        self.assertThat(self.menu.get_title_label().text,
                        StartsWith(self.data_uri_prefix))

    def test_open_link_in_webbrowser(self):
        main_webview = self.get_oxide_webview()
        signal = main_webview.watch_signal(
            'openExternalUrlTriggered(QString)')
        self.assertThat(signal.was_emitted, Equals(False))

        self.menu.click_action("OpenLinkInWebBrowser")

        self.assertThat(lambda: signal.was_emitted, Eventually(Equals(True)))
        self.assertThat(signal.num_emissions, Equals(1))

    def test_copy_link(self):
        # There is no easy way to test the contents of the clipboard,
        # but we can at least verify that the context menu was dismissed.
        self.menu.click_action("CopyLinkContextualAction")

    def test_copy_image(self):
        # There is no easy way to test the contents of the clipboard,
        # but we can at least verify that the context menu was dismissed.
        self.menu.click_action("CopyImageContextualAction")


class TestContextMenuTextArea(TestContextMenuBase):

    def setUp(self):
        super(TestContextMenuTextArea, self).setUp(path="/textarea")
        self.assertThat(self.menu.get_title_label().visible, Equals(False))

    def test_actions(self):
        actions = ["SelectAll",
                   "Cut",
                   "Undo",
                   "Redo",
                   "Paste",
                   "SelectAll",
                   "Copy",
                   "Erase"]
        for action in actions:
            self.menu.click_action("{}ContextualAction".format(action))
            self.menu = self._open_context_menu()

# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2015-2016 Canonical
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

    def _open_context_menu(self, webview):
        gr = webview.globalRect
        x = gr.x + webview.width // 2
        y = gr.y + webview.height // 2
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

    def _click_window_open(self):
        webview = self.get_oxide_webview()
        gr = webview.globalRect
        self.pointing_device.move(
            gr.x + webview.width*3/4,
            gr.y + webview.height*3/4)
        self.pointing_device.click()

    def _launch_application(self, path):
        args = []
        self.launch_webcontainer_app_with_local_http_server(
            args,
            path,
            {'WEBAPP_CONTAINER_BLOCK_OPEN_URL_EXTERNALLY': '1'})
        self.get_webcontainer_window().visible.wait_for(True)

    def _setup_overlay_webview_context_menu(self, path):
        overlay_path = "/with-overlay-link?path={}".format(path)
        self._launch_application(overlay_path)

        popup_controller = self.get_popup_controller()
        animation_watcher = popup_controller.watch_signal(
            'windowOverlayOpenAnimationDone()')
        animation_signal_emission = animation_watcher.num_emissions

        self._click_window_open()

        self.assertThat(
            lambda: len(self.get_popup_overlay_views()),
            Eventually(Equals(1)))
        self.assertThat(
            lambda: animation_watcher.num_emissions,
            Eventually(GreaterThan(animation_signal_emission)))

        self.webview = self.get_popup_overlay_views()[0].select_single(
            objectName="overlayWebview")
        self.menu = self._open_context_menu(self.webview)

    def _setup_webview_context_menu(self, path):
        self._launch_application("/{}".format(path))

        self.webview = self.get_oxide_webview()
        self.menu = self._open_context_menu(self.webview)


class TestContextMenuLink(TestContextMenuBase):

    def _test_open_link_(self):
        signal = self.webview.watch_signal(
            'openUrlExternallyRequested(QString)')
        self.assertThat(signal.was_emitted, Equals(False))

        self.menu.click_action("OpenLinkInBrowser")

        self.assertThat(lambda: signal.was_emitted, Eventually(Equals(True)))
        self.assertThat(signal.num_emissions, Equals(1))

    def _test_copy_link(self):
        self.menu.click_action("CopyLinkContextualAction")

    @testtools.skipIf(model() == "Desktop", "on devices only")
    def _test_share_link(self):
        self.menu.click_action("ShareContextualAction")
        self.app.wait_select_single("ContentShareDialog")


class TestContextMenuLinkOverlayWebView(TestContextMenuLink):

    def setUp(self):
        super(TestContextMenuLinkOverlayWebView, self).setUp()
        self._setup_overlay_webview_context_menu("with-external-link")

    def test_open_link_(self):
        self._test_open_link_()

    def test_copy_link(self):
        self._test_copy_link()

    @testtools.skipIf(model() == "Desktop", "on devices only")
    def test_share_link(self):
        self._test_share_link()


class TestContextMenuLinkMainWebView(TestContextMenuLink):

    def setUp(self):
        super(TestContextMenuLinkMainWebView, self).setUp()
        self._setup_webview_context_menu("with-external-link")

    def test_open_link_(self):
        self._test_open_link_()

    def test_copy_link(self):
        self._test_copy_link()

    @testtools.skipIf(model() == "Desktop", "on devices only")
    def test_share_link(self):
        self._test_share_link()


class TestContextMenuImage(TestContextMenuBase):

    def _test_copy_image(self):
        # There is no easy way to test the contents of the clipboard,
        # but we can at least verify that the context menu was dismissed.
        self.menu.click_action("CopyImageContextualAction")


class TestContextMenuImageMainWebview(TestContextMenuImage):

    def setUp(self):
        super(TestContextMenuImageMainWebview, self).setUp()
        self._setup_webview_context_menu("image")
        self.assertThat(self.menu.get_title_label().text,
                        StartsWith(self.data_uri_prefix))

    def test_copy_image(self):
        self._test_copy_image()


class TestContextMenuImageOverlayWebView(TestContextMenuImage):

    def setUp(self):
        super(TestContextMenuImageOverlayWebView, self).setUp()
        self._setup_overlay_webview_context_menu("image")
        self.assertThat(self.menu.get_title_label().text,
                        StartsWith(self.data_uri_prefix))

    def test_copy_image(self):
        self._test_copy_image()


class TestContextMenuImageAndLink(TestContextMenuBase):

    def _test_open_link_in_webbrowser(self):
        signal = self.webview.watch_signal(
            'openUrlExternallyRequested(QString)')
        self.assertThat(signal.was_emitted, Equals(False))

        self.menu.click_action("OpenLinkInBrowser")

        self.assertThat(lambda: signal.was_emitted, Eventually(Equals(True)))
        self.assertThat(signal.num_emissions, Equals(1))

    def _test_share_link(self):
        self.menu.click_action("ShareContextualAction")
        self.app.wait_select_single("ContentShareDialog")

    def _test_copy_link(self):
        # There is no easy way to test the contents of the clipboard,
        # but we can at least verify that the context menu was dismissed.
        self.menu.click_action("CopyLinkContextualAction")

    def _test_copy_image(self):
        # There is no easy way to test the contents of the clipboard,
        # but we can at least verify that the context menu was dismissed.
        self.menu.click_action("CopyImageContextualAction")


class TestContextMenuImageAndLinkMainWebView(TestContextMenuImageAndLink):

    def setUp(self):
        super(TestContextMenuImageAndLinkMainWebView, self).setUp()
        self._setup_webview_context_menu("imagelink")
        self.assertThat(self.menu.get_title_label().text,
                        StartsWith(self.data_uri_prefix))

    def test_open_link_in_webbrowser(self):
        self._test_open_link_in_webbrowser()

    @testtools.skipIf(model() == "Desktop", "on devices only")
    def test_share_link(self):
        self._test_share_link()

    def test_copy_link(self):
        self._test_copy_link()

    def test_copy_image(self):
        self._test_copy_image()


class TestContextMenuImageAndLinkOverlayWebView(TestContextMenuImageAndLink):

    def setUp(self):
        super(TestContextMenuImageAndLinkOverlayWebView, self).setUp()
        self._setup_overlay_webview_context_menu("imagelink")
        self.assertThat(self.menu.get_title_label().text,
                        StartsWith(self.data_uri_prefix))

    def test_open_link_in_webbrowser(self):
        self._test_open_link_in_webbrowser()

    @testtools.skipIf(model() == "Desktop", "on devices only")
    def test_share_link(self):
        self._test_share_link()

    def test_copy_link(self):
        self._test_copy_link()

    def test_copy_image(self):
        self._test_copy_image()


class TestContextMenuTextArea(TestContextMenuBase):

    def _test_actions(self):
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
            webview = self.get_webview()
            self.menu = self._open_context_menu(webview)


@testtools.skipIf(model() != "Desktop", "on desktop only")
class TestContextMenuTextAreaMainWebView(TestContextMenuTextArea):

    def setUp(self):
        super(TestContextMenuTextAreaMainWebView, self).setUp()
        self._setup_webview_context_menu("textarea")
        self.assertThat(self.menu.get_title_label().visible, Equals(False))

    def test_actions(self):
        self._test_actions()


@testtools.skipIf(model() != "Desktop", "on desktop only")
class TestContextMenuTextAreaOverlayWebView(TestContextMenuTextArea):

    def setUp(self):
        super(TestContextMenuTextAreaOverlayWebView, self).setUp()
        self._setup_overlay_webview_context_menu("textarea")
        self.assertThat(self.menu.get_title_label().visible, Equals(False))

    def test_actions(self):
        self._test_actions()

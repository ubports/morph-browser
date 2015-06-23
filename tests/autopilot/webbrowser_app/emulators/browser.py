# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2013-2015 Canonical
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

import logging

import autopilot.logging
import ubuntuuitoolkit as uitk
from autopilot import exceptions
from autopilot import input

logger = logging.getLogger(__name__)


class Browser(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def __init__(self, *args):
        super().__init__(*args)
        self.chrome = self._get_chrome()
        self.address_bar = self.chrome.address_bar
        self.keyboard = input.Keyboard.create()

    def _get_chrome(self):
        return self.select_single(Chrome)

    def go_to_url(self, url):
        self.address_bar.go_to_url(url)

    def wait_until_page_loaded(self, url):
        webview = self.get_current_webview()
        webview.url.wait_for(url)
        # loadProgress == 100 ensures that a page has actually loaded
        webview.loadProgress.wait_for(100, timeout=20)
        webview.loading.wait_for(False)

    def go_back(self):
        self.chrome.go_back()

    def go_forward(self):
        self.chrome.go_forward()

    @autopilot.logging.log_action(logger.info)
    def enter_private_mode(self):
        if not self.is_in_private_mode():
            self.chrome.toggle_private_mode()
        else:
            logger.warning('The browser is already in private mode.')

    def is_in_private_mode(self):
        return self.get_current_webview().incognito

    @autopilot.logging.log_action(logger.info)
    def leave_private_mode(self):
        if self.is_in_private_mode():
            self.chrome.toggle_private_mode()
        else:
            logger.warning('The browser is not in private mode.')

    @autopilot.logging.log_action(logger.info)
    def leave_private_mode_with_confirmation(self, confirm=True):
        if self.is_in_private_mode():
            self.chrome.toggle_private_mode()
            dialog = self._get_leave_private_mode_dialog()
            if confirm:
                dialog.confirm()
            else:
                dialog.cancel()
            dialog.wait_until_destroyed()
        else:
            logger.warning('The browser is not in private mode.')

    def _get_leave_private_mode_dialog(self):
        return self.wait_select_single(LeavePrivateModeDialog, visible=True)

    # Since the NewPrivateTabView does not define any new QML property in its
    # extended file, it does not report itself to autopilot with the same name
    # as the extended file. (See http://pad.lv/1454394)
    def is_new_private_tab_view_visible(self):
        try:
            self.get_new_private_tab_view()
            return True
        except exceptions.StateNotFoundError:
            return False

    def get_window(self):
        return self.get_parent()

    def get_current_webview(self):
        return self.select_single("WebViewImpl", visible=True)

    def get_webviews(self):
        return self.select_many("WebViewImpl", incognito=False)

    def get_incognito_webviews(self):
        return self.select_many("WebViewImpl", incognito=True)

    def get_error_sheet(self):
        return self.select_single("ErrorSheet")

    def get_suggestions(self):
        return self.select_single(Suggestions)

    def get_geolocation_dialog(self):
        return self.wait_select_single(GeolocationPermissionRequest)

    def get_selection(self):
        return self.wait_select_single(Selection)

    def get_selection_actions(self):
        return self.wait_select_single("ActionSelectionPopover",
                                       objectName="selectionActions")

    def get_tabs_view(self):
        return self.wait_select_single(TabsList, visible=True)

    def get_recent_view_toolbar(self):
        return self.wait_select_single(Toolbar, objectName="recentToolbar",
                                       state="shown")

    def get_new_tab_view(self):
        return self.wait_select_single("NewTabView", visible=True)

    # Since the NewPrivateTabView does not define any new QML property in its
    # extended file, it does not report itself to autopilot with the same name
    # as the extended file. (See http://pad.lv/1454394)
    def get_new_private_tab_view(self):
        return self.wait_select_single("QQuickItem",
                                       objectName="newPrivateTabView",
                                       visible=True)

    def get_settings_page(self):
        return self.wait_select_single(SettingsPage, visible=True)

    def get_content_picker_dialog(self):
        # only on devices
        return self.wait_select_single("PopupBase",
                                       objectName="contentPickerDialog")

    def get_bottom_edge_hint(self):
        return self.select_single("QQuickImage", objectName="bottomEdgeHint")

    def get_bookmark_options(self):
        return self.select_single(BookmarkOptions)

    # The history view is dynamically created, so it might or might not be
    # available
    def get_history_view(self):
        try:
            return self.select_single("HistoryView")
        except exceptions.StateNotFoundError:
            return None

    def get_bookmarks_folder_list_view(self):
        return self.select_single(BookmarksFolderListView)

    def press_key(self, key):
        self.keyboard.press_and_release(key)


class Chrome(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def __init__(self, *args):
        super().__init__(*args)
        self.address_bar = self._get_address_bar()

    def _get_address_bar(self):
        return self.select_single(AddressBar)

    @autopilot.logging.log_action(logger.info)
    def go_back(self):
        back_button = self._get_back_button()
        back_button.enabled.wait_for(True)
        self.pointing_device.click_object(back_button)

    def _get_back_button(self):
        return self.select_single("ChromeButton", objectName="backButton")

    def is_back_button_enabled(self):
        back_button = self._get_back_button()
        return back_button.enabled

    @autopilot.logging.log_action(logger.info)
    def go_forward(self):
        forward_button = self._get_forward_button()
        forward_button.enabled.wait_for(True)
        self.pointing_device.click_object(forward_button)

    def _get_forward_button(self):
        return self.select_single("ChromeButton", objectName="forwardButton")

    def is_forward_button_enabled(self):
        forward_button = self._get_forward_button()
        return forward_button.enabled

    def toggle_private_mode(self):
        drawer_button = self.get_drawer_button()
        self.pointing_device.click_object(drawer_button)
        self.get_drawer()
        private_mode_action = self.get_drawer_action("privatemode")
        self.pointing_device.click_object(private_mode_action)

    def get_drawer_button(self):
        return self.select_single("ChromeButton", objectName="drawerButton")

    def get_drawer(self):
        return self.wait_select_single("QQuickItem", objectName="drawer",
                                       clip=False)

    def get_drawer_action(self, actionName):
        drawer = self.get_drawer()
        return drawer.select_single("AbstractButton", objectName=actionName,
                                    visible=True)


class AddressBar(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def __init__(self, *args):
        super().__init__(*args)
        self.text_field = self.select_single(
            uitk.TextField, objectName='addressBarTextField')

    @autopilot.logging.log_action(logger.debug)
    def focus(self):
        self.pointing_device.click_object(self)
        self.activeFocus.wait_for(True)

    def clear(self):
        self.text_field.clear()

    @autopilot.logging.log_action(logger.info)
    def go_to_url(self, url):
        self.write(url)
        self.press_key('Enter')

    def write(self, text, clear=True):
        self.text_field.write(text, clear)

    def press_key(self, key):
        self.text_field.keyboard.press_and_release(key)

    @autopilot.logging.log_action(logger.info)
    def click_action_button(self):
        button = self.select_single("QQuickMouseArea",
                                    objectName="actionButton")
        self.pointing_device.click_object(button)

    def get_bookmark_toggle(self):
        return self.select_single("QQuickItem", objectName="bookmarkToggle")


class Suggestions(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_ordered_entries(self):
        return sorted(self.select_many("Suggestion"),
                      key=lambda item: item.globalRect.y)


class GeolocationPermissionRequest(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_deny_button(self):
        return self.select_single("Button", objectName="deny")

    def get_allow_button(self):
        return self.select_single("Button", objectName="allow")


class Selection(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_rectangle(self):
        return self.select_single("QQuickItem", objectName="rectangle")

    def get_handle(self, name):
        return self.select_single("SelectionHandle", objectName=name)


class TabPreview(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    @autopilot.logging.log_action(logger.info)
    def select(self):
        area = self.select_single("QQuickMouseArea", objectName="selectArea")
        # click towards the top of the area to ensure we’re not selecting
        # the following preview that might be overlapping
        ca = area.globalRect
        self.pointing_device.move(ca.x + ca.width // 2, ca.y + ca.height // 4)
        self.pointing_device.click()

    @autopilot.logging.log_action(logger.info)
    def close(self):
        button = self.select_single("AbstractButton", objectName="closeButton")
        self.pointing_device.click_object(button)


class TabsList(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_previews(self):
        previews = self.select_many(TabPreview)
        previews.sort(key=lambda tab: tab.globalRect.y)
        return previews


class Toolbar(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    @autopilot.logging.log_action(logger.info)
    def click_button(self, name):
        self.isFullyShown.wait_for(True)
        button = self.select_single("Button", objectName=name)
        self.pointing_device.click_object(button)

    @autopilot.logging.log_action(logger.info)
    def click_action(self, name):
        self.isFullyShown.wait_for(True)
        action = self.select_single("ToolbarAction", objectName=name)
        self.pointing_device.click_object(action)


class SettingsPage(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_header(self):
        return self.select_single(SettingsPageHeader)

    def get_searchengine_entry(self):
        return self.select_single("Subtitled", objectName="searchengine")

    def get_searchengine_page(self):
        return self.wait_select_single("QQuickItem",
                                       objectName="searchEnginePage")

    def get_homepage_entry(self):
        return self.select_single("Subtitled", objectName="homepage")

    def get_restore_session_entry(self):
        return self.select_single("Standard", objectName="restoreSession")

    def get_background_tabs_entry(self):
        return self.select_single("Standard", objectName="backgroundTabs")

    def get_privacy_entry(self):
        return self.select_single("Standard", objectName="privacy")

    def get_privacy_page(self):
        return self.wait_select_single("QQuickItem",
                                       objectName="privacySettings")

    def get_reset_settings_entry(self):
        return self.select_single("Standard", objectName="reset")


class SettingsPageHeader(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    @autopilot.logging.log_action(logger.info)
    def click_back_button(self):
        button = self.select_single("AbstractButton", objectName="backButton")
        self.pointing_device.click_object(button)


class LeavePrivateModeDialog(uitk.Dialog):

    @autopilot.logging.log_action(logger.info)
    def confirm(self):
        confirm_button = self.select_single(
            "Button", objectName="leavePrivateModeDialog.okButton")
        self.pointing_device.click_object(confirm_button)

    @autopilot.logging.log_action(logger.info)
    def cancel(self):
        cancel_button = self.select_single(
            "Button", objectName="leavePrivateModeDialog.cancelButton")
        self.pointing_device.click_object(cancel_button)


class NewTabView(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_bookmarks_more_button(self):
        return self.select_single("Button", objectName="bookmarks.moreButton")

    def get_homepage_bookmark(self):
        return self.select_single(UrlDelegate, objectName="homepageBookmark")

    def get_bookmarks_list(self):
        return self.select_single(UrlsList, objectName="bookmarksList")

    def get_top_sites_list(self):
        return self.select_single(UrlsList, objectName="topSitesList")

    def get_notopsites_label(self):
        return self.select_single("Label", objectName="notopsites")


class UrlsList(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_delegates(self):
        return sorted(self.select_many(UrlDelegate),
                      key=lambda delegate: delegate.globalRect.y)

    def get_urls(self):
        return [delegate.url for delegate in self.get_delegates()]


class UrlDelegate(uitk.UCListItem):

    pass


class BookmarkOptions(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_dismiss_button(self):
        return self.select_single("Button",
                                  objectName="bookmarkOptions.okButton")


class BookmarksFolderListView(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_delegates(self):
        return sorted(self.select_many(BookmarksFolderDelegate),
                      key=lambda delegate: delegate.globalRect.y)

    def get_folder_delegate(self, folder):
        return self.select_single(BookmarksFolderDelegate,
                                  objectName="bookmarkFolderDelegate_" +
                                  folder)


class BookmarksFolderDelegate(uitk.UCListItem):

    def get_delegate_header(self):
        return self.wait_select_single("QQuickItem",
                                       objectName="bookmarkFolderHeader")

    def get_url_delegates(self):
        return sorted(self.select_many(UrlDelegate),
                      key=lambda delegate: delegate.globalRect.y)

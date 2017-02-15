# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2013-2017 Canonical
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
import time

import autopilot.logging
import ubuntuuitoolkit as uitk
from autopilot import exceptions
from autopilot import input
from autopilot.platform import model

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
        webview = self.wait_select_single("WebViewImpl", current=True, url=url)
        # loadProgress == 100 ensures that a page has actually loaded
        webview.loadProgress.wait_for(100, timeout=20)
        webview.loading.wait_for(False)

    def go_back(self):
        self.chrome.go_back()

    def go_forward(self):
        self.chrome.go_forward()

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
        return self.select_single("WebViewImpl", current=True)

    def get_webviews(self):
        return self.select_many("WebViewImpl", incognito=False)

    def get_incognito_webviews(self):
        return self.select_many("WebViewImpl", incognito=True)

    def get_error_sheet(self):
        return self.select_single("ErrorSheet")

    def get_sad_tab(self):
        return self.wait_select_single(SadTab)

    def get_suggestions(self):
        return self.select_single(Suggestions)

    def get_geolocation_dialog(self):
        return self.wait_select_single(GeolocationPermissionRequest)

    def get_http_auth_dialog(self):
        return self.wait_select_single(HttpAuthenticationDialog)

    def get_media_access_dialog(self):
        return self.wait_select_single(MediaAccessDialog)

    def get_tabs_view(self):
        return self.wait_select_single(TabsList, visible=True)

    def get_recent_view_toolbar(self):
        return self.wait_select_single(Toolbar, objectName="recentToolbar",
                                       state="shown")

    def get_new_tab_view(self):
        if self.wide:
            return self.wait_select_single("NewTabViewWide", visible=True)
        else:
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

    def get_downloads_page(self):
        return self.wait_select_single(DownloadsPage, visible=True)

    def get_content_picker_dialog(self):
        # only on devices
        return self.wait_select_single("PopupBase",
                                       objectName="contentPickerDialog")

    def get_download_dialog(self):
        return self.wait_select_single("PopupBase",
                                       objectName="downloadDialog")

    def get_peer_picker(self):
        return self.wait_select_single(objectName="contentPeerPicker")

    def get_download_options_dialog(self):
        return self.wait_select_single("Dialog",
                                       objectName="downloadOptionsDialog")

    def click_cancel_download_button(self):
        button = self.select_single("Button",
                                    objectName="cancelDownloadButton")
        self.pointing_device.click_object(button)

    def click_choose_app_button(self):
        button = self.select_single("Button",
                                    objectName="chooseAppButton")
        self.pointing_device.click_object(button)

    def click_download_file_button(self):
        button = self.select_single("Button",
                                    objectName="downloadFileButton")
        self.pointing_device.click_object(button)

    def get_bottom_edge_handle(self):
        return self.select_single(objectName="bottomEdgeHandle")

    def get_bottom_edge_bar(self):
        return self.select_single(objectName="bottomEdgeBar", visible=True)

    def get_bookmark_options(self):
        return self.select_single(BookmarkOptions)

    def get_new_bookmarks_folder_dialog(self):
        return self.wait_select_single("Dialog",
                                       objectName="newFolderDialog")

    # The bookmarks view is dynamically created, so it might or might not be
    # available
    def get_bookmarks_view(self):
        try:
            if self.wide:
                return self.select_single("BookmarksViewWide")
            else:
                return self.select_single("BookmarksView")
        except exceptions.StateNotFoundError:
            return None

    # The history view is dynamically created, so it might or might not be
    # available
    def get_history_view(self):
        try:
            if self.wide:
                return self.wait_select_single(HistoryViewWide)
            else:
                return self.wait_select_single(HistoryView)
        except exceptions.StateNotFoundError:
            return None

    def get_expanded_history_view(self):
        return self.wait_select_single(ExpandedHistoryView, visible=True)

    def press_key(self, key):
        self.keyboard.press_and_release(key)

    def get_context_menu(self):
        if self.wide:
            return self.wait_select_single(ContextMenuWide)
        else:
            return self.wait_select_single(ContextMenuMobile)

    def open_item_context_menu_on_item(self, item, menuClass):
        cx = item.globalRect.x + item.globalRect.width // 2
        cy = item.globalRect.y + item.globalRect.height // 2
        self.pointing_device.move(cx, cy)
        if model() == 'Desktop':
            self.pointing_device.click(button=3)
        else:
            self.pointing_device.press()
            time.sleep(1.5)
            self.pointing_device.release()
        return self.wait_select_single(menuClass)

    def open_context_menu(self):
        webview = self.get_current_webview()
        chrome = self.chrome
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
        return self.get_context_menu()

    def dismiss_context_menu(self, menu):
        if self.wide:
            # Dismiss by clicking outside of the menu
            webview_rect = self.get_current_webview().globalRect
            actions = menu.get_visible_actions()
            outside_x = (webview_rect.x + actions[0].globalRect.x) // 2
            outside_y = webview_rect.y + webview_rect.height // 2
            self.pointing_device.move(outside_x, outside_y)
            self.pointing_device.click()
        else:
            # Dismiss by clicking the cancel action
            menu.click_cancel_action()
        menu.wait_until_destroyed()

    def get_alert_dialog(self):
        return AlertDialog(
            self.wait_select_single("Dialog", objectName="alertDialog")
        )

    def get_before_unload_dialog(self):
        return BeforeUnloadDialog(
            self.wait_select_single("Dialog", objectName="beforeUnloadDialog")
        )

    def get_confirm_dialog(self):
        return ConfirmDialog(
            self.wait_select_single("Dialog", objectName="confirmDialog")
        )

    def get_prompt_dialog(self):
        return PromptDialog(
            self.wait_select_single("Dialog", objectName="promptDialog")
        )


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

    def get_drawer_button(self):
        return self.select_single("ChromeButton", objectName="drawerButton")

    def get_drawer(self):
        return self.wait_select_single("QQuickItem", objectName="drawer",
                                       clip=False)

    def get_drawer_action(self, actionName):
        drawer = self.get_drawer()
        return drawer.select_single(objectName=actionName, visible=True)

    def get_tabs_bar(self):
        return self.select_single(TabsBar)

    def get_find_next_button(self):
        return self.select_single("ChromeButton",
                                  objectName="findNextButton")

    def get_find_prev_button(self):
        return self.select_single("ChromeButton",
                                  objectName="findPreviousButton")

    def get_progress_bar(self):
        return self.select_single("ProgressBar",
                                  objectName="chromeProgressBar")


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
        return self.select_single("QQuickMouseArea",
                                  objectName="bookmarkToggle")

    def get_find_in_page_counter(self):
        return self.select_single(objectName="findInPageCounter")


class TabsBar(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    @autopilot.logging.log_action(logger.info)
    def click_new_tab_button(self):
        button = self.select_single(objectName="newTabButton")
        self.pointing_device.click_object(button)

    def get_tabs(self):
        return self.select_many("QQuickMouseArea", objectName="tabDelegate")

    def get_tab(self, index):
        return self.select_single("QQuickMouseArea", objectName="tabDelegate",
                                  tabIndex=index)

    @autopilot.logging.log_action(logger.info)
    def select_tab(self, index):
        self.pointing_device.click_object(self.get_tab(index))

    @autopilot.logging.log_action(logger.info)
    def close_tab(self, index):
        tab = self.get_tab(index)
        close_button = tab.select_single(objectName="tabCloseButton")
        self.pointing_device.click_object(close_button)


class Suggestions(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_ordered_entries(self):
        return sorted(self.select_many("Suggestion"),
                      key=lambda item: item.globalRect.y)


class SadTab(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    @autopilot.logging.log_action(logger.info)
    def click_close_tab_button(self):
        button = self.select_single("Button", objectName="closeTabButton")
        self.pointing_device.click_object(button)

    @autopilot.logging.log_action(logger.info)
    def click_reload_button(self):
        button = self.select_single("Button", objectName="reloadButton")
        self.pointing_device.click_object(button)


class GeolocationPermissionRequest(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_deny_button(self):
        return self.select_single("Button", objectName="deny")

    def get_allow_button(self):
        return self.select_single("Button", objectName="allow")


class HttpAuthenticationDialog(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_deny_button(self):
        return self.select_single("Button", objectName="deny")

    def get_allow_button(self):
        return self.select_single("Button", objectName="allow")

    def get_username_field(self):
        return self.select_single("TextField", objectName="username")

    def get_password_field(self):
        return self.select_single("TextField", objectName="password")


class MediaAccessDialog(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    @autopilot.logging.log_action(logger.info)
    def click_deny_button(self):
        button = self.select_single("Button",
                                    objectName="mediaAccessDialog.denyButton")
        self.pointing_device.click_object(button)

    @autopilot.logging.log_action(logger.info)
    def click_allow_button(self):
        button = self.select_single("Button",
                                    objectName="mediaAccessDialog.allowButton")
        self.pointing_device.click_object(button)


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
        button = self.select_single(objectName="closeButton")
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


class PageHeader(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    @autopilot.logging.log_action(logger.info)
    def click_back_button(self):
        button = self.select_single(objectName="back_button")
        self.pointing_device.click_object(button)


class BrowserPage(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_header(self):
        return self.select_single(PageHeader)


class SettingsPage(BrowserPage):

    def get_searchengine_entry(self):
        return self.select_single(objectName="searchengine")

    def get_searchengine_page(self):
        return self.wait_select_single(objectName="searchEnginePage")

    def get_homepage_entry(self):
        return self.select_single(objectName="homepage")

    def get_restore_session_entry(self):
        return self.select_single(objectName="restoreSession")

    def get_privacy_entry(self):
        return self.select_single(objectName="privacy")

    def get_privacy_page(self):
        return self.wait_select_single(objectName="privacySettings")

    def get_reset_settings_entry(self):
        return self.select_single(objectName="reset")


class DownloadsPage(BrowserPage):

    def get_download_entries(self):
        return sorted(self.select_many("DownloadDelegate"),
                      key=lambda item: item.globalRect.y)


class HistoryView(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_domain_entries(self):
        return sorted(self.select_many("UrlDelegate"),
                      key=lambda item: item.globalRect.y)


class HistoryViewWide(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_entries(self):
        return sorted(self.select_many("UrlDelegate"),
                      key=lambda item: item.globalRect.y)

    def get_search_field(self):
        return self.select_single(objectName="searchQuery")


class ExpandedHistoryView(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_header(self):
        return self.select_single(objectName="header")

    def get_entries(self):
        return sorted(self.select_many("UrlDelegate",
                                       objectName="entriesDelegate"),
                      key=lambda item: item.globalRect.y)


class NewTabView(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_bookmarks_more_button(self):
        return self.select_single("Button", objectName="bookmarks.moreButton")

    def get_homepage_bookmark(self):
        return self.select_single(UrlDelegate, objectName="homepageBookmark")

    def get_bookmarks_list(self):
        return self.select_single(objectName="bookmarksList")

    def get_bookmark_delegates(self):
        list = self.get_bookmarks_list()
        return sorted(list.select_many(UrlDelegate),
                      key=lambda delegate: delegate.globalRect.y)

    def get_top_sites_list(self):
        return self.select_single(UrlPreviewGrid, objectName="topSitesList")

    def get_notopsites_label(self):
        return self.select_single(objectName="notopsites")

    def get_top_site_items(self):
        return self.get_top_sites_list().get_delegates()

    def get_bookmarks_folder_list_view(self):
        return self.wait_select_single(BookmarksFoldersView)

    def get_bookmarks(self, folder_name):
        # assumes that the "more" button has been clicked
        folders = self.get_bookmarks_folder_list_view()
        folder_delegate = folders.get_folder_delegate(folder_name)
        return folders.get_urls_from_folder(folder_delegate)

    def get_folder_names(self):
        folders = self.get_bookmarks_folder_list_view().get_delegates()
        return [folder.folderName for folder in folders]


class NewTabViewWide(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def go_to_section(self, section_index):
        sections = self.select_single(uitk.Sections)
        if not sections.selectedIndex == section_index:
            sections.click_section_button(section_index)

    def get_bookmarks_list(self):
        self.go_to_section(1)
        list = self.select_single(uitk.QQuickListView,
                                  objectName="bookmarksList")
        return sorted(list.select_many("DraggableUrlDelegateWide",
                      objectName="bookmarkItem"),
                      key=lambda delegate: delegate.globalRect.y)

    def get_top_sites_list(self):
        self.go_to_section(0)
        return self.select_single(UrlPreviewGrid, objectName="topSitesList")

    def get_folders_list(self):
        self.go_to_section(1)
        list = self.select_single(uitk.QQuickListView,
                                  objectName="foldersList")
        return sorted(list.select_many(objectName="folderItem"),
                      key=lambda delegate: delegate.globalRect.y)

    def get_top_site_items(self):
        return self.get_top_sites_list().get_delegates()

    def get_bookmarks(self, folder_name):
        folders = self.get_folders_list()
        matches = [folder for folder in folders if folder.name == folder_name]
        if not len(matches) == 1:
            return []
        self.pointing_device.click_object(matches[0])
        return self.get_bookmarks_list()

    def get_folder_names(self):
        return [folder.name for folder in self.get_folders_list()]


class UrlPreviewGrid(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_delegates(self):
        return sorted(self.select_many("UrlPreviewDelegate"),
                      key=lambda delegate: delegate.globalRect.y)

    def get_urls(self):
        return [delegate.url for delegate in self.get_delegates()]


class UrlDelegate(uitk.UCListItem):

    pass


class UrlDelegateWide(uitk.UCListItem):

    pass


class UrlPreviewDelegate(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def hide_from_history(self, root):
        menu = root.open_item_context_menu_on_item(self,
                                                   "ActionSelectionPopover")

        # Note: we can't still use the click_action_button method of
        # ActionSelectionPopover's CPO, because it will crash if we delete the
        # menu as a reaction to the click (which is the case here).
        # However at least we can select the action button by objectName now.
        # See bug http://pad.lv/1504189
        delete_item = menu.wait_select_single(objectName="delete_button")
        self.pointing_device.click_object(delete_item)
        menu.wait_until_destroyed()


class DraggableUrlDelegateWide(UrlDelegateWide):

    def get_grip(self):
        return self.select_single("Icon", objectName="dragGrip")


class BookmarkOptions(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_title_text_field(self):
        return self.select_single(uitk.TextField, objectName="titleTextField")

    def get_save_in_option_selector(self):
        return self.select_single("OptionSelector", currentlyExpanded=False)

    @autopilot.logging.log_action(logger.info)
    def click_new_folder_button(self):
        button = self.select_single("Button",
                                    objectName="bookmarkOptions.newButton")
        self.pointing_device.click_object(button)

    @autopilot.logging.log_action(logger.info)
    def click_dismiss_button(self):
        button = self.select_single("Button",
                                    objectName="bookmarkOptions.okButton")
        self.pointing_device.click_object(button)


class BookmarksFoldersView(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_delegates(self):
        return sorted(self.select_many(objectName="bookmarkFolderDelegate"),
                      key=lambda delegate: delegate.globalRect.y)

    def get_folder_delegate(self, folder):
        return self.select_single(objectName="bookmarkFolderDelegate",
                                  folderName=folder)

    def get_urls_from_folder(self, folder):
        return sorted(folder.select_many(UrlDelegate),
                      key=lambda delegate: delegate.globalRect.y)

    def get_header_from_folder(self, folder):
        return folder.wait_select_single(objectName="bookmarkFolderHeader")


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


class DialogWrapper(object):
    def __init__(self, dialog):
        self.dialog = dialog

        self.text = self.dialog.text
        self.wait_until_destroyed = self.dialog.wait_until_destroyed
        self.visible = self.dialog.visible


class AlertDialog(DialogWrapper):
    def get_ok_button(self):
        return self.dialog.select_single("Button", objectName="okButton")


class BeforeUnloadDialog(DialogWrapper):
    def get_leave_button(self):
        return self.dialog.select_single("Button", objectName="leaveButton")

    def get_stay_button(self):
        return self.dialog.select_single("Button", objectName="stayButton")


class ConfirmDialog(DialogWrapper):
    def get_cancel_button(self):
        return self.dialog.select_single("Button", objectName="cancelButton")

    def get_ok_button(self):
        return self.dialog.select_single("Button", objectName="okButton")


class PromptDialog(DialogWrapper):
    def get_cancel_button(self):
        return self.dialog.select_single("Button", objectName="cancelButton")

    def get_input_textfield(self):
        return self.dialog.select_single("TextField",
                                         objectName="inputTextField")

    def get_ok_button(self):
        return self.dialog.select_single("Button", objectName="okButton")

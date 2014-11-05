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

import ubuntuuitoolkit as uitk


class AddressBar(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_text_field(self):
        return self.select_single("TextField")

    def get_clear_button(self):
        return self.select_single("AbstractButton")

    def get_action_button(self):
        return self.select_single("QQuickMouseArea", objectName="actionButton")

    def get_bookmark_toggle(self):
        return self.select_single("QQuickItem", objectName="bookmarkToggle")


class Chrome(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_address_bar(self):
        return self.select_single(AddressBar)

    def get_back_button(self):
        return self.select_single("ChromeButton", objectName="backButton")

    def get_forward_button(self):
        return self.select_single("ChromeButton", objectName="forwardButton")

    def get_drawer_button(self):
        return self.select_single("ChromeButton", objectName="drawerButton")

    def get_drawer(self):
        return self.wait_select_single("QQuickItem", objectName="drawer",
                                       clip=False)

    def get_drawer_action(self, actionName):
        drawer = self.get_drawer()
        return drawer.select_single("AbstractButton", objectName=actionName)


class Suggestions(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_list(self):
        return self.select_single("QQuickListView")

    def get_entries(self):
        return self.get_list().select_many("Base")


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

    def get_close_button(self):
        return self.select_single("AbstractButton", objectName="closeButton")


class TabsView(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_previews(self):
        return self.select_many(TabPreview)

    def get_ordered_previews(self):
        previews = self.get_previews()
        previews.sort(key=lambda tab: tab.y)
        return previews

    def get_done_button(self):
        return self.select_single("Button", objectName="doneButton")

    def get_add_button(self):
        return self.select_single("ToolbarAction", objectName="addTabButton")


class Browser(uitk.UbuntuUIToolkitCustomProxyObjectBase):

    def get_window(self):
        return self.get_parent()

    def get_keyboard_rectangle(self):
        return self.select_single("KeyboardRectangle")

    def get_chrome(self):
        return self.select_single(Chrome)

    def get_current_webview(self):
        return self.select_single("WebViewImpl", current=True)

    def get_webviews(self):
        return self.select_many("WebViewImpl")

    def get_visible_webviews(self):
        return self.select_many("WebViewImpl", visible=True)

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
        return self.wait_select_single(TabsView)

    def get_new_tab_view(self):
        return self.wait_select_single("NewTabView", visible=True)

    def get_content_picker_dialog(self):
        # only on devices
        return self.wait_select_single("PopupBase",
                                       objectName="contentPickerDialog")

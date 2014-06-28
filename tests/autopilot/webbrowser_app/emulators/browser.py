# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2013 Canonical
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

from ubuntuuitoolkit import emulators as uitk


class Panel(uitk.Toolbar):
    pass


class Browser(uitk.MainView):

    """
    An emulator class that makes it easy to interact with the webbrowser app.
    """

    def get_window(self):
        return self.get_parent()

    def get_toolbar(self):
        # Overridden since the browser doesn’t use the MainView’s Toolbar.
        return self.select_single(Panel)

    def get_keyboard_rectangle(self):
        return self.select_single("KeyboardRectangle")

    def get_chrome(self):
        return self.select_single("Chrome")

    def get_address_bar(self):
        """Get the browsers address bar"""
        return self.select_single("AddressBar", objectName="addressBar")

    def get_address_bar_clear_button(self):
        textfield = self.get_address_bar_text_field()
        return textfield.select_single("AbstractButton")

    def get_address_bar_action_button(self):
        textfield = self.get_address_bar_text_field()
        return textfield.select_single("QQuickMouseArea",
                                       objectName="actionButton")

    def get_back_button(self):
        return self.select_single("ActionItem", objectName="backButton")

    def get_forward_button(self):
        return self.select_single("ActionItem", objectName="forwardButton")

    def get_current_webview(self):
        return self.select_single("WebViewImpl", current=True)

    def get_visible_webviews(self):
        return self.select_many("WebViewImpl", visible=True)

    def get_error_sheet(self):
        return self.select_single("ErrorSheet")

    def get_address_bar_text_field(self):
        return self.get_address_bar().select_single("TextField")

    def get_address_bar_suggestions(self):
        return self.select_single("Suggestions")

    def get_address_bar_suggestions_listview(self):
        suggestions = self.get_address_bar_suggestions()
        return suggestions.select_single("QQuickListView")

    def get_address_bar_suggestions_listview_entries(self):
        listview = self.get_address_bar_suggestions_listview()
        return listview.select_many("Base")

    def get_many_activity_view(self):
        return self.select_many("ActivityView")

    def get_activity_view(self):
        return self.wait_select_single("ActivityView")

    def get_tabslist(self):
        return self.get_activity_view().select_single("TabsList")

    def get_tabslist_newtab_delegate(self):
        return self.get_tabslist().select_single("UbuntuShape",
                                                 objectName="newTabDelegate")

    def get_tabslist_view(self):
        return self.get_tabslist().select_single("QQuickListView")

    def get_tabslist_view_delegates(self):
        view = self.get_tabslist_view()
        tabs = view.select_many("PageDelegate", objectName="openTabDelegate")
        tabs.sort(key=lambda tab: tab.x)
        return tabs

    def get_geolocation_dialog(self):
        return self.wait_select_single("GeolocationPermissionRequest")

    def get_new_tab_view(self):
        return self.wait_select_single("NewTabView")

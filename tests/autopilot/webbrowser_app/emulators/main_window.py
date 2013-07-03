# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.


class MainWindow(object):
    """
    An emulator class that makes it easy to interact with the webbrowser app.
    """

    def __init__(self, app):
        self.app = app

    def get_qml_view(self):
        """Get the main QML view"""
        return self.app.select_single("QQuickWindow")

    def get_browser(self):
        return self.app.select_single("Browser")

    def get_chrome(self):
        return self.app.select_single("Chrome")

    def get_address_bar(self):
        """Get the browsers address bar"""
        return self.app.select_single("AddressBar", objectName="addressBar")

    def get_address_bar_clear_button(self):
        textfield = self.get_address_bar_text_field()
        return textfield.get_children_by_type("AbstractButton")[0]

    def get_address_bar_action_button(self):
        textfield = self.get_address_bar_text_field()
        return textfield.select_single("QQuickMouseArea",
                                       objectName="actionButton")

    def get_back_button(self):
        return self.app.select_single("ActionItem", objectName="backButton")

    def get_forward_button(self):
        return self.app.select_single("ActionItem", objectName="forwardButton")

    def get_tabs_button(self):
        return self.app.select_single("ActionItem", objectName="tabsButton")

    def get_current_webview(self):
        browser = self.get_browser()
        webviews = self.app.select_many("UbuntuWebView")
        return webviews[browser.currentIndex]

    def get_error_sheet(self):
        return self.app.select_single("ErrorSheet")

    def get_address_bar_text_field(self):
        return self.get_address_bar().get_children_by_type("TextField")[0]

    def get_address_bar_suggestions(self):
        return self.app.select_single("Suggestions")

    def get_address_bar_suggestions_listview(self):
        suggestions = self.get_address_bar_suggestions()
        return suggestions.get_children_by_type("QQuickListView")[0]

    def get_address_bar_suggestions_listview_entries(self):
        listview = self.get_address_bar_suggestions_listview()
        return listview.get_children()[0].get_children_by_type("Base")

    def get_panel(self):
        return self.app.select_single("Panel")

    def get_activity_view(self):
        return self.app.select_single("ActivityView")

    def get_tabslist(self):
        return self.get_activity_view().select_single("TabsList")

    def get_tabslist_newtab_delegate(self):
        return self.get_tabslist().select_single("PageDelegate",
                                                 objectName="newTabDelegate")

    def get_tabslist_view(self):
        return self.get_tabslist().select_single("QQuickRepeater")

    def get_tabslist_view_delegates(self):
        row = self.get_tabslist().select_single("QQuickRow")
        delegates = row.select_many("PageDelegate")
        return delegates[1:]

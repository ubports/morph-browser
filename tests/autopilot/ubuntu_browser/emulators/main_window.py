# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

class MainWindow(object):
    """An emulator class that makes it easy to interact with the ubuntu browser."""

    def __init__(self, app):
        self.app = app

    def get_qml_view(self):
        """Get the main QML view"""
        return self.app.select_single("QQuickView")

    def get_address_bar(self):
        """Get the browsers address bar"""
        return self.app.select_single("TextField", objectName="addressBar")

    def get_address_bar_clear_button(self):
        return self.get_address_bar().get_children_by_type("AbstractButton")[0]

    def get_web_view(self):
        return self.app.select_single("QQuickWebView")

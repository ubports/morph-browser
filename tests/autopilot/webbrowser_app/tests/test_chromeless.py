# -*- coding: utf-8 -*-
#
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

from __future__ import absolute_import

from autopilot.introspection import dbus

from webbrowser_app.tests import BrowserTestCaseBase


class TestChromeless(BrowserTestCaseBase):

    """Tests the main browser features when run in chromeless mode."""

    ARGS = ['--chromeless']

    def test_chrome_is_not_loaded(self):
        try:
            self.main_window.get_chrome()
        except dbus.StateNotFoundError:
            pass
        else:
            self.fail("the chrome should not be loaded")

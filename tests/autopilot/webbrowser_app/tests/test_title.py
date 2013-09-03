# -*- coding: utf-8 -*-
#
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

from __future__ import absolute_import

from testtools.matchers import Contains
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestWindowTitle(StartOpenRemotePageTestCaseBase):

    """Tests that the window’s title reflects the page title."""

    def test_window_title(self):
        title = "Alice in Wonderland"
        body = "<p>Lorem ipsum dolor sit amet.</p>"
        url = self.make_html_page(title, body)
        self.go_to_url(url)
        window = self.app.select_single("QQuickWindow")
        self.assertThat(window.title, Eventually(Contains(title)))

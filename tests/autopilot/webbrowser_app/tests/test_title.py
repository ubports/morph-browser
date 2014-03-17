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

from __future__ import absolute_import

from testtools.matchers import Contains
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestWindowTitle(StartOpenRemotePageTestCaseBase):

    """Tests that the window’s title reflects the page title."""

    def test_window_title(self):
        self.go_to_url(self.base_url + "/aleaiactaest")
        #window = self.app.select_single("QQuickWindow")
        # XXX: for some reason, autopilot finds two instances of QQuickWindow.
        # One is the correct one, and the other one is not visible, its
        # dimensions are 0×0, it has no title, its parent is the webbrowser-app
        # object, and it has no children.
        # See https://bugs.launchpad.net/bugs/1248620.
        window = self.app.select_single("QQuickWindow", visible=True)
        self.assertThat(window.title, Eventually(Contains("Alea Iacta Est")))

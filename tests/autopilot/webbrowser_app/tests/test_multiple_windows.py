# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2016 Canonical
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

from testtools.matchers import Equals

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestMultipleWindows(StartOpenRemotePageTestCaseBase):

    def test_open_new_window(self):
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(1))
        self.open_new_window()
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(2))
        for window in windows:
            self.assertThat(window.incognito, Equals(False))

    def test_open_new_private_window(self):
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(1))
        self.open_new_private_window()
        windows = self.app.get_windows()
        self.assertThat(len(windows), Equals(2))
        self.assertThat(len(self.app.get_windows(incognito=False)), Equals(1))
        self.assertThat(len(self.app.get_windows(incognito=True)), Equals(1))

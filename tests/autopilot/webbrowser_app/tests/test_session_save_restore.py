# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2014 Canonical
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

from autopilot.matchers import Eventually
from testtools.matchers import Equals

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestSessionSaveRestore(StartOpenRemotePageTestCaseBase):

    def create_new_tab(self, url):
        self.open_tabs_view()
        self.open_new_tab()
        new_tab_view = self.main_window.get_new_tab_view()
        self.main_window.go_to_url(url)
        new_tab_view.wait_until_destroyed()

    def test_session_is_saved_and_restored(self):
        paths = ["/test1", "/test2", "/wait/0"]
        for path in paths[1:]:
            self.create_new_tab(self.base_url + path)
        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        self.assertThat(tabs_view.count, Eventually(Equals(len(paths))))
        process = self.app.process
        process.kill()
        process.wait(10)
        self.ARGS = []
        self.app = self.launch_app()
        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        self.assertThat(tabs_view.count, Eventually(Equals(len(paths))))
        previews = tabs_view.get_ordered_previews()
        for i in range(len(paths)):
            self.assertThat(previews[len(paths) - 1 - i].url,
                            Eventually(Equals(self.base_url + paths[i])))
        self.assert_number_webviews_eventually(1)

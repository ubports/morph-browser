# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2015 Canonical
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

import signal

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestSadTab(StartOpenRemotePageTestCaseBase):

    def test_reload_web_process_killed(self):
        self.kill_web_processes()
        sad_tab = self.main_window.get_sad_tab()
        sad_tab.click_reload_button()
        sad_tab.wait_until_destroyed()
        self.assert_home_page_eventually_loaded()

    def test_close_tab_web_process_killed(self):
        self.kill_web_processes()
        sad_tab = self.main_window.get_sad_tab()
        sad_tab.click_close_tab_button()
        sad_tab.wait_until_destroyed()
        self.main_window.get_new_tab_view()

    def test_reload_web_process_crashed(self):
        self.kill_web_processes(signal.SIGSEGV)
        sad_tab = self.main_window.get_sad_tab()
        sad_tab.click_reload_button()
        sad_tab.wait_until_destroyed()
        self.assert_home_page_eventually_loaded()

    def test_close_tab_web_process_crashed(self):
        self.kill_web_processes(signal.SIGSEGV)
        sad_tab = self.main_window.get_sad_tab()
        sad_tab.click_close_tab_button()
        sad_tab.wait_until_destroyed()
        self.main_window.get_new_tab_view()

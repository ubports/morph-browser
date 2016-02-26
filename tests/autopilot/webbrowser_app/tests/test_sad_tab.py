# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2015-2016 Canonical
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
import time

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestSadTab(StartOpenRemotePageTestCaseBase):

    def _kill_web_process(self):
        self.kill_web_processes()
        # The first time the web process is killed, the browser attempts to
        # reload the page gracefully (after a short delay), hoping the process
        # won’t be killed again.
        time.sleep(1)
        self.main_window.wait_until_page_loaded(self.url)

        self.kill_web_processes()
        # The second time around, the browser displays a sad tab.
        return self.main_window.get_sad_tab()

    def test_reload_web_process_killed(self):
        sad_tab = self._kill_web_process()
        sad_tab.click_reload_button()
        sad_tab.wait_until_destroyed()
        self.assert_home_page_eventually_loaded()

    def test_close_tab_web_process_killed(self):
        wide = self.main_window.wide
        sad_tab = self._kill_web_process()
        sad_tab.click_close_tab_button()
        if wide:
            # closing the last open tab exits the application
            self.app.process.wait()
            return
        sad_tab.wait_until_destroyed()
        self.main_window.get_new_tab_view()

    def _crash_web_process(self):
        self.kill_web_processes(signal.SIGABRT)
        # A crash of the web process displays the sad tab right away
        return self.main_window.get_sad_tab()

    def test_reload_web_process_crashed(self):
        sad_tab = self._crash_web_process()
        sad_tab.click_reload_button()
        sad_tab.wait_until_destroyed()
        self.assert_home_page_eventually_loaded()

    def test_close_tab_web_process_crashed(self):
        wide = self.main_window.wide
        sad_tab = self._crash_web_process()
        sad_tab.click_close_tab_button()
        if wide:
            # On desktop, closing the last open tab exits the application
            self.app.process.wait()
            return
        sad_tab.wait_until_destroyed()
        self.main_window.get_new_tab_view()

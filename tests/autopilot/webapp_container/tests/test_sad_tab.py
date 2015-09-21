# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
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
import time

from autopilot.platform import model

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase


class TestSadTab(WebappContainerTestCaseWithLocalContentBase):
    def _kill_web_process(self):
        self.kill_web_processes()
        # The first time the web process is killed, the browser attempts to
        # reload the page gracefully (after a short delay), hoping the process
        # won’t be killed again.
        time.sleep(1)
        self.assert_page_eventually_loaded(self.url)

        self.kill_web_processes()
        # The second time around, the browser displays a sad tab.
        return self.get_sad_tab()

    def test_reload_main_webview_killed(self):
        self.launch_webcontainer_app_with_local_http_server([])
        self.get_webcontainer_window().visible.wait_for(True)

        sad_tab = self._kill_web_process()
        sad_tab.click_reload_button()
        sad_tab.wait_until_destroyed()
        self.assert_page_eventually_loaded(self.url)

    def test_reload_overlay_killed(self):
        args = []
        self.launch_webcontainer_app_with_local_http_server(
            args,
            '/open-close-content')
        self.get_webcontainer_window().visible.wait_for(True)

        views = self.get_popup_overlay_views()
        self.click_href_target_blank()
        self.assertThat(
            lambda: len(self.get_popup_overlay_views()),
            Eventually(Equals(1)))

        views = self.get_popup_overlay_views()
        overlay = views[0]

        sad_tab = self._kill_web_process()

        closeButton = overlay.select_single(
            objectName='overlayCloseButton')

        sad_tab.click_close_tab_button()
        sad_tab.wait_until_destroyed()
        self.main_window.get_new_tab_view()

    def _crash_web_process(self):
        self.kill_web_processes(signal.SIGABRT)
        # A crash of the web process displays the sad tab right away
        return self.get_sad_tab()

    def test_reload_main_webview_crashed(self):
        sad_tab = self._crash_web_process()
        sad_tab.click_reload_button()
        sad_tab.wait_until_destroyed()
        self.assert_page_eventually_loaded(self.url)

    def test_reload_overlay_crashed(self):
        sad_tab = self._crash_web_process()
        sad_tab.click_close_tab_button()
        if model() == 'Desktop':
            # On desktop, closing the last open tab exits the application
            self.app.process.wait()
            return
        sad_tab.wait_until_destroyed()
        self.main_window.get_new_tab_view()

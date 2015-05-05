# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2013-2015 Canonical
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
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestPrivateView(StartOpenRemotePageTestCaseBase):

    def confirm_leaving_private_mode(self):
        dialog = self.main_window.get_leave_private_mode_dialog()
        ok_button = dialog.select_single(
            "Button", objectName="leavePrivateModeDialog.okButton")
        self.pointing_device.click_object(ok_button)
        dialog.wait_until_destroyed()

    def cancel_leaving_private_mode(self):
        dialog = self.main_window.get_leave_private_mode_dialog()
        cancel_button = dialog.select_single(
            "Button", objectName="leavePrivateModeDialog.cancelButton")
        self.pointing_device.click_object(cancel_button)
        dialog.wait_until_destroyed()

    def go_into_private_mode(self):
        self.toggle_private_mode()

    def leave_private_mode(self):
        self.toggle_private_mode()
        self.confirm_leaving_private_mode()

    def test_going_in_and_out_private_mode(self):
        self.go_into_private_mode()
        new_private_tab_view = self.main_window.get_new_private_tab_view()
        self.leave_private_mode()
        new_private_tab_view.wait_until_destroyed()

    def test_cancel_leaving_private_mode(self):
        self.go_into_private_mode()
        new_private_tab_view = self.main_window.get_new_private_tab_view()
        self.toggle_private_mode()
        self.cancel_leaving_private_mode()
        self.assertThat(new_private_tab_view.visible, Eventually(Equals(True)))

    def test_usual_tabs_not_visible_in_private(self):
        self.open_tabs_view()
        self.open_new_tab()
        new_tab_view = self.main_window.get_new_tab_view()
        url = self.base_url + "/test1"
        self.main_window.go_to_url(url)
        new_tab_view.wait_until_destroyed()
        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = tabs_view.get_previews()
        self.assertThat(len(previews), Equals(2))
        tabs_view.get_previews()[1].select()
        tabs_view.visible.wait_for(False)
        self.assertThat(lambda: self.main_window.get_current_webview().url,
                        Eventually(Equals(url)))

        self.go_into_private_mode()
        self.open_tabs_view()
        tabs_view = self.main_window.get_tabs_view()
        previews = tabs_view.get_previews()
        self.assertThat(len(previews), Equals(1))

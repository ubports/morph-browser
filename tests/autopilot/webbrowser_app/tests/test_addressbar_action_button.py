# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2013-2014 Canonical
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


class TestAddressBarActionButton(StartOpenRemotePageTestCaseBase):

    def test_button_disabled_when_text_is_empty(self):
        self.clear_address_bar()
        address_bar = self.main_window.get_chrome().get_address_bar()
        action_button = address_bar.get_action_button()
        self.assertThat(action_button.enabled, Eventually(Equals(False)))
        self.type_in_address_bar("ubuntu")
        self.assertThat(action_button.enabled, Eventually(Equals(True)))

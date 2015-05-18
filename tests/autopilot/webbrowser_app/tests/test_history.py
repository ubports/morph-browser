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

from testtools.matchers import Equals
from autopilot.matchers import Eventually

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestHistory(StartOpenRemotePageTestCaseBase):

    def test_history_not_save_404(self):
        self.open_tabs_view()
        self.open_new_tab()
        url = self.base_url + "/404page"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)

        history = self.open_history()
        self.assertThat(lambda: len(history.get_history_urls()),
                        Eventually(Equals(1)))

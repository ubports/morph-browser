# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
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

""" Autopilot tests for the webapp_container package """

import os
import subprocess

from autopilot.testcase import AutopilotTestCase
from autopilot.platform import model

from ubuntuuitoolkit import emulators as toolkit_emulators
from webapp_container.tests import fake_servers

BASE_FILE_PATH = os.path.dirname(os.path.realpath(__file__))
CONTAINER_EXEC_REL_PATH = '../../../../src/app/webcontainer/webapp-container'
INSTALLED_BROWSER_CONTAINER_PATH_NAME = 'webapp-container'
try:
    INSTALLED_BROWSER_CONTAINER_PATH_NAME = subprocess.check_output(
        ['which', 'webapp-container']).strip()
except subprocess.CalledProcessError:
    pass

LOCAL_BROWSER_CONTAINER_PATH_NAME = \
    os.path.join(BASE_FILE_PATH, CONTAINER_EXEC_REL_PATH)


class WebappContainerTestCaseBase(AutopilotTestCase):
    def get_webcontainer_app_path(self):
        if os.path.exists(LOCAL_BROWSER_CONTAINER_PATH_NAME):
            return LOCAL_BROWSER_CONTAINER_PATH_NAME
        return INSTALLED_BROWSER_CONTAINER_PATH_NAME

    def launch_webcontainer_app(self, args):
        if model() != 'Desktop':
            args.append(
                '--desktop_file_hint=/usr/share/applications/'
                'webbrowser-app.desktop')
        try:
            self.app = self.launch_test_application(
                self.get_webcontainer_app_path(),
                *args,
                emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)
        except:
            self.app = None

    def get_webcontainer_proxy(self):
        return self.app

    def get_webcontainer_window(self):
        return self.app.select_single(objectName="webappContainer")

    def get_webcontainer_webview(self):
        return self.app.select_single(objectName="webappBrowserView")

    def get_webcontainer_panel(self):
        return self.app.select_single(objectName="panel")


class WebappContainerTestCaseWithLocalContentBase(WebappContainerTestCaseBase):
    def setUp(self):
        super(WebappContainerTestCaseWithLocalContentBase, self).setUp()
        self.http_server = fake_servers.WebappContainerContentHttpServer()
        self.addCleanup(self.http_server.shutdown)
        self.base_url = "http://localhost:{}".format(self.http_server.port)

    def launch_webcontainer_app_with_local_http_server(self, args, path='/'):
        self.url = self.base_url + path
        args.append(self.url)
        self.launch_webcontainer_app(args)

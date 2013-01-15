# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Ubuntu-browser autopilot tests."""

from os import remove
import os.path

from autopilot.introspection.qt import QtIntrospectionTestMixin
from autopilot.testcase import AutopilotTestCase

from ubuntu_browser.emulators.main_window import MainWindow

class BrowserTestCase(AutopilotTestCase, QtIntrospectionTestMixin):

    """A common test case class that provides several useful methods for ubuntu browser tests."""

    def setUp(self):
        super(BrowserTestCase, self).setUp()
        # Lets assume we are installed system wide if this file is somewhere in /usr
        if os.path.realpath(__file__).startswith("/usr/"):
            self.launch_test_installed()
        else:
            self.launch_test_local()

    def launch_test_local(self):
        self.app = self.launch_test_application(
            "../../src/ubuntu-browser")

    def launch_test_installed(self):
        if self.running_on_device():
            self.app = self.launch_test_application(
               "ubuntu-browser",
               "--fullscreen")
        else:
            self.app = self.launch_test_application(
               "ubuntu-browser")

    @staticmethod
    def running_on_device():
        return os.path.isfile('/system/usr/idc/autopilot-finger.idc')

    @property
    def main_window(self):
        return MainWindow(self.app)


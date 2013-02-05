# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Ubuntu-browser autopilot tests."""

import os
import tempfile

from testtools.matchers import Equals

from autopilot.introspection.qt import QtIntrospectionTestMixin
from autopilot.matchers import Eventually
from autopilot.testcase import AutopilotTestCase

from ubuntu_browser.emulators.main_window import MainWindow


class BrowserTestCaseBase(AutopilotTestCase, QtIntrospectionTestMixin):

    """
    A common test case class that provides several useful methods
    for ubuntu browser tests.
    """

    ARGS = []
    _temp_pages = []

    def setUp(self):
        super(BrowserTestCaseBase, self).setUp()
        # assume we are installed system-wide if this file is somewhere in /usr
        if os.path.realpath(__file__).startswith("/usr/"):
            self.launch_test_installed()
        else:
            self.launch_test_local()
        # This is needed to wait for the application to start.
        # In the testfarm, the application may take some time to show up.
        self.assertThat(self.main_window.get_qml_view().visible,
                        Eventually(Equals(True)))

    def tearDown(self):
        super(BrowserTestCaseBase, self).tearDown()
        for page in self._temp_pages:
            try:
                os.remove(page)
            except:
                pass
        self._temp_pages = []

    def launch_test_local(self):
        self.app = self.launch_test_application("../../src/ubuntu-browser",
                                                *self.ARGS)

    def launch_test_installed(self):
        if self.running_on_device():
            self.app = self.launch_test_application("ubuntu-browser",
                                                    "--fullscreen",
                                                    *self.ARGS)
        else:
            self.app = self.launch_test_application("ubuntu-browser",
                                                    *self.ARGS)

    @staticmethod
    def running_on_device():
        return os.path.isfile('/system/usr/idc/autopilot-finger.idc')

    @property
    def main_window(self):
        return MainWindow(self.app)

    def make_html_page(self, title, body):
        """
        Write a web page using title and body onto a temporary file,
        and return the corresponding local "file://…" URL. The file
        is automatically deleted after running the calling test method.
        """
        fd, path = tempfile.mkstemp(suffix=".html", text=True)
        os.write(fd,
                    "<html>"
                        "<title>" + title + "</title>"
                        "<body>" + body + "</body>"
                    "</html>")
        os.close(fd)
        self._temp_pages.append(path)
        return "file://" + path

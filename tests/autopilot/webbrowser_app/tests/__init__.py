# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""webbrowser-app autopilot tests."""

import os
import os.path
import shutil
import tempfile

from testtools.matchers import Equals

from autopilot.input import Mouse, Touch, Pointer
from autopilot.matchers import Eventually
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase

import http_server

from webbrowser_app.emulators.main_window import MainWindow


HTTP_SERVER_PORT = 8129
TYPING_DELAY = 0.001


class BrowserTestCaseBase(AutopilotTestCase):

    """
    A common test case class that provides several useful methods
    for webbrowser-app tests.
    """

    if model() == 'Desktop':
        scenarios = [('with mouse', dict(input_device_class=Mouse)), ]
    else:
        scenarios = [('with touch', dict(input_device_class=Touch)), ]

    local_location = "../../src/webbrowser-app"

    ARGS = []
    _temp_pages = []

    def setUp(self):
        self.pointing_device = Pointer(self.input_device_class.create())
        super(BrowserTestCaseBase, self).setUp()
        if os.path.exists(self.local_location):
            self.launch_test_local()
        else:
            self.launch_test_installed()
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
        self.app = self.launch_test_application(self.local_location,
                                                *self.ARGS)

    def launch_test_installed(self):
        if model() == 'Desktop':
            self.app = self.launch_test_application("webbrowser-app",
                                                    *self.ARGS)
        else:
            self.app = self.launch_test_application(
                "webbrowser-app",
                "--fullscreen",
                "--desktop_file_hint=/usr/share/applications/webbrowser-app.desktop",
                *self.ARGS,
                app_type='qt')

    def clear_cache(self):
        cachedir = os.path.join(os.path.expanduser("~"), ".local", "share",
                                "webbrowser-app")
        shutil.rmtree(cachedir, True)
        os.makedirs(cachedir)

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
        html = "<html><title>%s</title><body>%s</body></html>" % (title, body)
        os.write(fd, html)
        os.close(fd)
        self._temp_pages.append(path)
        return "file://" + path

    def reveal_chrome(self):
        distance = self.main_window.get_chrome().height
        view = self.main_window.get_qml_view()
        x_line = int(view.x + view.width * 0.5)
        start_y = int(view.y + view.height - 1)
        stop_y = int(start_y - distance)
        self.pointing_device.drag(x_line, start_y, x_line, stop_y)

    def hide_chrome(self):
        distance = self.main_window.get_chrome().height
        view = self.main_window.get_qml_view()
        x_line = int(view.x + view.width * 0.5)
        start_y = int(self.main_window.get_chrome().globalRect[1])
        stop_y = int(start_y + distance)
        self.pointing_device.drag(x_line, start_y, x_line, stop_y)

    def go_to_url(self, url):
        self.reveal_chrome()
        address_bar = self.main_window.get_address_bar()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()
        clear_button = self.main_window.get_address_bar_clear_button()
        self.pointing_device.move_to_object(clear_button)
        self.pointing_device.click()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()
        self.keyboard.type(url, delay=TYPING_DELAY)
        self.keyboard.press("Enter")

    def assert_page_eventually_loaded(self, url):
        webview = self.main_window.get_web_view()
        self.assertThat(webview.url, Eventually(Equals(url)))


class StartOpenLocalPageTestCaseBase(BrowserTestCaseBase):

    """Helper test class that opens the browser at a local URL instead of
    defaulting to the homepage."""

    def setUp(self):
        title = "start page"
        body = "<p>Lorem ipsum dolor sit amet.</p>"
        self.url = self.make_html_page(title, body)
        self.ARGS = [self.url]
        super(StartOpenLocalPageTestCaseBase, self).setUp()
        self.assert_home_page_eventually_loaded()

    def assert_home_page_eventually_loaded(self):
        self.assert_page_eventually_loaded(self.url)


class BrowserTestCaseBaseWithHTTPServer(BrowserTestCaseBase):

    """
    A specialization of the common test case class that runs
    a simple custom HTTP server in a separate thread.
    """

    def setUp(self):
        self.server = http_server.HTTPServerInAThread(HTTP_SERVER_PORT)
        self.server.start()
        super(BrowserTestCaseBaseWithHTTPServer, self).setUp()

    def tearDown(self):
        super(BrowserTestCaseBaseWithHTTPServer, self).tearDown()
        self.server.shutdown()


class StartOpenRemotePageTestCaseBase(BrowserTestCaseBaseWithHTTPServer):

    """Helper test class that opens the browser at a remote URL instead of
    defaulting to the homepage."""

    def setUp(self):
        self.base_url = "http://localhost:%d" % HTTP_SERVER_PORT
        self.url = self.base_url + "/loremipsum"
        self.ARGS = [self.url]
        super(StartOpenRemotePageTestCaseBase, self).setUp()
        self.assert_home_page_eventually_loaded()

    def assert_home_page_eventually_loaded(self):
        self.assert_page_eventually_loaded(self.url)

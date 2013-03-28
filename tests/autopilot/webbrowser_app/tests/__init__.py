# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""webbrowser-app autopilot tests."""

import BaseHTTPServer
import os
import tempfile
import threading
import time

from testtools.matchers import Equals

from autopilot.introspection.qt import QtIntrospectionTestMixin
from autopilot.matchers import Eventually
from autopilot.testcase import AutopilotTestCase

from webbrowser_app.emulators.main_window import MainWindow


HTTP_SERVER_PORT = 8129


class BrowserTestCaseBase(AutopilotTestCase, QtIntrospectionTestMixin):

    """
    A common test case class that provides several useful methods
    for webbrowser-app tests.
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
        self.app = self.launch_test_application("../../src/webbrowser-app",
                                                *self.ARGS)

    def launch_test_installed(self):
        if self.running_on_device():
            self.app = self.launch_test_application("webbrowser-app",
                                                    "--fullscreen",
                                                    *self.ARGS)
        else:
            self.app = self.launch_test_application("webbrowser-app",
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


class HTTPRequestHandler(BaseHTTPServer.BaseHTTPRequestHandler):

    """
    A custom HTTP request handler that serves GET resources.
    """

    def make_html(self, title, body):
        return "<html><title>" + title + "</title>" + \
               "<body>" + body + "</body></html>"

    def send_html(self, html):
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        self.wfile.write(html)

    def do_GET(self):
        if self.path == "/loremipsum":
            self.send_response(200)
            title = "Lorem Ipsum"
            body = "<p>Lorem ipsum dolor sit amet.</p>"
            html = self.make_html(title, body)
            self.send_html(html)
        elif self.path.startswith("/wait/"):
            delay = int(self.path[6:])
            self.send_response(200)
            title = "waiting %d seconds" % delay
            body = "<p>this page took %d seconds to load</p>" % delay
            html = self.make_html(title, body)
            time.sleep(delay)
            self.send_html(html)
        else:
            self.send_error(404)


class HTTPServerInAThread(threading.Thread):

    """
    A simple custom HTTP server run in a separate thread.
    """

    def __init__(self, port):
        super(HTTPServerInAThread, self).__init__()
        self.server = BaseHTTPServer.HTTPServer(("", port), HTTPRequestHandler)
        self.server.allow_reuse_address = True

    def run(self):
        self.server.serve_forever()

    def shutdown(self):
        self.server.shutdown()
        self.server.server_close()


class BrowserTestCaseBaseWithHTTPServer(BrowserTestCaseBase):

    """
    A specialization of the common test case class that runs
    a simple custom HTTP server in a separate thread.
    """

    def setUp(self):
        self.server = HTTPServerInAThread(HTTP_SERVER_PORT)
        self.server.start()
        super(BrowserTestCaseBaseWithHTTPServer, self).setUp()

    def tearDown(self):
        super(BrowserTestCaseBaseWithHTTPServer, self).tearDown()
        self.server.shutdown()

# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License version 3, as
# published by the Free Software Foundation.

""" Autopilot tests for the webapp_container package """

import os
import BaseHTTPServer
import threading
import subprocess

from autopilot.testcase import AutopilotTestCase
from autopilot.input import Mouse, Pointer

from ubuntuuitoolkit import emulators as toolkit_emulators

BASE_FILE_PATH = os.path.dirname(os.path.realpath(__file__))
CONTAINER_EXEC_REL_PATH = '../../../../src/app/webcontainer/webapp-container'
INSTALLED_BROWSER_CONTAINER_PATH_NAME = 'webapp-container'
try:
    INSTALLED_BROWSER_CONTAINER_PATH_NAME = subprocess.check_output(
        ['which', 'webapp-container']).strip()
except:
    pass


class WebappContainerTestCaseBase(AutopilotTestCase):
    LOCAL_BROWSER_CONTAINER_PATH_NAME = "%s/%s" % (BASE_FILE_PATH,
                                                   CONTAINER_EXEC_REL_PATH)
    ARGS = []

    def setUp(self):
        super(WebappContainerTestCaseBase, self).setUp()
        self.pointer = Pointer(Mouse.create())

    def tearDown(self):
        super(WebappContainerTestCaseBase, self).tearDown()

    def get_webcontainer_app_path(self):
        if os.path.exists(self.LOCAL_BROWSER_CONTAINER_PATH_NAME):
            return self.LOCAL_BROWSER_CONTAINER_PATH_NAME
        return INSTALLED_BROWSER_CONTAINER_PATH_NAME

    def launch_webcontainer_app(self):
        try:
            self.app = self.launch_test_application(
                self.get_webcontainer_app_path(),
                *self.ARGS,
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


HTTP_SERVER_PORT = 8383


class RequestHandler(BaseHTTPServer.BaseHTTPRequestHandler):
    def serve_content(self, content, mime_type='text/html'):
        self.send_response(200)
        self.send_header('Content-type', mime_type)
        self.end_headers()
        self.wfile.write(content)

    def basic_html_content(self):
        return """
<html>
<head>
<title>Some content</title>
</head>
<body>
This is some content
</body>
</html>
        """

    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.serve_content(self.basic_html_content())
        else:
            self.send_error(404)


class WebappContainerContentHttpServer(threading.Thread):
    def __init__(self, port):
        super(WebappContainerContentHttpServer, self).__init__()
        self.port = port
        self.server = BaseHTTPServer.HTTPServer(("", port), RequestHandler)
        self.server.allow_reuse_address = True

    def run(self):
        self.server.serve_forever()

    def shutdown(self):
        self.server.shutdown()
        self.server.server_close()


class WebappContainerTestCaseWithLocalContentBase(WebappContainerTestCaseBase):
    def setUp(self):
        self.server = WebappContainerContentHttpServer(HTTP_SERVER_PORT)
        self.server.start()
        self.addCleanup(self.server.shutdown)
        self.base_url = "http://localhost:%d" % self.server.port
        super(WebappContainerTestCaseWithLocalContentBase, self).setUp()

    def launch_webcontainer_app_with_local_http_server(self, path='/'):
        self.url = self.base_url + path
        self.ARGS.append(self.url)
        self.launch_webcontainer_app()

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

import BaseHTTPServer
import threading


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
    def __init__(self):
        super(WebappContainerContentHttpServer, self).__init__()
        self.server = BaseHTTPServer.HTTPServer(("", 0), RequestHandler)
        self.server.allow_reuse_address = True

    def run(self):
        self.server.serve_forever()

    def shutdown(self):
        self.server.shutdown()
        self.server.server_close()

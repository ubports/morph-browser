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

import http.server as http
import logging
import threading


class RequestHandler(http.BaseHTTPRequestHandler):
    def serve_content(self, content, mime_type='text/html'):
        self.send_header('Content-type', mime_type)
        self.end_headers()
        self.wfile.write(content.encode())

    def basic_html_content(self, content="basic"):
        return """
<html>
<head>
<title>Some content</title>
</head>
<body>
This is some {} content
</body>
</html>
        """.format(content)

    def redirect_html_content(self):
        return """
<html>
<head>
<title>Some content</title>
</head>
<body>
<div><a href='/redirect?url=myredirect&s=1&r=2' target='_blank'>
<div style="height: 100%; width: 100%"></div>
</a></div>
</body>
</html>
        """

    def external_click_content(self):
        return """
<html>
<head>
<title>Some content</title>
</head>
<body>
<div><a href='http://www.ubuntu.com/'>
<div style="height: 100%; width: 100%"></div>
</a></div>
</body>
</html>
        """

    def targetted_click_content(self):
        return """
<html>
<head>
<title>Some content</title>
</head>
<body>
<div>
<a href="/open-close-content" target="_blank">
<div style="height: 100%; width: 100%">
</div>
</a>
</div>
</body>
</html>
        """

    def display_ua_content(self):
        return """
<html>
<head>
<title>Some content</title>
<script>
window.onload = function() {{
  document.title = navigator.userAgent + " " + {};
}}
</script>
</head>
<body>
</body>
</html>
        """.format("'"+self.headers['user-agent']+"'")

    def saml(self, loopcount):
        return """
    <html>
    <head>
    <title>open-close</title>
    <script>
    </script>
    </head>
    <body>
    <a href="/redirect-to-saml/?loopcount={}&SAMLRequest=1">
        <div style="height: 100%; width: 100%; background-color: red">
            target blank link
        </div>
    </a>
    </body>
    </html>
        """.format(loopcount)

    def open_close_content(self):
        return """
<html>
<head>
<title>open-close</title>
<script>
</script>
</head>
<body>
    <a href="/open-close-content" target="_blank">
        <div style="height: 50%; width: 100%; background-color: red">
            target blank link
        </div>
    </a>
    <div id="lorem" style="height: 50%; width: 100%; background-color: blue">
        Lorem ipsum dolor sit amet
    </div>
</body>
</html>
        """

    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.serve_content(self.basic_html_content())
        elif self.path == '/other':
            self.send_response(200)
            self.serve_content(self.basic_html_content("other"))
        elif self.path == '/get-redirect':
            self.send_response(200)
            self.serve_content(self.redirect_html_content())
        elif self.path == '/with-external-link':
            self.send_response(200)
            self.serve_content(self.external_click_content())
        elif self.path == '/with-targetted-link':
            self.send_response(200)
            self.serve_content(self.targetted_click_content())
        elif self.path == '/show-user-agent':
            self.send_response(200)
            self.serve_content(self.display_ua_content())
        elif self.path == '/open-close-content':
            self.send_response(200)
            self.serve_content(self.open_close_content())
        elif self.path.startswith('/saml/'):
            args = self.path[len('/saml/'):]
            loopCount = 0
            if args.startswith('?loopcount='):
                loopCount = int(args[len('?loopcount='):].split(';')[0])
            self.send_response(200)
            self.serve_content(self.saml(loopCount))
        elif self.path.startswith('/redirect-to-saml/'):
            locationTarget = '/'
            args = self.path[len('/redirect-to-saml/'):]
            if args.startswith('?loopcount='):
                header_size = len('?loopcount=')
                loopCount = int(
                    args[header_size:args.index('&')].split(';')[0])
                if loopCount > 0:
                    loopCount = loopCount - 1
                    locationTarget += 'redirect-to-saml\
/?loopcount=' + str(loopCount) + '&SAMLRequest=1'
            self.send_response(302)
            self.send_header("Location", locationTarget)
            self.end_headers()
        else:
            self.send_error(404)


class WebappContainerContentHttpServer(object):
    def __init__(self):
        super(WebappContainerContentHttpServer, self).__init__()
        self.server = http.HTTPServer(("", 0), RequestHandler)
        self.server.allow_reuse_address = True
        self.server_thread = threading.Thread(target=self.server.serve_forever)
        self.server_thread.start()
        logging.info("now serving on port {}".format(self.server.server_port))

    @property
    def port(self):
        return self.server.server_port

    def run(self):
        self.server.serve_forever()

    def shutdown(self):
        self.server.shutdown()
        self.server.server_close()
        self.server_thread.join()

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
import urllib


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

    def external_href_with_link_content(self, path="open-close-content"):
        return """
<html>
<head>
<title>Some content</title>
</head>
<body>
<div>
<a href="/{}" target="_blank">
<div style="height: 100%; width: 100%">
</div>
</a>
</div>
</body>
</html>
        """.format(path)

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

    def manifest_json_content(self):
        return """
{
  "name": "Theme Color",
  "short_name": "Theme Color",
  "icons": [],
  "theme_color": "#FF0000"
}        """

    def theme_color_content(self, color, with_manifest=False):
        color_content = ''
        if color:
            color_content = """
<meta name=\"theme-color\" content=\"{}\"></meta>
""".format(color)
        manifest_content = ''
        if with_manifest:
            manifest_content = "<link rel=\"manifest\" href=\"manifest.json\">"

        return """
<html>
<head>
{}
{}
<title>theme-color</title>
<script>
</script>
</head>
<body>
</body>
</html>
        """.format(color_content, manifest_content)

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

    base64_png_data = \
        "iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAIAAACRXR/mAAAACXBIWXMAAAsTAAALEwE" \
        "AmpwYAAAAOUlEQVRYw+3OAQ0AAAgDoGv/zlpDN0hATS7qaGlpaWlpaWlpaWlpaWlpaW" \
        "lpaWlpaWlpaWlpab1qLUGqAWNyFWTYAAAAAElFTkSuQmCC"

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
        elif self.path == "/image":
            self.send_response(200)
            html = '<html><body>'
            html += '<img src="data:image/png;base64,' + self.base64_png_data
            html += '" style="position: fixed; top: 50%; left: 50%; '
            html += 'transform: translate(-50%, -50%)" />'
            html += '</body></html>'
            self.serve_content(html)
        elif self.path == "/imagelink":
            self.send_response(200)
            html = '<html><body><a href="http://www.ubuntu.com">'
            html += '<img src="data:image/png;base64,' + self.base64_png_data
            html += '" style="position: fixed; top: 50%; left: 50%; '
            html += 'transform: translate(-50%, -50%)" />'
            html += '</a></body></html>'
            self.serve_content(html)
        elif self.path == "/textarea":
            self.send_response(200)
            html = '<html><body style="margin: 0">'
            html += '<textarea style="width: 100%; height: 100%">some text'
            html += '</textarea></body></html>'
            self.serve_content(html)
        elif self.path == '/with-targetted-link':
            self.send_response(200)
            self.serve_content(self.external_href_with_link_content())
        elif self.path == '/show-user-agent':
            self.send_response(200)
            self.serve_content(self.display_ua_content())
        elif self.path == '/open-close-content':
            self.send_response(200)
            self.serve_content(self.open_close_content())
        elif self.path == '/theme-color/manifest.json':
            self.send_response(200)
            self.serve_content(self.manifest_json_content())
        elif self.path.startswith('/theme-color/'):
            args = self.path[len('/theme-color/'):]
            self.send_response(200)
            color = ''
            if args.startswith('?color='):
                color = args[len('?color='):]
            with_manifest = False
            if args.startswith('?manifest='):
                with_manifest = True
            self.send_response(200)
            self.serve_content(self.theme_color_content(color, with_manifest))
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
        elif self.path.startswith('/with-overlay-link'):
            qs = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            self.send_response(200)
            self.serve_content(self.external_href_with_link_content(qs['path'][0]))
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

# -*- coding: utf-8 -*-
#
# Copyright 2013-2016 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

from base64 import b64decode
import http.server as http
import json
import logging
import threading
import time

logger = logging.getLogger(__name__)


class HTTPRequestHandler(http.BaseHTTPRequestHandler):

    """
    A custom HTTP request handler that serves GET resources.
    """

    suggestions_data = {}

    base64_png_data = \
        "iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAIAAACRXR/mAAAACXBIWXMAAAsTAAALEwE" \
        "AmpwYAAAAOUlEQVRYw+3OAQ0AAAgDoGv/zlpDN0hATS7qaGlpaWlpaWlpaWlpaWlpaW" \
        "lpaWlpaWlpaWlpab1qLUGqAWNyFWTYAAAAAElFTkSuQmCC"

    def make_html(self, title, body):
        html = "<html><title>{}</title><body>{}</body></html>"
        return html.format(title, body)

    def send_html(self, html):
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        self.wfile.write(html.encode())

    def send_auth_request(self):
        self.send_response(401)
        self.send_header("WWW-Authenticate", "Basic realm=\"Enter Password\"")
        self.end_headers()
        self.send_html("Not Authorized")

    def do_GET(self):
        if self.path == "/ping":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"pong")
        elif self.path == "/test1":
            self.send_response(200)
            title = "test page 1"
            body = "<p>test page 1</p>"
            html = self.make_html(title, body)
            self.send_html(html)
        elif self.path == "/test2":
            self.send_response(200)
            title = "test page 2"
            body = "<p>test page 2</p>"
            html = self.make_html(title, body)
            self.send_html(html)
        elif self.path == "/link":
            self.send_response(200)
            html = '<html><body style="margin: 0">'
            html += '<a href="/test1"><div style="height: 100%"></div></a>'
            html += '</body></html>'
            self.send_html(html)
        elif self.path.startswith("/wait/"):
            delay = int(self.path[6:])
            self.send_response(200)
            title = "waiting {} seconds".format(delay)
            body = "<p>this page took {} seconds to load</p>".format(delay)
            html = self.make_html(title, body)
            time.sleep(delay)
            self.send_html(html)
        elif self.path == "/blanktargetlink":
            # craft a page that accepts clicks anywhere inside its window
            # and that requests opening another page in a new tab
            self.send_response(200)
            html = '<html><body style="margin: 0">'
            html += '<a href="/test2" target="_blank">'
            html += '<div style="height: 100%"></div></a>'
            html += '</body></html>'
            self.send_html(html)
        elif self.path == "/fulliframewithblanktargetlink":
            # iframe that takes up the whole page and that contains
            # the page above
            self.send_response(200)
            html = '<html><body style="margin: 0">'
            html += '<iframe height="100%" width="100%" '
            html += 'src="/blanktargetlink" />'
            html += '</body></html>'
            self.send_html(html)
        elif self.path == "/image":
            self.send_response(200)
            html = '<html><body>'
            html += '<img src="data:image/png;base64,' + self.base64_png_data
            html += '" style="position: fixed; top: 50%; left: 50%; '
            html += 'transform: translate(-50%, -50%)" />'
            html += '</body></html>'
            self.send_html(html)
        elif self.path == "/imagelink":
            self.send_response(200)
            html = '<html><body><a href="/test1">'
            html += '<img src="data:image/png;base64,' + self.base64_png_data
            html += '" style="position: fixed; top: 50%; left: 50%; '
            html += 'transform: translate(-50%, -50%)" />'
            html += '</a></body></html>'
            self.send_html(html)
        elif self.path == "/textarea":
            self.send_response(200)
            html = '<html><body style="margin: 0">'
            html += '<textarea style="width: 100%; height: 100%">some text'
            html += '</textarea></body></html>'
            self.send_html(html)
        elif self.path == "/uploadform":
            # craft a page that accepts clicks anywhere inside its window
            # and on a click opens up the content picker.
            # It also pops up an alert with the new content of the file
            # upload field when it changes
            self.send_response(200)
            html = '<html><body style="margin: 0">'
            html += '<form action="upload" method="post" '
            html += 'enctype="multipart/form-data">'
            html += '<input type="file" name="file" id="file" '
            html += 'onchange="alert(this.value)"><br>'
            html += '<input type="submit" name="submit" value="Submit">'
            html += '</form>'
            html += '<a href="javascript:'
            html += 'document.getElementById(\'file\').click()">'
            html += '<div style="height: 100%"></div></a>'
            html += '</body></html>'
            self.send_html(html)
        elif self.path == "/fullscreen":
            # craft a page that accepts clicks anywhere inside its window
            # to toggle fullscreen mode on/off
            self.send_response(200)
            html = '<html><body style="margin: 0">'
            html += '<a id="fullscreen"><div style="height: 100%"></div></a>'
            html += '</body><script>'
            html += 'document.getElementById("fullscreen").addEventListener('
            html += '"click", function(event) { '
            html += 'if (!document.webkitFullscreenElement) { '
            html += 'document.documentElement.webkitRequestFullscreen(); '
            html += '} else { document.webkitExitFullscreen(); } });'
            html += '</script></html>'
            self.send_html(html)
        elif self.path == "/geolocation":
            self.send_response(200)
            html = '<html><body><script>'
            html += 'navigator.geolocation.getCurrentPosition('
            html += 'function r(p) {});</script></body></html>'
            self.send_html(html)
        elif self.path == "/closeself":
            # craft a page that accepts clicks anywhere inside its window
            # and that requests to be closed
            self.send_response(200)
            html = '<html><body style="margin: 0">'
            html += '<a onclick="window.close()">'
            html += '<div style="height: 100%"></div>'
            html += '</a></body></html>'
            self.send_html(html)
        elif self.path == "/findinpage":
            # send a page with some searchable text
            self.send_response(200)
            html = '<html><body>hello this is text and more text</body></html>'
            self.send_html(html)
        elif self.path.startswith("/suggest"):
            self.send_response(200)
            self.send_header("Content-Type", "text/x-suggestions+json")
            self.end_headers()
            query = self.path[len("/suggest?q="):]
            if query in self.suggestions_data:
                suggestions = self.suggestions_data[query]
                self.wfile.write(json.dumps(suggestions).encode())
        elif self.path.startswith("/tab/"):
            self.send_response(200)
            name = self.path[len("/tab/"):]
            self.send_html('<html><body>' + name + '</body></html>')
        elif self.path.startswith("/downloadpdfgenericmime"):
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Disposition",
                             "attachment; filename='test.pdf'")
            self.end_headers()
        elif self.path.startswith("/downloadpdf"):
            self.send_response(200)
            self.send_header("Content-Type", "application/pdf")
            self.send_header("Content-Disposition",
                             "attachment; filename='test.pdf'")
            self.end_headers()
        elif self.path.startswith("/basicauth"):
            login = "user"
            password = "pass"
            if "Authorization" in self.headers:
                header = self.headers.get("Authorization")
                credentials = str(b64decode(header[len("Basic "):])).split(":")
                if credentials[0] == login and credentials[1] == password:
                    self.send_response(200)
                    self.send_html("Authentication Successful !")
                else:
                    self.send_auth_request()
            else:
                self.send_auth_request()
        elif self.path.startswith("/media/"):
            self.send_response(200)
            permissions = self.path[len("/media/"):]
            self.send_html(
                "<script>navigator.webkitGetUserMedia("
                "{video: " + ("true" if "v" in permissions else "false") +
                ", audio: " + ("true" if "a" in permissions else "false") +
                "}, function() { location.href = '/test1' } " +
                ", function() { location.href = '/test2' })</script>"
            )
        elif self.path == "/favicon":
            self.send_response(200)
            html = '<html><head><link rel="icon" type="image/png" '
            html += 'href="/assets/icon1.png"></head>'
            html += '<body>favicon</body></html>'
            self.send_html(html)
        elif self.path == "/changingfavicon":
            self.send_response(200)
            html = '<html><head><link id="favicon" rel="shortcut icon" '
            html += 'type="image/png" href="icon0.png"></head><body><script>'
            html += 'var i = 0; window.setInterval(function() {'
            html += 'document.getElementById("favicon").href = ++i + '
            html += '".png"; }, 1000);</script></body></html>'
            self.send_html(html)
        elif self.path == "/changingtitle":
            self.send_response(200)
            html = '<html><head><title>title0</title></head><body><script>'
            html += 'var i = 0; window.setInterval(function() { '
            html += 'document.title = "title" + ++i; }, 500);</script></body>'
            html += '</html>'
            self.send_html(html)
        elif self.path == "/pushstate":
            self.send_response(200)
            html = '<html><head><title>push state</title></head>'
            html += '<body style="margin: 0"><a id="link">'
            html += '<div style="height: 100%"></div></a><script>'
            html += 'document.getElementById("link").addEventListener("click",'
            html += ' function(e) { document.title = "state pushed"; '
            html += 'history.pushState(null, null, "/statepushed"); });'
            html += '</script></body></html>'
            self.send_html(html)
        elif self.path == "/super":
            self.send_response(200)
            html = '<html><body><div style="position: fixed; top: 50%; left: '
            html += '50%; transform: translate(-50%, -50%); font-size: 500%">'
            html += 'Supercalifragilisticexpialidocious</div></body></html>'
            self.send_html(html)
        elif self.path == "/redirect-no-title-header":
            self.send_response(301)
            self.send_header("Location", "/redirect-destination")
            self.end_headers()
        elif self.path == "/redirect-no-title-js":
            self.send_response(200)
            html = '<html><body><script type="text/javascript">'
            html += 'window.location.href = "/redirect-destination"'
            html += '</script></body></html>'
            self.send_html(html)
        elif self.path == "/redirect-destination":
            self.send_response(200)
            html = '<html><body><p>redirect-destination</p></body></html>'
            self.send_html(html)
        elif self.path == "/js-alert-dialog":
            self.send_response(200)
            html = '<html><body><script type="text/javascript">'
            html += 'window.onload = function() {'
            html += '  window.alert("Alert Dialog")'
            html += '} </script></body></html>'
            self.send_html(html)
        elif self.path == "/js-before-unload-dialog":
            self.send_response(200)
            html = '<html><body><script type="text/javascript">'
            html += 'window.onbeforeunload = function(e) {'
            html += '  var dialogText = "Dialog text here";'
            html += '  e.returnValue = dialogText;'
            html += '  return dialogText;'
            html += '}; </script></body></html>'
            self.send_html(html)
        elif self.path == "/js-confirm-dialog":
            self.send_response(200)
            html = '<html><body><script type="text/javascript">'
            html += 'window.onload = function() {'
            html += '  if (window.confirm("Confirm Dialog") == true) {'
            html += '    document.title = "OK" } '
            html += '  else { document.title = "CANCEL" }'
            html += '} </script></body></html>'
            self.send_html(html)
        elif self.path == "/js-prompt-dialog":
            self.send_response(200)
            html = '<html><body><script type="text/javascript">'
            html += 'window.onload = function() {'
            html += '  var result = window.prompt("Prompt Dialog", "Default");'
            html += '  if (result != null) { document.title = result; } '
            html += '  else { document.title = "CANCEL" }'
            html += '} </script></body></html>'
            self.send_html(html)
        else:
            self.send_error(404)

    def log_message(self, format, *args):
        logger.info(format % args)

    def log_error(self, format, *args):
        logger.error(format % args)


class HTTPServerInAThread(object):

    """
    A simple custom HTTP server run in a separate thread.
    """
    def set_suggestions_data(self, data):
        self.handler.suggestions_data = data

    def __init__(self):
        # port == 0 will assign a random free port
        self.handler = HTTPRequestHandler
        self.server = http.HTTPServer(("", 0), self.handler)
        self.server.allow_reuse_address = True
        self.server_thread = threading.Thread(target=self.server.serve_forever)
        self.server_thread.start()
        logging.info("now serving on port {}".format(self.server.server_port))

    def cleanup(self):
        self.server.shutdown()
        self.server.server_close()
        self.server_thread.join()

    @property
    def port(self):
        return self.server.server_port


__all__ = ["HTTPServerInAThread"]

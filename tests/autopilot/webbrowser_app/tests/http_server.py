# -*- coding: utf-8 -*-
#
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

import http.server as http
import logging
import threading
import time

logger = logging.getLogger(__name__)


class HTTPRequestHandler(http.BaseHTTPRequestHandler):

    """
    A custom HTTP request handler that serves GET resources.
    """

    def make_html(self, title, body):
        html = "<html><title>{}</title><body>{}</body></html>"
        return html.format(title, body)

    def send_html(self, html):
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        self.wfile.write(html.encode())

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
        elif self.path == "/selection":
            self.send_response(200)
            html = '<html><body style="margin: 10%">'
            html += '<div style="position: absolute; width: 50%; height: 50%; '
            html += 'top: 25%; left: 25%"></div></body></html>'
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

    def __init__(self):
        # port == 0 will assign a random free port
        self.server = http.HTTPServer(("", 0), HTTPRequestHandler)
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

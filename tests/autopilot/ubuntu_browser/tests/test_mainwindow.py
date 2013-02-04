# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Tests for the Browser"""

from __future__ import absolute_import

from testtools.matchers import Equals
from autopilot.matchers import Eventually

from ubuntu_browser.tests import BrowserTestCase, ChromelessBrowserTestCase

import unittest
import time
import os
from os import path
import tempfile


class TestMainWindowMixin(object):

    def setUp(self):
        super(TestMainWindowMixin, self).setUp()
        # This is needed to wait for the application to start.
        # In the testfarm, the application may take some time to show up.
        self.assertThat(self.main_window.get_qml_view().visible, Eventually(Equals(True)))

    def tearDown(self):
        super(TestMainWindowMixin, self).tearDown()

    def swipe_chrome_up(self, distance):
        view = self.main_window.get_qml_view()
        x_line = view.x + view.width * 0.5
        start_y = view.y + view.height - 1
        stop_y = start_y - distance
        self.pointing_device.drag(x_line, start_y, x_line, stop_y)

    def swipe_chrome_down(self, distance):
        view = self.main_window.get_qml_view()
        x_line = view.x + view.width * 0.5
        start_y = self.main_window.get_chrome().globalRect[1]
        stop_y = start_y + distance
        self.pointing_device.drag(x_line, start_y, x_line, stop_y)

    def reveal_chrome(self):
        self.swipe_chrome_up(self.main_window.get_chrome().height)

    def hide_chrome(self):
        self.swipe_chrome_down(self.main_window.get_chrome().height)


class TestMainWindow(BrowserTestCase, TestMainWindowMixin):

    """Tests the main browser features"""

    def test_reveal_chrome(self):
        view = self.main_window.get_qml_view()
        chrome = self.main_window.get_chrome()
        self.assertThat(view.height, Equals(chrome.globalRect[1] - view.y))
        self.reveal_chrome()
        self.assertThat(lambda: chrome.globalRect[1], Eventually(Equals(view.y + view.height - chrome.height)))

    def test_reveal_chrome_with_partial_swipe(self):
        view = self.main_window.get_qml_view()
        chrome = self.main_window.get_chrome()
        self.assertThat(view.height, Equals(chrome.globalRect[1] - view.y))
        self.swipe_chrome_up(10)
        self.assertThat(lambda: chrome.globalRect[1], Eventually(Equals(view.y + view.height - chrome.height)))

    def test_reveal_chrome_with_long_swipe(self):
        view = self.main_window.get_qml_view()
        chrome = self.main_window.get_chrome()
        self.assertThat(view.height, Equals(chrome.globalRect[1] - view.y))
        self.swipe_chrome_up(chrome.height * 2)
        self.assertThat(lambda: chrome.globalRect[1], Eventually(Equals(view.y + view.height - chrome.height)))

    def test_hide_chrome(self):
        view = self.main_window.get_qml_view()
        chrome = self.main_window.get_chrome()
        self.reveal_chrome()
        self.hide_chrome()
        self.assertThat(lambda: chrome.globalRect[1], Eventually(Equals(view.y + view.height)))

    def test_hide_chrome_with_partial_swipe(self):
        view = self.main_window.get_qml_view()
        chrome = self.main_window.get_chrome()
        self.reveal_chrome()
        self.swipe_chrome_down(10)
        self.assertThat(lambda: chrome.globalRect[1], Eventually(Equals(view.y + view.height)))

    def test_hide_chrome_with_long_swipe(self):
        view = self.main_window.get_qml_view()
        chrome = self.main_window.get_chrome()
        self.reveal_chrome()
        self.swipe_chrome_down(chrome.height * 2)
        self.assertThat(lambda: chrome.globalRect[1], Eventually(Equals(view.y + view.height)))

    def test_unfocus_chrome_hides_it(self):
        view = self.main_window.get_qml_view()
        chrome = self.main_window.get_chrome()
        webview = self.main_window.get_web_view()
        self.reveal_chrome()
        self.pointing_device.move_to_object(webview)
        self.pointing_device.click()
        self.assertThat(lambda: chrome.globalRect[1], Eventually(Equals(view.y + view.height)))

    def test_open_website(self):
        self.reveal_chrome()
        address_bar = self.main_window.get_address_bar()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()
        address_bar_clear_button = self.main_window.get_address_bar_clear_button()
        self.pointing_device.move_to_object(address_bar_clear_button)
        self.pointing_device.click()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()

        self.keyboard.type("http://www.canonical.com", delay=0.001)
        self.keyboard.press("Enter")

        web_view = self.main_window.get_web_view()
        self.assertThat(web_view.url, Eventually(Equals("http://www.canonical.com/")))

    def test_title(self):
        fd, path = tempfile.mkstemp(suffix=".html", text=True)
        os.write(fd, "<html><title>Alice in Wonderland</title><body><p>Lorem ipsum dolor sit amet.</p></body></html>")
        os.close(fd)

        self.reveal_chrome()
        address_bar = self.main_window.get_address_bar()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()
        address_bar_clear_button = self.main_window.get_address_bar_clear_button()
        self.pointing_device.move_to_object(address_bar_clear_button)
        self.pointing_device.click()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()
        self.keyboard.type("file://" + path, delay=0.001)
        self.keyboard.press("Enter")

        window = self.main_window.get_qml_view()
        self.assertThat(window.title, Eventually(Equals("Alice in Wonderland - Ubuntu Web Browser")))

        os.remove(path)


class TestMainWindowChromeless(ChromelessBrowserTestCase, TestMainWindowMixin):

    """Tests the main browser features when run in chromeless mode."""

    def test_chrome_is_not_loaded(self):
        self.assertThat(self.main_window.get_chrome(), Equals(None))


# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Tests for the Browser"""

from __future__ import absolute_import

from testtools.matchers import Equals, NotEquals, GreaterThan
from autopilot.matchers import Eventually

from kalossi_browser.tests import BrowserTestCase

import unittest
import time
import os
from os import path

class TestMainWindow(BrowserTestCase):
    """Tests the main browser features"""

    """ This is needed to wait for the application to start.
        In the testfarm, the application may take some time to show up."""
    def setUp(self):
        super(TestMainWindow, self).setUp()
        self.assertThat(self.main_window.get_qml_view().visible, Eventually(Equals(True)))

    def tearDown(self):
        super(TestMainWindow, self).tearDown()

    """Test opening a website"""
    def test_open_website(self):
        address_bar = self.main_window.get_address_bar()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()
        address_bar_clear_button = self.main_window.get_address_bar_clear_button()
        self.pointing_device.move_to_object(address_bar_clear_button)
        self.pointing_device.click()
        self.pointing_device.move_to_object(address_bar)
        self.pointing_device.click()

        self.keyboard.type("http://www.canonical.com")
        self.keyboard.press("Enter")

        web_view = self.main_window.get_web_view()
        self.assertThat(web_view.url, Eventually(Equals("http://www.canonical.com/")))

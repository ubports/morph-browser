# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License version 3, as
# published by the Free Software Foundation.

from __future__ import absolute_import

from testtools.matchers import Equals, NotEquals

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase


class WebappContainerChromeSetupTestCase(
        WebappContainerTestCaseWithLocalContentBase):

    def test_container_does_not_load_with_no_webapp_and_url(self):
        self.ARGS = ['--webapp']
        self.launch_webcontainer_app()
        self.assertThat(self.get_webcontainer_proxy(), Equals(None))

    def test_default_to_chromeless(self):
        self.ARGS = ['']
        self.launch_webcontainer_app_with_local_http_server()
        self.assertThat(self.get_webcontainer_proxy(), NotEquals(None))
        self.assertThat(self.get_webcontainer_webview().chromeless,
                        Equals(True))

    def test_enable_chrome_back_forward(self):
        self.ARGS = ['--enable-back-forward']
        self.launch_webcontainer_app_with_local_http_server()
        self.assertThat(self.get_webcontainer_proxy(), NotEquals(None))
        self.assertThat(self.get_webcontainer_webview().chromeless,
                        Equals(False))
        panel = self.get_webcontainer_panel()
        self.assertThat(panel.backForwardButtonsVisible,
                        Equals(True))

    def test_enable_chrome_address_bar(self):
        self.ARGS = ['--enable-addressbar']
        self.launch_webcontainer_app_with_local_http_server()
        self.assertThat(self.get_webcontainer_proxy(), NotEquals(None))
        self.assertThat(self.get_webcontainer_webview().chromeless,
                        Equals(False))
        self.assertThat(self.get_webcontainer_panel().addressBarVisible,
                        Equals(True))

# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License version 3, as published
# by the Free Software Foundation.

from __future__ import absolute_import

import time

from testtools.matchers import Contains, Equals, NotEquals
from autopilot.matchers import Eventually

from webapp_container.tests import WebappContainerTestCaseBase, WebappContainerTestCaseWithLocalContentBase

class WebappContainerAppLaunchTestCase(WebappContainerTestCaseWithLocalContentBase):

    def setUp(self):
        super(WebappContainerAppLaunchTestCase, self).setUp()

    def test_containerDoesNotLoadWithNoWebappNameAndUrl(self):
        self.ARGS = ['--webapp']
        self.launch_webcontainer_app()
        self.assertThat(self.get_webcontainer_proxy(), Equals(None));

    def test_loadsWithUrl(self):
        self.ARGS = ['']
        self.launch_webcontainer_app_with_local_http_server()
        self.assertThat(self.get_webcontainer_proxy(), NotEquals(None));
        self.assertThat(self.get_webcontainer_window().url, Equals(self.url));

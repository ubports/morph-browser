# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License version 3, as
# published by the Free Software Foundation.

from __future__ import absolute_import

from testtools.matchers import Equals, NotEquals

from webapp_container.tests import WebappContainerTestCaseWithLocalContentBase


class WebappContainerAppLaunchTestCase(
        WebappContainerTestCaseWithLocalContentBase):

    def setUp(self):
        super(WebappContainerAppLaunchTestCase, self).setUp()

    def test_container_does_not_load_with_no_webapp_name_and_url(self):
        self.ARGS = ['--webapp']
        self.launch_webcontainer_app()
        self.assertThat(self.get_webcontainer_proxy(), Equals(None))

    def test_loads_with_url(self):
        self.ARGS = ['']
        self.launch_webcontainer_app_with_local_http_server()
        self.assertThat(self.get_webcontainer_proxy(), NotEquals(None))
        self.assertThat(self.get_webcontainer_window().url, Equals(self.url))

/*
 * Copyright 2014 Canonical Ltd.
 *
 * This file is part of webbrowser-app.
 *
 * webbrowser-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * webbrowser-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtTest 1.0
import "../../../src/app/UrlUtils.js" as UrlUtils

TestCase {
    name: "UrlUtils"

    function test_extractAuthority_data() {
        return [
            {url: "", authority: ""},
            {url: "http://example.org/", authority: "example.org"},
            {url: "http://www.example.org/", authority: "www.example.org"},
            {url: "http://www.example.org/foo/bar", authority: "www.example.org"},
            {url: "http://example.org:2442/foo", authority: "example.org:2442"},
            {url: "http://user:pwd@example.org/", authority: "user:pwd@example.org"},
            {url: "http://user:pwd@example.org:2442/", authority: "user:pwd@example.org:2442"},
            {url: "ftp://user:pwd@example.org:21/foo/bar", authority: "user:pwd@example.org:21"}
        ]
    }

    function test_extractAuthority(data) {
        compare(UrlUtils.extractAuthority(data.url), data.authority)
    }

    function test_extractHost_data() {
        return [
            {url: "http://example.org/", host: "example.org"},
            {url: "http://www.example.org/", host: "www.example.org"},
            {url: "http://www.example.org/foo/bar", host: "www.example.org"},
            {url: "http://example.org:2442/foo", host: "example.org"},
            {url: "http://user:pwd@example.org/", host: "example.org"},
            {url: "http://user:pwd@example.org:2442/", host: "example.org"},
            {url: "ftp://user:pwd@example.org:21/foo/bar", host: "example.org"}
        ]
    }

    function test_extractHost(data) {
        compare(UrlUtils.extractHost(data.url), data.host)
    }

    function test_removeScheme_data() {
        return [
            {url: "http://example.org/", removed: "example.org/"},
            {url: "file://user:pwd@example.org:2442/", removed: "user:pwd@example.org:2442/"},
            {url: "file:///home/foo/bar.txt", removed: "/home/foo/bar.txt"},
            {url: "ht+tp://www.example.org/", removed: "www.example.org/"},
            {url: "www.example.org", removed: "www.example.org"},
        ]
    }

    function test_removeScheme(data) {
        compare(UrlUtils.removeScheme(data.url), data.removed)
    }

    function test_looksLikeAUrl_data() {
        return [
            {url: "", looksLike: false},
            {url: "http://example.org/", looksLike: true},
            {url: "example.org", looksLike: true},
            {url: "http://www.example.org?q=foo bar", looksLike: false},
            {url: "about:blank", looksLike: true},
            {url: "file:///usr/foo/bar", looksLike: true},
            {url: "hello://my/name/is/", looksLike: true},
            {url: "192.168.1.0", looksLike: true}
        ]
    }

    function test_looksLikeAUrl(data) {
        compare(UrlUtils.looksLikeAUrl(data.url), data.looksLike)
    }

    function test_fixUrl_data() {
        return [
            {url: "About:BLANK", fixed: "about:blank"},
            {url: "/usr/bin/", fixed: "file:///usr/bin/"},
            {url: "example.org", fixed: "http://example.org"}
        ]
    }

    function test_fixUrl(data) {
        compare(UrlUtils.fixUrl(data.url), data.fixed)
    }
}

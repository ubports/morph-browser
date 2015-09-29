/*
 * Copyright 2014-2015 Canonical Ltd.
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

.pragma library

var overrides = [
    ["^https?:\/\/mail\.google\.com\/", "Mozilla/5.0 (Linux; Ubuntu 14.04 like Android 4.4) AppleWebKit/537.36 Chromium/35.0.1870.2 Mobile Safari"],
    ["^https?:\/\/(www|m)\.youtube\.com\/", "Mozilla/5.0 (Linux; Ubuntu 14.04 like Android 4.4;) AppleWebKit/537.36 Chromium/35.0.1870.2 Mobile Safari/537.36"], // http://pad.lv/1228415, http://pad.lv/1415107, http://pad.lv/1417258, http://pad.lv/1499394
    ["^http:\/\/chrome\.angrybirds\.com\/", "Mozilla/5.0 (Linux; Ubuntu 14.04 like Android 4.4;) AppleWebKit/537.36 Chrome/35.0.1870.2 Mobile Safari/537.36"], // http://pad.lv/1284158
    ["^https?:\/\/(\w+\.)*hsbc\.com\.br\/", "Mozilla/5.0 (Linux; Ubuntu 14.04 like Android 4.4;) AppleWebKit/537.36 Chrome/35.0.1870.2 Mobile Safari/537.36"], // http://pad.lv/1380657
    ["^http:\/\/(\w+\.)*espn\.(go\.)?com\/", "Mozilla/5.0 (Linux; Ubuntu 14.04 like Android 4.4;) AppleWebKit/537.36 Chrome/35.0.1870.2 Mobile Safari/537.36"], // http://pad.lv/1316259
];

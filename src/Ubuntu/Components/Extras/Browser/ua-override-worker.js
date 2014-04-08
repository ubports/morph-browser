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

var overrides = [];

oxide.onMessage = function(msg) {
    if ("overrides" in msg) {
        overrides = msg["overrides"];
    }
}

function getUAoverride(url) {
    for (var i = 0; i < overrides.length; i++) {
        var override = overrides[i];
        if (override[0].test(url)) {
            return override[1];
        }
    }
    return null;
}

exports.onBeforeSendHeaders = function(event) {
    var override = getUAoverride(event.url);
    if (override !== null) {
        event.setHeader("User-Agent", override);
        oxide.sendMessage({url: event.url, override: override});
    }
}

exports.onGetUserAgentOverride = function(data) {
    var override = getUAoverride(event.url);
    if (override !== null) {
        data.userAgentOverride = override;
    }
}

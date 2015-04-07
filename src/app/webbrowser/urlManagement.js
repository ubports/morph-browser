/*
 * Copyright 2015 Canonical Ltd.
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
'use strict';

function fixUrl(address) {
    var url = address;
    if (address.substr(0, 1) == "/") {
        url = "file://" + address;
    } else if (address.indexOf("://") == -1) {
        url = "http://" + address;
    }
    return url;
}

function looksLikeAUrl(address) {
    var terms = address.split(/\s/)
    if (terms.length > 1) {
        return false
    }
    if (address.substr(0, 1) == "/") {
        return true
    }
    if (address.match(/^https?:\/\//) ||
        address.match(/^file:\/\//) ||
        address.match(/^[a-z]+:\/\//)) {
        return true
    }
    if (address.split('/', 1)[0].match(/\.[a-zA-Z]{2,4}$/)) {
        return true
    }
    if (address.split('/', 1)[0].match(/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}/)) {
        return true
    }
    return false
}

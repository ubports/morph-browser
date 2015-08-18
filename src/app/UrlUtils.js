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

function removeScheme(url) {
    var authority = url.toString()
    var indexOfScheme = authority.indexOf("://")
    if (indexOfScheme !== -1) {
        authority = authority.slice(indexOfScheme + 3)
    }
    return authority
}

function extractAuthority(url) {
    var authority = removeScheme(url)
    var indexOfPath = authority.indexOf("/")
    if (indexOfPath !== -1) {
        authority = authority.slice(0, indexOfPath)
    }
    return authority
}

function extractHost(url) {
    var host = extractAuthority(url)
    var indexOfAt = host.indexOf("@")
    if (indexOfAt !== -1) {
        host = host.slice(indexOfAt + 1)
    }
    var indexOfColon = host.indexOf(":")
    if (indexOfColon !== -1) {
        host = host.slice(0, indexOfColon)
    }
    return host
}

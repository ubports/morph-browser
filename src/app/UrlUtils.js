/*
 * Copyright 2014 Canonical Ltd.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
/*jslint node: true */
'use strict';

function extractScheme(url) {
    var urlString = url.toString();
    return urlString.substring(0,urlString.indexOf(":"));
}

function removeScheme(url) {
    var rest = url.toString();
    var indexOfScheme = rest.indexOf(":");
    if (indexOfScheme !== -1) {
        rest = rest.slice(indexOfScheme + 1);

        if (rest.indexOf("//") === 0)
        {
            rest = rest.slice(2);
        }
    }
    return rest;
}

function schemeIs(url, expectedScheme) {
    return (extractScheme(url) === expectedScheme);
}

function hasCustomScheme(url) {

    switch (extractScheme(url)) {
     case 'http':
     case 'https':
     case 'file':
     case 'ftp':
     case 'data':
     case 'mailto':
       return false;
     default:
       return true;
   }
}

function extractAuthority(url) {
    var authority = removeScheme(url);
    var indexOfPath = authority.indexOf("/");
    if (indexOfPath !== -1) {
        authority = authority.slice(0, indexOfPath);
    }
    return authority;
}

function extractHost(url) {
    var host = extractAuthority(url);
    var indexOfAt = host.indexOf("@");
    if (indexOfAt !== -1) {
        host = host.slice(indexOfAt + 1);
    }
    var indexOfColon = host.indexOf(":");
    if (indexOfColon !== -1) {
        host = host.slice(0, indexOfColon);
    }
    return host;
}

function hostIs(url, expectedHost) {
    return (extractHost(url) === expectedHost);
}

function fixUrl(address) {
    var url = address;
    if (address.toLowerCase() === "about:blank") {
        return address.toLowerCase();
    } else if (address.match(/^data:/i)) {
        return "data:" + address.substr(5);
    } else if (address.substr(0, 1) === "/") {
        url = "file://" + address;
    } else if (address.indexOf("://") === -1) {
        url = "http://" + address;
    }
    return url;
}

function looksLikeAUrl(address) {
    if (address.match(/^data:/i)) {
        return true;
    }
    var terms = address.split(/\s/);
    if (terms.length > 1) {
        return false;
    }
    if (address.toLowerCase() === "about:blank") {
        return true;
    }
    if (address.substr(0, 1) === "/") {
        return true;
    }
    if (address.match(/^https?:\/\//i) ||
        address.match(/^file:\/\//i) ||
        address.match(/^[a-z]+:\/\//i)) {
        return true;
    }
    if (address.split('/', 1)[0].match(/\.[a-zA-Z]{2,}$/)) {
        return true;
    }
    if (address.split('/', 1)[0].match(/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}/)) {
        return true;
    }
    return false;
}

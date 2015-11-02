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

// ==UserScript==
// @include https://m.facebook.com/*
// ==/UserScript==

// Ensure that the facebook mobile site never shows its app banner, which
// suggests installing a native Android/iOS application based on naïve
// parsing of the UA string.

// The banner does not currently have any class or id that would make sure we
// can identify it easily. But we know that it does always appear just before
// the login form, so we find it that way.

var login = document.getElementsByClassName("mobile-login-form");
if (login.length === 1) {
    var appbanner = login[0].previousSibling;
    if (appbanner) {
        appbanner.parentNode.removeChild(appbanner);
    }
}

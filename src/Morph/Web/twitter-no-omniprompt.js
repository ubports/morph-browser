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

// ==UserScript==
// @include https://mobile.twitter.com/*
// ==/UserScript==

// Ensure that the twitter mobile site never shows its "omniprompt" header,
// which suggests installing a native Android/iOS application based on
// naïve parsing of the UA string.

if (document.body) {
    document.body.classList.add("no-omniprompt");
}

var androidPrompt = document.querySelector(".client-prompt");
if (androidPrompt) {
	androidPrompt.style.display = "none";
}
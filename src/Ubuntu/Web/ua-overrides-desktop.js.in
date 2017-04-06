/*
 * Copyright 2014-2017 Canonical Ltd.
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

// Note: when changing the value of this variable, all domains which
// use it must be carefully tested to ensure no regression.
var chrome_desktop_override = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/${CHROMIUM_VERSION} Chrome/${CHROMIUM_VERSION} Safari/537.36";

var overrides = [
    // Google calendar
    ["^https:\/\/calendar\.google\.com\/", chrome_desktop_override],
    ["^https:\/\/.+\.google\.com\/calendar\/", chrome_desktop_override],

    // Youtube (https://launchpad.net/bugs/1412880)
    ["^https:\/\/(www\.)?youtube\.com\/", chrome_desktop_override],

    // Google maps (https://launchpad.net/bugs/1503506, https://launchpad.net/bugs/1551649)
    ["^https:\/\/(www\.)?google\..+\/maps", chrome_desktop_override],

    // Gmail (https://launchpad.net/bugs/1452616)
    ["^https:\/\/mail\.google\.com\/", chrome_desktop_override],

    // Google docs (https://launchpad.net/bugs/1643386)
    ["^https:\/\/(docs|drive)\.google\.com\/", chrome_desktop_override],

    // Google plus (https://launchpad.net/bugs/1656310)
    ["^https:\/\/plus\.google\.com\/", chrome_desktop_override],

    // Google hangouts (https://launchpad.net/bugs/1565055)
    ["^https:\/\/hangouts\.google\.com\/", chrome_desktop_override],
    ["^https:\/\/talkgadget\.google\.com\/hangouts\/", chrome_desktop_override],
    ["^https:\/\/plus\.google\.com\/hangouts\/", chrome_desktop_override],

    // Google recaptcha (https://launchpad.net/bugs/1599146)
    ["^https:\/\/www\.google\.com\/recaptcha\/", chrome_desktop_override],

    // Google photos (https://launchpad.net/bugs/1665926)
    ["^https:\/\/photos\.google\.com\/", chrome_desktop_override],

    // (mobile) twitter (https://launchpad.net/bugs/1577834)
    ["^https:\/\/mobile\.twitter\.com\/", chrome_desktop_override],

    // meet.jit.si (https://launchpad.net/bugs/1635971)
    ["^https:\/\/meet\.jit\.si\/", chrome_desktop_override],

    // ESPN websites (https://launchpad.net/bugs/1637285)
    ["^https?:\/\/(.+\.)?espn(fc)?\.co(m|\.uk)\/", chrome_desktop_override],

    // Ebay (https://launchpad.net/bugs/1575780)
    ["^https?:\/\/(.+\.)?ebay\.(at|be|ca|ch|cn|co\.jp|co\.th|co\.uk|com|com\.au|com\.hk|com\.my|com\.sg|com\.tw|de|es|fr|ie|in|it|nl|ph|pl|se|vn)\/", chrome_desktop_override],

    // Dailymotion (https://launchpad.net/bugs/1662826)
    ["^http:\/\/www\.dailymotion\.com\/", chrome_desktop_override],

    // Dropbox (https://launchpad.net/bugs/1672804)
    ["^https:\/\/www\.dropbox\.com\/", chrome_desktop_override],

    // Facebook (https://launchpad.net/bugs/1677218)
    ["^https:\/\/www\.facebook\.com\/", chrome_desktop_override],
];

/*
 * Copyright 2013 Canonical Ltd.
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

// B2G’s list of overrides: https://hg.mozilla.org/mozilla-central/raw-file/tip/b2g/app/ua-update.json.in

// List of user agent string overrides in the form of an object.
// Each key is a domain name for which the default user agent string doesn’t
// work well enough. Values can either be a string (full override) or an array
// containing two values that are passed to the String.replace method (the
// first value may be either a string or a regular expression, the second value
// must be a string).

// Examples of valid entries:
//     "example.org": "full override"
//     "example.com": ["Ubuntu", "Ubuntu Edge"]
//     "google.com": [/mobi/i, "b"]

// The original list was initially built from the top 100 entries
// at http://www.alexa.com/topsites (2013-08-16), using Chrome on
// Android as a reference.

var overrides = {
    // Google+ is special, scroll doesn't work with an AppleWebkit personality
    "plus.google.com": ["Mobile", "Android; Mobile"],

    "google.com": [/Mobile\) WebKit\/[.0-9]*/, "Android 4.3) AppleWebKit Mobile Safari"],
    "google.co.in": [/Mobile\) WebKit\/[.0-9]*/, "Android 4.3) AppleWebKit Mobile Safari"],
    "google.de": [/Mobile\) WebKit\/[.0-9]*/, "Android 4.3) AppleWebKit Mobile Safari"],
    "google.co.uk": [/Mobile\) WebKit\/[.0-9]*/, "Android 4.3) AppleWebKit Mobile Safari"],
    "google.fr": [/Mobile\) WebKit\/[.0-9]*/, "Android 4.3) AppleWebKit Mobile Safari"],
    "google.com.br": [/Mobile\) WebKit\/[.0-9]*/, "Android 4.3) AppleWebKit Mobile Safari"],
    "google.co.jp": [/Mobile\) WebKit\/[.0-9]*/, "Android 4.3) AppleWebKit Mobile Safari"],
    "google.com.hk": [/Mobile\) WebKit\/[.0-9]*/, "Android 4.3) AppleWebKit Mobile Safari"],
    "google.ru": [/Mobile\) WebKit\/[.0-9]*/, "Android 4.3) AppleWebKit Mobile Safari"],
    "google.it": [/Mobile\) WebKit\/[.0-9]*/, "Android 4.3) AppleWebKit Mobile Safari"],
    "google.es": [/Mobile\) WebKit\/[.0-9]*/, "Android 4.3) AppleWebKit Mobile Safari"],
    "google.com.mx": [/Mobile\) WebKit\/[.0-9]*/, "Android 4.3) AppleWebKit Mobile Safari"],
    "google.ca": [/Mobile\) WebKit\/[.0-9]*/, "Android 4.3) AppleWebKit Mobile Safari"],
    "google.com.tr": [/Mobile\) WebKit\/[.0-9]*/, "Android 4.3) AppleWebKit Mobile Safari"],
    "google.com.au": [/Mobile\) WebKit\/[.0-9]*/, "Android 4.3) AppleWebKit Mobile Safari"],
    "google.pl": [/Mobile\) WebKit\/[.0-9]*/, "Android 4.3) AppleWebKit Mobile Safari"],

    "youtube.com": [/Mobile\) WebKit\/([.0-9]*)/, "Linux) WebKit/$1 (like Android 4.3) Ubuntu Mobile"],

    "twitter.com": ["Mobile)", "Mobile) Firefox"],

    // while this issue gets resolved (https://bugs.launchpad.net/ubuntu/+source/ubuntu-keyboard/+bug/1233207)
    "login.ubuntu.com": [/Mobile\) WebKit\/[.0-9]*/, "Android 4.3) AppleWebKit Mobile Safari"],

    "yahoo.com": ["Mobile", "Android; Mobile"],
    "baidu.com": ["Mobile", "Android; Mobile"],
    "qq.com": [/WebKit\/[.0-9]*/, "Apple$& Mobile"],
    "amazon.com": ["Mobile", "Android; Mobile"],
    "linkedin.com": ["Mobile", "Android; Mobile"],
    "blogspot.com": ["Mobile", "Android; Mobile"],
    "taobao.com": ["Mobile", "Android; Mobile"],
    "bing.com": ["Mobile", "Android; Mobile"],
    "yahoo.co.jp": ["Ubuntu", "Linux; Android 4; Galaxy Build/"],
    "yandex.ru": ["Mobile", "Android; Mobile"],
    "sina.com.cn": ["Mobile", "Android; Mobile"],
    "ebay.com": ["Mobile", "Android; Mobile"],
    "tumblr.com": ["Mobile", "Android; Mobile"],
    "msn.com": ["Mobile", "Android; Mobile"],
    "mail.ru": ["Ubuntu", "Linux; Android 4; Galaxy Build/"],
    "hao123.com": ["Mobile", "Android; Mobile"],
    "ask.com": ["Mobile", "Android; Mobile"],
    "blogger.com": ["Mobile", "Android; Mobile"],
    "imdb.com": ["Mobile", "Android; Mobile"],
    "amazon.co.jp": ["Mobile", "Android; Mobile"],
    "tmall.com": ["Mobile", "Android; Mobile"],
    "fc2.com": ["Mobile", "Android; Mobile"],
    "soso.com": ["Mobile", "Android; Mobile"],
    "delta-search.com": ["Mobile", "Android; Mobile"],
    "odnoklassniki.ru": ["Mobile", "Android; Mobile"],
    "alibaba.com": ["Mobile", "Android; Mobile"],
    "flickr.com": ["Mobile", "Android; Mobile"],
    "amazon.de": ["Mobile", "Android; Mobile"],
    "blogspot.in": ["Mobile", "Android; Mobile"],
    "ifeng.com": ["Mobile", "Android; Mobile"],
    "360.cn": ["Mobile", "Android; Mobile"],
    "youku.com": ["Mobile", "Android; Mobile"],
    "ebay.de": ["Mobile", "Android; Mobile"],
    "uol.com.br": ["Mobile", "Android; Mobile"],
    "aol.com": ["Mobile", "Android; Mobile"],
    "alipay.com": ["Mobile", "Android; Mobile"],
    "dailymotion.com": ["Mobile", "Android; Mobile Safari"],
    "amazon.co.uk": ["Mobile", "Android; Mobile"],
    "ebay.co.uk": ["Mobile", "Android; Mobile"],

    "facebook.com": [/Mobile\) WebKit\/([.0-9]*)/, "Linux) WebKit/$1 (like Android 4.3) AppleWebKit/$1 Ubuntu Mobile"],
    // Akamai serves images for Facebook
    "akamaihd.net": [/Mobile\) WebKit\/([.0-9]*)/, "Linux) WebKit/$1 (like Android 4.3) AppleWebKit/$1 Ubuntu Mobile"],

    "nytimes.com": ["Mobile", "Android; Mobile Safari"],

    // http://pad.lv/1223937
    "huffpost.com": ["Mobile)", "Mobile) Firefox"],
};

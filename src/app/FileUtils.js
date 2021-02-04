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
.pragma library
'use strict';

function formatBytes(bytes, decimals) {
    decimals = decimals ? decimals : 2
    if (bytes === 0) return '0 B';

    var k = 1000;
    var dm = decimals < 0 ? 0 : decimals;
    var sizes = ["B", "KB", "MB", "GB", "TB"];

    var i = Math.floor(Math.log(bytes) / Math.log(k));

    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

function getFilename(path) {
    return path.replace(/^.*[\\\/]/, '')
}


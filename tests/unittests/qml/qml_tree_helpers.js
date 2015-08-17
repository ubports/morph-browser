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

// Given the naming convention in QML for class names, we should
// never have a class name with underscores in it, so the following
// should be a safe way to remove the rest of the extra metatype
// information produced by converting QML objects to strings.
function qmlType(item) {
    var itemType = String(item).split("_")
    return itemType.length > 0 ? itemType[0] : String(item)
}

function findChildrenByType(item, type, list) {
    list = list || []
    if (qmlType(item) === type) list.push(item)
    for (var i in item.children) {
        findChildrenByType(item.children[i], type, list)
    }
    return list
}

function findAncestorByType(item, type) {
    while (item.parent) {
        if (qmlType(item.parent) === type) return item.parent
        item = item.parent
    }
    return null
}

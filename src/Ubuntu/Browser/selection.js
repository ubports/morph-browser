/*
 * Copyright 2013 Canonical Ltd.
 *
 * This file is part of ubuntu-browser.
 *
 * ubuntu-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * ubuntu-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

function elementContainedInBox(element, box) {
    var rect = element.getBoundingClientRect();
    return ((box.left <= rect.left) && (box.right >= rect.right) &&
            (box.top <= rect.top) && (box.bottom >= rect.bottom));
}

function getImgFullUri(uri) {
    if ((uri.slice(0, 7) === 'http://') ||
        (uri.slice(0, 8) === 'https://') ||
        (uri.slice(0, 7) === 'file://')) {
        return uri;
    } else if (uri.slice(0, 1) === '/') {
        var docuri = document.documentURI;
        var firstcolon = docuri.indexOf('://');
        var protocol = 'http://';
        if (firstcolon !== -1) {
            protocol = docuri.slice(0, firstcolon + 3);
        }
        return protocol + document.domain + uri;
    } else {
        var base = document.baseURI;
        var lastslash = base.lastIndexOf('/');
        if (lastslash === -1) {
            return base + '/' + uri;
        } else {
            return base.slice(0, lastslash + 1) + uri;
        }
    }
}

function getSelectedData(element) {
    var data = element.getBoundingClientRect();
    data.html = element.outerHTML;
    data.text = element.textContent;
    var images = [];
    if (element.tagName.toLowerCase() === 'img') {
        images.push(getImgFullUri(element.getAttribute('src')));
    } else {
        var imgs = element.getElementsByTagName('img');
        for (var i = 0; i < imgs.length; i++) {
            images.push(getImgFullUri(imgs[i].getAttribute('src')));
        }
    }
    if (images.length > 0) {
        data.images = images;
    }
    return data;
}

function adjustSelection(selection) {
    var centerX = (selection.left + selection.right) / 2;
    var centerY = (selection.top + selection.bottom) / 2;
    var element = document.elementFromPoint(centerX, centerY);
    var parent = element;
    while (elementContainedInBox(parent, selection)) {
        parent = parent.parentNode;
    }
    element = parent;
    return getSelectedData(element);
}

function distance(touch1, touch2) {
    return Math.sqrt(Math.pow(touch2.clientX - touch1.clientX, 2) +
                     Math.pow(touch2.clientY - touch1.clientY, 2));
}

navigator.qt.onmessage = function(message) {
    var data = null;
    try {
        data = JSON.parse(message.data);
    } catch (error) {
        return;
    }
    if ('query' in data) {
        if (data.query === 'adjustselection') {
            var selection = adjustSelection(data);
            selection.event = 'selectionadjusted';
            navigator.qt.postMessage(JSON.stringify(selection));
        }
    }
}

function longPressDetected(x, y) {
    var element = document.elementFromPoint(x, y);
    var data = getSelectedData(element);
    data.event = 'longpress';
    navigator.qt.postMessage(JSON.stringify(data));
}

function clearLongpressTimeout() {
    clearTimeout(this.longpressObserver);
    delete this.longpressObserver;
    delete this.currentTouch;
}

var doc = document.documentElement;

doc.addEventListener('touchstart', function(event) {
    this.currentTouch = event.touches[0];
    this.longpressObserver = setTimeout(longPressDetected, 800, this.currentTouch.clientX, this.currentTouch.clientY);
});

doc.addEventListener('touchend', function(event) {
    clearLongpressTimeout();
});

doc.addEventListener('touchmove', function(event) {
      if (distance(event.changedTouches[0], this.currentTouch) > 3) {
          clearLongpressTimeout();
      }
});

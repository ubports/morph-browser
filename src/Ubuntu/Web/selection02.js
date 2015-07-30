/*
 * Copyright 2013-2015 Canonical Ltd.
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

function elementContainedInBox(element, box) {
    var rect = element.getBoundingClientRect();
    return ((box.left <= rect.left) && (box.right >= rect.right) &&
            (box.top <= rect.top) && (box.bottom >= rect.bottom));
}

function getImgFullUri(uri) {
    if ((uri.slice(0, 7) === 'http://') ||
        (uri.slice(0, 8) === 'https://') ||
        (uri.slice(0, 7) === 'file://') ||
        (uri.slice(0, 5) === 'data:')) {
        return uri;
    } else if (uri.slice(0, 1) === '/') {
        var docuri = document.documentURI;
        var firstcolon = docuri.indexOf('://');
        var protocol = 'http://';
        if (firstcolon !== -1) {
            protocol = docuri.slice(0, firstcolon + 3);
        }
        if (uri.slice(0, 2) === '//') {
            // URLs beginning with a // should just inherit the protocol
            // from the current page
            return protocol + uri.slice(2);
        } else {
            return protocol + document.domain + uri;
        }
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
    var node = element;
    var data = new Object;

    var nodeName = node.nodeName.toLowerCase();
    if (nodeName === 'img') {
        data.img = getImgFullUri(node.getAttribute('src'));
    } else if (nodeName === 'a') {
        data.href = node.href;
        data.title = node.title;
    }

    // If the parent tag is a hyperlink, we want it too.
    var parent = node.parentNode;
    if ((nodeName !== 'a') && parent && (parent.nodeName.toLowerCase() === 'a')) {
        data.href = parent.href;
        data.title = parent.title;
        node = parent;
    }

    var boundingRect = node.getBoundingClientRect();
    data.left = boundingRect.left;
    data.top = boundingRect.top;
    data.width = boundingRect.width;
    data.height = boundingRect.height;

    node = node.cloneNode(true);
    // filter out script nodes
    var scripts = node.getElementsByTagName('script');
    while (scripts.length > 0) {
        var scriptNode = scripts[0];
        if (scriptNode.parentNode) {
            scriptNode.parentNode.removeChild(scriptNode);
        }
    }
    data.html = node.outerHTML;
    data.nodeName = node.nodeName.toLowerCase();
    // FIXME: extract the text and images in the order they appear in the block,
    // so that this order is respected when the data is pushed to the clipboard.
    data.text = node.textContent;
    var images = [];
    var imgs = node.getElementsByTagName('img');
    for (var i = 0; i < imgs.length; i++) {
        images.push(getImgFullUri(imgs[i].getAttribute('src')));
    }
    if (images.length > 0) {
        data.images = images;
    }

    return data;
}

function adjustSelection(selection) {
    // FIXME: allow selecting two consecutive blocks, instead of
    // interpolating to the containing block.
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

document.defaultView.addEventListener('scroll', function(event) {
    oxide.sendMessage('scroll', {});
});

function setScaleParameters(data) {
    var w = document.defaultView;
    data['dpr'] = w.devicePixelRatio;
    data['innerWidth'] = w.innerWidth;
    data['outerWidth'] = w.outerWidth;
    data['innerHeight'] = w.innerHeight;
    data['outerHeight'] = w.outerHeight;
}

oxide.addMessageHandler("createselection", function(msg) {
    var element = document.elementFromPoint(msg.args.x, msg.args.y);
    var data = getSelectedData(element);
    setScaleParameters(data);
    msg.reply(data);
});

oxide.addMessageHandler("adjustselection", function (msg) {
    var w = document.defaultView;
    var scaleX = w.outerWidth / w.innerWidth * w.devicePixelRatio;
    var scaleY = w.outerHeight / w.innerHeight * w.devicePixelRatio;
    var selection = new Object;
    selection.left = msg.args.x / scaleX;
    selection.right = selection.left + msg.args.width / scaleX;
    selection.top = msg.args.y / scaleY;
    selection.bottom = selection.top + msg.args.height / scaleY;
    var adjusted = adjustSelection(selection);
    setScaleParameters(adjusted);
    msg.reply(adjusted);
});

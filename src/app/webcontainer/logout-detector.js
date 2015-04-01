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

oxide.sendMessage('domChanged', 'Some message');

var MutationObserver = window.MutationObserver || window.WebKitMutationObserver;

var observer = new MutationObserver(function(mutations) {
    var addnodes = []
    mutations.forEach(function(mutation) {
        for (var i in mutation.addedNodes) {
            addnodes.push(mutation.addedNodes[i].className)
        }
    });

    oxide.sendMessage('domChanged', JSON.stringify(addnodes))
});
observer.observe(document.body, {childList: true, subtree: true });


oxide.addMessageHandler("evaluateSelectors", function(msg) {
    var selectors = msg.args.selectors;
    console.log("Evaluating selectors: " + selectors);
    var match = document.querySelector(selectors);
    msg.reply({result: (match !== null)});
});

/*
 * Copyright 2015 Canonical Ltd.
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

(function() {
    function detectThemeColorMetaInformation() {
        var theme_color_meta =
                document.head.querySelector('meta[name="theme-color"]');
        if (theme_color_meta) {
            oxide.sendMessage(
                'webapp-specific-page-metadata-detected', {
                    type: 'theme-color',
                    baseurl: document.location.href,
                    theme_color: theme_color_meta.getAttribute('content')
                });
            return true;
        }
        return false;
    }
    function detectManifestMetaInformation() {
        var manifest = document.head.querySelector('link[rel="manifest"]');

        if (manifest && manifest.getAttribute('href')) {
            oxide.sendMessage(
                'webapp-specific-page-metadata-detected', {
                    type: 'manifest',
                    baseurl: document.location.href,
                    manifest: manifest.href
                });
            return true;
        }

        return false;
    }

    function extractWebAppMetaInfo() {
        var detectors = [detectThemeColorMetaInformation, detectManifestMetaInformation]
        for (var i in detectors) {
            if (detectors[i]()) {
                break;
            }
        }
    }
    extractWebAppMetaInfo();

    var MutationObserver = window.MutationObserver || window.WebKitMutationObserver;
    var observer = new MutationObserver(function(mutations) {
        extractWebAppMetaInfo();
    });
    observer.observe(document, {childList: true, subtree: true, attributes: true });
})();

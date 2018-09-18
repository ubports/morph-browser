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

function highlightTerms(text, terms) {
    var termsRe
    var highlight = '<font color="#752571">$&</font>'
    var searchTerms = []

    function escapeTerm(term) {
        // Escape special characters in a search term
        // (a simpler version of preg_quote).
        return term.replace(/[().?+|*^$]/g, '\\$&')
    }

    function setSearchTerms(terms) {
        searchTerms = terms
        termsRe = new RegExp(terms.map(escapeTerm).join('|'), 'ig')
    }

    // Highlight the matching terms in a case-insensitive manner
    if (text && text.toString()) {
        if (searchTerms !== terms) setSearchTerms(terms)
        if (searchTerms.length == 0) return text
        var highlighted = text.toString().replace(termsRe, highlight)
        highlighted = highlighted.replace(new RegExp('&', 'g'), '&amp;')
        highlighted = '<html>' + highlighted + '</html>'
        return highlighted
    } else {
        return ""
    }
}

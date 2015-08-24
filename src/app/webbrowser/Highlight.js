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

function highlightTerms(text, terms) {
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

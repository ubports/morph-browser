'use strict'

function fixUrl(address) {
    var url = address
    if (address.substr(0, 1) == "/") {
        url = "file://" + address
    } else if (address.indexOf("://") == -1) {
        url = "http://" + address
    }
    return url
}


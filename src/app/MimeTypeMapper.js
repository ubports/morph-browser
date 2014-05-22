function mimeTypeToContentType(mimeType) {
    if(mimeType.search("image/") === 0) {
        return ContentType.Pictures;
    } else if(mimeType.search("audio/") === 0) {
        return ContentType.Music;
    } else if(mimeType.search("text/x-vcard") === 0) {
        return ContentType.Contacts;
    } else if(mimeType.search("text/") === 0) {
        return ContentType.Documents;
    } else {
        return ContentType.All;
    }
}

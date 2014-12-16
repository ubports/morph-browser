/*
 * Copyright 2014 Canonical Ltd.
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

// Constructed from /etc/mime.types
function filenameToContentType(filename) {
    var filenameParts = filename.split(".");
    if(filenameParts.length === 1 || (filenameParts[0] === "" && filenameParts.length === 2)) {
        return ContentType.Unknown;
    }
    var ext = filenameParts.pop().toLowerCase();
    switch(ext) {
        case "art":
        case "bmp":
        case "cdr":
        case "cdt":
        case "cpt":
        case "cr2":
        case "crw":
        case "djv":
        case "djvu":
        case "erf":
        case "gif":
        case "ico":
        case "ief":
        case "jng":
        case "jp2":
        case "jpe":
        case "jpeg":
        case "jpf":
        case "jpg":
        case "jpg2":
        case "jpm":
        case "jpx":
        case "nef":
        case "orf":
        case "pat":
        case "pbm":
        case "pcx":
        case "pgm":
        case "png":
        case "pnm":
        case "ppm":
        case "psd":
        case "ras":
        case "rgb":
        case "svg":
        case "svgz":
        case "tif":
        case "tiff":
        case "wbmp":
        case "xbm":
        case "xpm":
        case "xwd":
            return ContentType.Pictures;
        case "3gp":
        case "asf":
        case "asx":
        case "avi":
        case "axv":
        case "dif":
        case "dl":
        case "dv":
        case "fli":
        case "flv":
        case "gl":
        case "lsf":
        case "lsx":
        case "m4v":
        case "mkv":
        case "mng":
        case "mov":
        case "movie":
        case "mp4":
        case "mpe":
        case "mpeg":
        case "mpg":
        case "mpv":
        case "mxu":
        case "ogv":
        case "qt":
        case "ts":
        case "webm":
        case "wm":
        case "wmv":
        case "wmx":
        case "wvx":
            return ContentType.Videos;
        case "aif":
        case "aifc":
        case "aiff":
        case "amr":
        case "au":
        case "awb":
        case "axa":
        case "csd":
        case "flac":
        case "gsm":
        case "kar":
        case "m3u":
        case "m4a":
        case "mid":
        case "midi":
        case "mp2":
        case "mp3":
        case "mpega":
        case "mpga":
        case "oga":
        case "ogg":
        case "opus":
        case "orc":
        case "pls":
        case "ra":
        case "ram":
        case "rm":
        case "sco":
        case "sd2":
        case "sid":
        case "snd":
        case "spx":
        case "wav":
        case "wax":
        case "wma":
            return ContentType.Music;
        case "vcard":
        case "vcf":
            return ContentType.Contacts;
        case "323":
        case "appcache":
        case "asc":
        case "bib":
        case "boo":
        case "brf":
        case "c":
        case "c++":
        case "cc":
        case "cls":
        case "cpp":
        case "csh":
        case "css":
        case "csv":
        case "cxx":
        case "d":
        case "diff":
        case "etx":
        case "gcd":
        case "h":
        case "hh":
        case "h++":
        case "hpp":
        case "hs":
        case "htc":
        case "htm":
        case "html":
        case "hxx":
        case "ics":
        case "icz":
        case "jad":
        case "java":
        case "lhs":
        case "ltx":
        case "ly":
        case "mml":
        case "moc":
        case "p":
        case "pas":
        case "patch":
        case "pdf":
        case "pl":
        case "pm":
        case "pot":
        case "py":
        case "rtx":
        case "scala":
        case "sct":
        case "sfv":
        case "sh":
        case "shtml":
        case "srt":
        case "sty":
        case "tcl":
        case "tex":
        case "text":
        case "tk":
        case "tm":
        case "tsv":
        case "ttl":
        case "txt":
        case "uls":
        case "vcs":
        case "wml":
        case "wmls":
        case "wsc":
            return ContentType.Documents;
        case "epub":
        case "mobi":
        case "lit":
        case "fb2":
        case "azw":
        case "tpz":
            return ContentType.EBooks;
        default:
            return ContentType.Unknown;
    }
}

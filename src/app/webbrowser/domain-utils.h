/*
 * Copyright 2013 Canonical Ltd.
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

#ifndef __DOMAIN_UTILS_H__
#define __DOMAIN_UTILS_H__

// Qt
#include <QtCore/QString>
#include <QtCore/QStringList>
#include <QtCore/QUrl>

namespace DomainUtils {

static const QString TOKEN_LOCAL = "(local)";
static const QString TOKEN_NONE = "(none)";

static QString extractTopLevelDomainName(const QUrl& url)
{
    if (url.isLocalFile()) {
        return TOKEN_LOCAL;
    }
    QString host = url.host();
    if (host.isEmpty()) {
        // XXX: (when) can this happen?
        return TOKEN_NONE;
    }
    QString tld = url.topLevelDomain();
    if (tld.isEmpty()) {
        return host;
    }
    host.chop(tld.size());
    QString sld = host.split(".").last();
    return sld + tld;
}

} // namespace DomainUtils

#endif // __DOMAIN_UTILS_H__

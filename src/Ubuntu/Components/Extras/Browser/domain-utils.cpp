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

#include "domain-utils.h"

// Qt
#include <QtCore/QStringList>
#include <QtCore/QUrl>

const QString DomainUtils::TOKEN_LOCAL = "(local)";
const QString DomainUtils::TOKEN_NONE = "(none)";

QString DomainUtils::extractTopLevelDomainName(const QUrl& url)
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

/*
 * Copyright 2013 Canonical Ltd.
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

static QString getDomainWithoutSubdomain(const QString& domain)
{
    // e.g. ci.ubports.com (does handle domains like .co.uk correctly)
    // .com
    QString topLevelDomain = QUrl("//" + domain).topLevelDomain();

    // invalid top level domain (e.g. local device or IP address)
    if (topLevelDomain.isEmpty())
    {
        QString lastPartOfDomain = domain.mid(domain.lastIndexOf('.'));

        // last part is numeric -> seems to be an IP address
        bool convertToIntOk;
        lastPartOfDomain.toInt(&convertToIntOk);

        topLevelDomain = convertToIntOk ? "" : lastPartOfDomain;
    }

    // ci.ubports
    QString urlWithoutTopLevelDomain = domain.mid(0, domain.length() - topLevelDomain.length());
    // ubports (if no . is found, the string stays the same because lastIndexOf is -1)
    QString hostName = urlWithoutTopLevelDomain.mid(urlWithoutTopLevelDomain.lastIndexOf('.') + 1);
    // ubports.com
    return hostName + topLevelDomain;
}

} // namespace DomainUtils

#endif // __DOMAIN_UTILS_H__

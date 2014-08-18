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

#include "url-pattern-utils.h"

#include <QtCore/QRegularExpression>
#include <QDebug>


/**
 * Tests for the validity of a given webapp url pattern. It follows
 *  the following grammar:
 *
 * <url-pattern> := <scheme>://<host><path>
 * <scheme> := 'http' | 'https'
 * <host> := '*' <any char except '/' and '.'>+ <hostpart> <hostpart>+
 * <hostpart> := '.' <any char except '/', '*', '?' and '.'>+
 * <path> := '/' <any chars>
 *
 * @param pattern pattern that is to be tested for validity
 * @return true if the url is valid, false otherwise
 */
static bool isValidWebappUrlPattern(const QString& pattern)
{
    static QRegularExpression grammar("^http(s|s\\?)?://[^\\.]+\\.[^\\.\\*\\?]+\\.[^\\.\\*\\?]+(\\.[^\\.\\*\\?/]+)*/.*$");
    return grammar.match(pattern).hasMatch();
}

/**
 * A Google related webapp is treated very specifically. The issue
 * with those Google service related webapps is that the all rely
 * on a common authentication mechanism and one endup being redirected
 * to the auth urls automatically when needed.
 * Most of the redirections can be match against discrete url patterns
 * but there is always a country dependant step in the auth patterns, e.g.
 * https://accounts.google.com/* or https://accounts.google.ca/* etc.
 *
 * Since by default we dont allow a wildcard in the TLD position, the only
 * solution then is to manually enter the list of top level country related
 * domains.
 * In this context, we isolate the Google case, with a more restricted set of patterns
 * that should adhere to the following grammar:
 *
 * <url-pattern> := <scheme>://<host><path>
 * <scheme> := 'http' | 'https'
 * <host> := <any char except '/', '*', '?' and '.'>+ '.google' <hostpart>
 * <hostpart> := '.' <any char except '/', '?' and '.'>+
 * <path> := '/' <any chars>
 *
 * So for example we allow 'https://accounts.google.* /' but not 'https://*.google.* /'
 * (the spaces are there to avoid the confusion w/ a end of comment token.
 *
 * IMPORTAN NOTE: the '*' wildcard in the TLD position is not a REAL wildcard in the
 * sense that it corresponds to [^\\./], so it wont match ('google.com.evildomain') as usual.
 *
 * @param pattern pattern that is to be tested for validity
 * @return true if the url is valid, false otherwise
 */
static bool isValidGoogleUrlPattern(const QString& pattern)
{
    static QRegularExpression grammar("^http(s|s\\?)?://[^\\.\\?\\*]+\\.google\\.[^\\.\\?]+/.*$");
    return grammar.match(pattern).hasMatch();
}

/* A short URL pattern has only a domain and TLD, but no sub-domain,
 * and possibly regular path and protocol globs.
 *
 * @param pattern pattern that is to be tested for validity
 * @return true if the url is valid, false otherwise
 */
static bool isValidShortUrlPattern(const QString& pattern)
{
    static QRegularExpression grammar("^http(s|s\\?)?://[^\\.\\*\\?]+\\.[^\\.\\*\\?]+(\\.[^\\.\\*\\?/]+)*/.*$");
    return grammar.match(pattern).hasMatch();
}


QString UrlPatternUtils::transformWebappSearchPatternToSafePattern(const QString& pattern)
{
    QString transformedPattern;

    if (isValidWebappUrlPattern(pattern)) {

        QRegularExpression urlRe("(.+://)([^/]+)(.+)");
        QRegularExpressionMatch match = urlRe.match(pattern);

        if (match.hasMatch())
        {
            // We make a distinction between the wildcard found in the
            //  hostname part and the one found later. The former being more
            //  restricted and should not be replaced by the same regexp pattern
            //  as the latter.
            // A less restrictive hostname pattern might lead to the following
            //  situation where e.g.
            // http://bady.guy.com/phishing.ebay.com/
            // matches
            // https?://*.ebay.com/*
            QString scheme = match.captured(1);
            QString hostname = match.captured(2).replace("*", "[^\\./]*");
            QString tail = match.captured(3).replace("*", "[^\\s]*");

            // reconstruct
            transformedPattern = QString("%1%2%3").arg(scheme).arg(hostname).arg(tail);
        }
    } else if (isValidGoogleUrlPattern(pattern)) {

        QRegularExpression urlRe("(.+://)([^\\./]+\\.google\\.)([^/]+)(.+)");
        QRegularExpressionMatch match = urlRe.match(pattern);

        if (match.hasMatch())
        {
            QString scheme = match.captured(1);
            QString hostname = match.captured(2);
            QString tld = match.captured(3).replace("*", "[^\\./]*");
            QString tail = match.captured(4).replace("*", "[^\\s]*");

            // reconstruct
            transformedPattern = QString("%1%2%3%4")
                                    .arg(scheme)
                                    .arg(hostname)
                                    .arg(tld)
                                    .arg(tail);
        }
    } else if (isValidShortUrlPattern(pattern)) {
        QRegularExpression urlRe("(.+://)([^/]+)(.+)");
        QRegularExpressionMatch match = urlRe.match(pattern);

        if (match.hasMatch())
        {
            // See comment above
            QString scheme = match.captured(1);
            QString hostname = match.captured(2).replace("*", "[^\\./]*");
            QString tail = match.captured(3).replace("*", "[^\\s]*");

            // reconstruct
            transformedPattern = QString("%1%2%3").arg(scheme).arg(hostname).arg(tail);
        }
    }

    return transformedPattern;
}

QStringList UrlPatternUtils::filterAndTransformUrlPatterns(const QStringList & includePatterns)
{
    QStringList patterns;
    Q_FOREACH(const QString& includePattern, includePatterns) {
        QString pattern = includePattern.trimmed();

        if (pattern.isEmpty())
            continue;

        QString safePattern =
                transformWebappSearchPatternToSafePattern(pattern);

        if ( ! safePattern.isEmpty()) {
            patterns.append(safePattern);
        } else {
            qDebug() << "Ignoring empty or invalid webapp URL pattern:" << pattern;
        }
    }
    return patterns;
}


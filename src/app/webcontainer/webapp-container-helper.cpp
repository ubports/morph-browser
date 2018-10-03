/*
 * Copyright 2014-2016 Canonical Ltd.
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

#include "webapp-container-helper.h"

#include <QColor>
#include <QMetaObject>
#include <QMetaProperty>
#include <QRegExp>
#include <QDebug>

WebappContainerHelper::WebappContainerHelper(QObject* parent)
    : QObject(parent)
{
    connect(this, SIGNAL(browseToUrlRequested(QObject*, const QUrl&)),
            this, SLOT(browseToUrl(QObject*, const QUrl&)),
            Qt::QueuedConnection);
}

WebappContainerHelper::~WebappContainerHelper()
{
    disconnect(this, SIGNAL(browseToUrlRequested(QObject*, const QUrl&)),
                this, SLOT(browseToUrl(QObject*, const QUrl&)));
}

void WebappContainerHelper::browseToUrl(QObject* webview, const QUrl& url)
{
    if ( ! webview) {
        return;
    }
    const QMetaObject* metaobject = webview->metaObject();
    int urlPropIdx = metaobject->indexOfProperty("url");
    if (urlPropIdx == -1) {
        return;
    }
    metaobject->property(urlPropIdx).write(webview, QVariant(url));
}

QString WebappContainerHelper::rgbColorFromCSSColor(const QString& cssColor)
{
    QString color = cssColor.trimmed().toLower();
    if (color.isEmpty()) {
        return QString();
    }
    QString returnColorFormat = "%1,%2,%3";
    if (color.startsWith("rgb")) {
        QRegExp rgbColorRe("rgb\\s*\\(\\s*(\\d+)\\s*,\\s*(\\d+)\\s*,\\s*(\\d+)\\s*\\)");
        if (rgbColorRe.exactMatch(color)) {
            return returnColorFormat
                    .arg(rgbColorRe.cap(1).toInt())
                    .arg(rgbColorRe.cap(2).toInt())
                    .arg(rgbColorRe.cap(3).toInt());
        }
        return QString();
    } else if (color.startsWith("#")) {
        QString hexColor = color.mid(1);
        if (hexColor.size() < 6 && hexColor.size() != 3) {
            color = "#" + QString(6 - hexColor.size(), '0') + hexColor;
        }
    }

    QColor returnColor(color);
    return returnColor.isValid()
        ? returnColorFormat
          .arg(returnColor.red())
          .arg(returnColor.green())
          .arg(returnColor.blue())
          .toLower()
        : QString();
}

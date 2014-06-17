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

#include "webapp-container-helper.h"

#include <QMetaObject>
#include <QMetaProperty>


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
    if ( ! webview)
        return;
    const QMetaObject* metaobject = webview->metaObject();
    int urlPropIdx = metaobject->indexOfProperty("url");
    if (urlPropIdx == -1)
        return;
    metaobject->property(urlPropIdx).write(webview, QVariant(url));
}





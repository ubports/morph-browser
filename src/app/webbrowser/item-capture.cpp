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

// local
#include "item-capture.h"

// Qt
#include <QtCore/QCryptographicHash>
#include <QtCore/QDir>
#include <QtCore/QStandardPaths>
#include <QtQuick/private/qquickitem_p.h>

ItemCapture::ItemCapture(QQuickItem* parent)
    : QQuickShaderEffectSource(parent)
{
    connect(this, SIGNAL(parentChanged(QQuickItem*)), SLOT(onParentChanged(QQuickItem*)));

    setScale(0);

    QDir cacheLocation(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/captures");
    m_cacheLocation = cacheLocation.absolutePath();
    if (!cacheLocation.exists()) {
        QDir::root().mkpath(m_cacheLocation);
    }
}

void ItemCapture::onParentChanged(QQuickItem* parent)
{
    QQuickItemPrivate::get(this)->anchors()->setFill(parent);
    setSourceItem(parent);
}

QString ItemCapture::capture(const QString& id)
{
    const QSGTextureProvider* provider = textureProvider();
    const QQuickShaderEffectTexture* texture = qobject_cast<QQuickShaderEffectTexture*>(provider->texture());
    QOpenGLContext* ctx = QQuickItemPrivate::get(this)->sceneGraphRenderContext()->openglContext();
    if (ctx->makeCurrent(ctx->surface())) {
        QImage image = texture->toImage().mirrored();
        QString hash(QCryptographicHash::hash(id.toUtf8(), QCryptographicHash::Md5).toHex());
        QString filepath = m_cacheLocation + "/" + hash + ".jpg";
        if (!image.isNull()) {
            if (image.save(filepath)) {
                return filepath;
            }
        }
    }
    return QString();
}

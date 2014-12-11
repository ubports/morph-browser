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
#include <QtCore/QMetaObject>
#include <QtCore/QMutexLocker>
#include <QtCore/QStandardPaths>
#include <QtQuick/private/qquickitem_p.h>

ItemCapture::ItemCapture(QQuickItem* parent)
    : QQuickShaderEffectSource(parent)
    , m_quality(-1)
{
    connect(this, SIGNAL(parentChanged(QQuickItem*)), SLOT(onParentChanged(QQuickItem*)));

    setScale(0);

    QDir cacheLocation(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/captures");
    m_cacheLocation = cacheLocation.absolutePath();
    if (!cacheLocation.exists()) {
        QDir::root().mkpath(m_cacheLocation);
    }
}

const int ItemCapture::quality() const
{
    return m_quality;
}

void ItemCapture::setQuality(const int quality)
{
    if (quality != m_quality) {
        if ((quality >= -1) && (quality <= 100)) {
            m_quality = quality;
            Q_EMIT qualityChanged();
        } else {
            qWarning() << "Invalid value for quality, must be between 0 and 100 (or -1 for default)";
        }
    }
}

void ItemCapture::onParentChanged(QQuickItem* parent)
{
    if (sourceItem()) {
        sourceItem()->disconnect(this);
    }
    QQuickItemPrivate::get(this)->anchors()->setFill(parent);
    setSourceItem(parent);
    if (parent) {
        connect(parent, SIGNAL(visibleChanged()), SLOT(onParentVisibleChanged()));
    }
}

void ItemCapture::onParentVisibleChanged()
{
    setLive(parentItem()->isVisible());
}

QSGNode* ItemCapture::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* updatePaintNodeData)
{
    QSGNode* newNode = QQuickShaderEffectSource::updatePaintNode(oldNode, updatePaintNodeData);
    QMutexLocker locker(&m_mutex);
    if (!m_request.isEmpty()) {
        QString request = m_request;
        QUrl capture;
        m_request.clear();
        QQuickShaderEffectTexture* texture =
            qobject_cast<QQuickShaderEffectTexture*>(textureProvider()->texture());
        QOpenGLContext* ctx =
            QQuickItemPrivate::get(this)->sceneGraphRenderContext()->openglContext();
        if (ctx->makeCurrent(ctx->surface())) {
            QImage image = texture->toImage().mirrored();
            if (!image.isNull()) {
                QString hash(QCryptographicHash::hash(request.toUtf8(),
                                                      QCryptographicHash::Md5).toHex());
                QString filepath = m_cacheLocation + "/" + hash + ".jpg";
                if (image.save(filepath, 0, m_quality)) {
                    capture = QUrl::fromLocalFile(filepath);
                }
            }
        }
        QMetaObject::invokeMethod(this, "onCaptureFinished", Qt::QueuedConnection,
                                  Q_ARG(QString, request), Q_ARG(QUrl, capture));
    }
    return newNode;
}

void ItemCapture::requestCapture(const QString& id)
{
    QMutexLocker locker(&m_mutex);
    m_request = id;
    scheduleUpdate();
}

void ItemCapture::onCaptureFinished(QString request, QUrl capture) const
{
    Q_EMIT captureFinished(request, capture);
}

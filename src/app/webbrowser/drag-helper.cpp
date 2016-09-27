/*
 * Copyright 2016 Canonical Ltd.
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

#include "drag-helper.h"

#include <QDrag>
#include <QDropEvent>
#include <QMimeData>
#include <QPainter>
#include <QPixmap>
#include <QSize>

DragHelper::DragHelper()
{
    m_active = false;
    m_mime_type = QStringLiteral("webbrowser/tab");
    m_preview_url = "";
    m_source = NULL;
}

Qt::DropAction DragHelper::execDrag(QString tabId)
{
    QDrag *drag = new QDrag(m_source);

    QMimeData *mimeData = new QMimeData;
    mimeData->setData(mimeType(), tabId.toLatin1());

    QSize pixmapSize(200, 150);

    QPixmap pixmap(previewUrl());
    
    if (pixmap.isNull()) {
        // If loading pixmap failed, draw a white rectangle
        pixmap = QPixmap(pixmapSize);
        QPainter painter(&pixmap);
        painter.eraseRect(0, 0, pixmapSize.width(), pixmapSize.height());
        painter.fillRect(0, 0, pixmapSize.width(), pixmapSize.height(), QColor(255, 255, 255, 255));
    } else {
        // Scale image to fit the expected size
        pixmap = pixmap.scaled(pixmapSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }

    drag->setHotSpot(QPoint(pixmapSize.width() / 2, pixmapSize.height() / 2));
    drag->setMimeData(mimeData);
    drag->setPixmap(pixmap);

    return drag->exec(Qt::CopyAction | Qt::MoveAction | Qt::IgnoreAction);
}

void DragHelper::setActive(bool active)
{
    if (m_active != active) {
        m_active = active;

        Q_EMIT activeChanged(m_active);
    }
}

void DragHelper::setMimeType(QString mimeType)
{
    if (m_mime_type != mimeType) {
        m_mime_type = mimeType;

        Q_EMIT mimeTypeChanged(m_mime_type);
    }
}

void DragHelper::setPreviewUrl(QString previewUrl)
{
    if (m_preview_url != previewUrl) {
        m_preview_url = previewUrl;

        Q_EMIT previewUrlChanged(m_preview_url);
    }
}

void DragHelper::setSource(QQuickItem *source)
{
    if (m_source != source) {
        m_source = source;

        Q_EMIT sourceChanged(m_source);
    }
}


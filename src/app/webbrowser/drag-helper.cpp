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

#include <QtCore/QMimeData>
#include <QtCore/QPoint>
#include <QtCore/QSize>
#include <QtCore/QString>
#include <QtGui/QColor>
#include <QtGui/QDrag>
#include <QtGui/QDropEvent>
#include <QtGui/QPainter>
#include <QtGui/QPixmap>
#include <QtQuick/QQuickItem>

DragHelper::DragHelper()
    : QObject(),
    m_active(false),
    m_dragging(false),
    m_expected_action(Qt::IgnoreAction),
    m_mime_type(QStringLiteral("webbrowser/tab")),
    m_preview_url(""),
    m_source(Q_NULLPTR)
{
}

Qt::DropAction DragHelper::execDrag(QString tabId)
{
    QDrag *drag = new QDrag(m_source);

    // Create a mimedata object to use for the drag
    QMimeData *mimeData = new QMimeData;
    mimeData->setData(mimeType(), tabId.toLatin1());

    // Build a pixmap for the drag handle
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

    // Setup the drag and then execute it
    drag->setHotSpot(QPoint(0, 0));
    drag->setMimeData(mimeData);
    drag->setPixmap(pixmap);


    setDragging(true);

    Qt::DropAction action = drag->exec(expectedAction());

    setDragging(false);

    return action;
}

void DragHelper::setActive(bool active)
{
    if (m_active != active) {
        m_active = active;

        Q_EMIT activeChanged();
    }
}

void DragHelper::setDragging(bool dragging)
{
    if (m_dragging != dragging) {
        m_dragging = dragging;

        Q_EMIT draggingChanged();
    }
}

void DragHelper::setExpectedAction(Qt::DropAction expectedAction)
{
    if (m_expected_action != expectedAction) {
        m_expected_action = expectedAction;

        Q_EMIT expectedActionChanged();
    }
}

void DragHelper::setMimeType(QString mimeType)
{
    if (m_mime_type != mimeType) {
        m_mime_type = mimeType;

        Q_EMIT mimeTypeChanged();
    }
}

void DragHelper::setPreviewUrl(QString previewUrl)
{
    if (m_preview_url != previewUrl) {
        m_preview_url = previewUrl;

        Q_EMIT previewUrlChanged();
    }
}

void DragHelper::setSource(QQuickItem *source)
{
    if (m_source != source) {
        m_source = source;

        Q_EMIT sourceChanged();
    }
}


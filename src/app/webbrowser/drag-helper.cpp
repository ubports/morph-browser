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
#include <QPen>
#include <QPixmap>
#include <QSize>
#include <QSizeF>

DragHelper::DragHelper()
{
    m_active = false;
    m_expected_action = Qt::IgnoreAction;
    m_mime_type = QStringLiteral("webbrowser/tab");
    m_preview_border_width = 8;
    m_preview_size = QSizeF(200, 150);
    m_preview_top_crop = 0;
    m_preview_url = "";
    m_source = Q_NULLPTR;
}

QPixmap DragHelper::drawPixmapWithBorder(QPixmap pixmap, int borderWidth, QColor color)
{
    // Create a transparent pixmap to draw to
    QPixmap output(pixmap.width() + borderWidth * 2, pixmap.height() + borderWidth * 2);
    output.fill(QColor(0, 0, 0, 0));
    
    // Draw the pixmap with space around the edge for a border
    QPainter borderPainter(&output);
    borderPainter.setRenderHint(QPainter::Antialiasing);
    borderPainter.drawPixmap(borderWidth, borderWidth, pixmap);
    
    // Define a pen to use for the border
    QPen borderPen;
    borderPen.setColor(color);
    borderPen.setJoinStyle(Qt::MiterJoin);
    borderPen.setStyle(Qt::SolidLine);
    borderPen.setWidth(borderWidth);
    
    // Set the pen and draw the border
    borderPainter.setPen(borderPen);
    borderPainter.drawRect(borderWidth / 2, borderWidth / 2,
                           output.width() - borderWidth, output.height() - borderWidth);

    return output;
}

Qt::DropAction DragHelper::execDrag(QString tabId)
{
    QDrag *drag = new QDrag(m_source);

    // Create a mimedata object to use for the drag
    QMimeData *mimeData = new QMimeData;
    mimeData->setData(mimeType(), tabId.toLatin1());

    // Get a bordered pixmap of the previewUrl
    QSize size = previewSize().toSize();
    
    QPixmap pixmap = drawPixmapWithBorder(getPreviewUrlAsPixmap(size.width(), size.height()),
        previewBorderWidth(), QColor(205, 205, 205, 255 * 0.6));  // #cdcdcd
    
    // Setup the drag and then execute it
    drag->setHotSpot(QPoint(size.width() * 0.1, size.height() * 0.1));
    drag->setMimeData(mimeData);
    drag->setPixmap(pixmap);

    return drag->exec(expectedAction());
}

QPixmap DragHelper::getPreviewUrlAsPixmap(int width, int height)
{
    QSize pixmapSize(width, height);
    QPixmap pixmap(previewUrl());
    
    if (pixmap.isNull()) {
        // If loading pixmap failed, draw a white rectangle
        pixmap = QPixmap(pixmapSize);
        QPainter painter(&pixmap);
        painter.eraseRect(0, 0, pixmapSize.width(), pixmapSize.height());
        painter.fillRect(0, 0, pixmapSize.width(), pixmapSize.height(), QColor(255, 255, 255, 255));
    } else {
        // Crop transparent part off the top of the image
        pixmap = pixmap.copy(0, previewTopCrop(), pixmap.width(), pixmap.height() - previewTopCrop());

        // Scale image to fit the expected size
        pixmap = pixmap.scaled(pixmapSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }
    
    return pixmap;
}

void DragHelper::setActive(bool active)
{
    if (m_active != active) {
        m_active = active;

        Q_EMIT activeChanged(m_active);
    }
}

void DragHelper::setExpectedAction(Qt::DropAction expectedAction)
{
    if (m_expected_action != expectedAction) {
        m_expected_action = expectedAction;
        
        Q_EMIT expectedActionChanged(m_expected_action);
    }
}

void DragHelper::setMimeType(QString mimeType)
{
    if (m_mime_type != mimeType) {
        m_mime_type = mimeType;

        Q_EMIT mimeTypeChanged(m_mime_type);
    }
}

void DragHelper::setPreviewBorderWidth(int previewBorderWidth)
{
    if (m_preview_border_width != previewBorderWidth) {
        m_preview_border_width = previewBorderWidth;

        Q_EMIT previewTopCropChanged(m_preview_border_width);
    }
}

void DragHelper::setPreviewSize(QSizeF previewSize)
{
    if (m_preview_size != previewSize) {
        m_preview_size = previewSize;

        Q_EMIT previewSizeChanged(m_preview_size);
    }
}

void DragHelper::setPreviewTopCrop(int previewTopCrop)
{
    if (m_preview_top_crop != previewTopCrop) {
        m_preview_top_crop = previewTopCrop;

        Q_EMIT previewTopCropChanged(m_preview_top_crop);
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


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

#ifndef __DRAGHELPER_H__
#define __DRAGHELPER_H__

#include <QtCore/QSizeF>
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtGui/QColor>
#include <QtGui/QMouseEvent>

class QQuickItem;

class DragHelper : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(bool dragging READ dragging NOTIFY draggingChanged)
    Q_PROPERTY(Qt::DropAction expectedAction READ expectedAction WRITE setExpectedAction NOTIFY expectedActionChanged)
    Q_PROPERTY(QString mimeType READ mimeType WRITE setMimeType NOTIFY mimeTypeChanged)
    Q_PROPERTY(int previewBorderWidth READ previewBorderWidth WRITE setPreviewBorderWidth NOTIFY previewBorderWidthChanged)
    Q_PROPERTY(QSizeF previewSize READ previewSize WRITE setPreviewSize NOTIFY previewSizeChanged)
    Q_PROPERTY(int previewTopCrop READ previewTopCrop WRITE setPreviewTopCrop NOTIFY previewTopCropChanged)
    Q_PROPERTY(QString previewUrl READ previewUrl WRITE setPreviewUrl NOTIFY previewUrlChanged)
    Q_PROPERTY(QQuickItem* source READ source WRITE setSource NOTIFY sourceChanged)
public:
    DragHelper();
    bool active() { return m_active; }
    bool dragging() { return m_dragging; }
    Qt::DropAction expectedAction() { return m_expected_action; }
    QString mimeType() { return m_mime_type; }
    int previewBorderWidth() { return m_preview_border_width; }
    QSizeF previewSize() { return m_preview_size; }
    int previewTopCrop() { return m_preview_top_crop; }
    QString previewUrl() { return m_preview_url; }
    QQuickItem *source() { return m_source; }
signals:
    void activeChanged();
    void draggingChanged();
    void expectedActionChanged();
    void mimeTypeChanged();
    void previewBorderWidthChanged();
    void previewSizeChanged();
    void previewTopCropChanged();
    void previewUrlChanged();
    void sourceChanged();
public slots:
    Q_INVOKABLE Qt::DropAction execDrag(QString tabId);
    void setActive(bool active);
    void setExpectedAction(Qt::DropAction expectedAction);
    void setMimeType(QString mimeType);
    void setPreviewBorderWidth(int previewBorderWidth);
    void setPreviewSize(QSizeF previewSize);
    void setPreviewTopCrop(int previewTopCrop);
    void setPreviewUrl(QString previewUrl);
    void setSource(QQuickItem *source);
private:
    QPixmap drawPixmapWithBorder(QPixmap pixmap, int borderWidth, QColor color);
    QPixmap getPreviewUrlAsPixmap(int width, int height);
    void setDragging(bool dragging);

    bool m_active;
    bool m_dragging;
    Qt::DropAction m_expected_action;
    QString m_mime_type;
    int m_preview_border_width;
    QSizeF m_preview_size;
    int m_preview_top_crop;
    QString m_preview_url;
    QQuickItem *m_source;
};

#endif // __DRAGHELPER_H__


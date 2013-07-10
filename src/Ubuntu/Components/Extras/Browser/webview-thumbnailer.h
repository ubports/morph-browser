/*
 * Copyright 2013 Canonical Ltd.
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

#ifndef __WEBVIEW_THUMBNAILER_H__
#define __WEBVIEW_THUMBNAILER_H__

// Qt
#include <QtCore/QSize>
#include <QtCore/QUrl>
#include <QtQuick/private/qquickitem_p.h>

class QQuickWebView;
class QSGRenderer;

class WebviewThumbnailer : public QQuickItem
{
    Q_OBJECT

    Q_PROPERTY(QQuickWebView* webview READ webview WRITE setWebview NOTIFY webviewChanged)
    Q_PROPERTY(QSize targetSize READ targetSize WRITE setTargetSize NOTIFY targetSizeChanged)

public:
    WebviewThumbnailer(QQuickItem* parent=0);
    ~WebviewThumbnailer();

    QQuickWebView* webview() const;
    void setWebview(QQuickWebView* webview);

    const QSize& targetSize() const;
    void setTargetSize(const QSize& targetSize);

    Q_INVOKABLE bool thumbnailExists() const;
    Q_INVOKABLE void renderThumbnail();

Q_SIGNALS:
    void webviewChanged() const;
    void targetSizeChanged() const;
    void thumbnailRendered(const QUrl& url) const;

protected:
    virtual QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* updatePaintNodeData);

private Q_SLOTS:
    void doRenderThumbnail();

private:
    QQuickWebView* m_webview;
    QSize m_targetSize;
    QSGRenderer* m_renderer;
};

#endif // __WEBVIEW_THUMBNAILER_H__

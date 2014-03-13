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

#include "webthumbnail-utils.h"
#include "webview-thumbnailer.h"

// Qt
#include <QtCore/QtGlobal>
#include <QtCore/QMetaObject>
#include <QtCore/QTimer>
#include <QtQuick/private/qsgrenderer_p.h>
#include <QtWebKit/private/qquickwebpage_p.h>
#include <QtWebKit/private/qquickwebview_p.h>

class BindableFbo : public QSGBindable
{
public:
    BindableFbo(QOpenGLFramebufferObject* fbo) : m_fbo(fbo) {}
    virtual void bind() const { m_fbo->bind(); }

private:
    QOpenGLFramebufferObject *m_fbo;
};

WebviewThumbnailer::WebviewThumbnailer(QQuickItem* parent)
    : QQuickItem(parent)
    , m_webview(0)
    , m_renderer(0)
{
}

WebviewThumbnailer::~WebviewThumbnailer()
{
    delete m_renderer;
}

QQuickWebView* WebviewThumbnailer::webview() const
{
    return m_webview;
}

void WebviewThumbnailer::setWebview(QQuickWebView* webview)
{
    if (webview != m_webview) {
        m_webview = webview;
        setFlag(QQuickItem::ItemHasContents, false);
        Q_EMIT webviewChanged();
    }
}

const QSize& WebviewThumbnailer::targetSize() const
{
    return m_targetSize;
}

void WebviewThumbnailer::setTargetSize(const QSize& targetSize)
{
    if (targetSize != m_targetSize) {
        m_targetSize = targetSize;
        Q_EMIT targetSizeChanged();
    }
}

bool WebviewThumbnailer::thumbnailExists() const
{
    if (m_webview) {
        QUrl url = m_webview->url();
        if (url.isValid()) {
            return WebThumbnailUtils::thumbnailFile(url).exists();
        }
    }
    return false;
}

void WebviewThumbnailer::renderThumbnail()
{
    // Delay the actual rendering to give all elements on the page
    // a chance to be fully rendered.
    QTimer::singleShot(1000, this, SLOT(doRenderThumbnail()));
}

void WebviewThumbnailer::doRenderThumbnail()
{
    if (m_webview) {
        setFlag(QQuickItem::ItemHasContents);
        update();
    }
}

QSGNode* WebviewThumbnailer::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* updatePaintNodeData)
{
    Q_UNUSED(updatePaintNodeData);

    if (!(m_webview && (flags() & QQuickItem::ItemHasContents))) {
        return oldNode;
    }
    setFlag(QQuickItem::ItemHasContents, false);

    QQuickWebPage* page = m_webview->page();
    qreal min = qMin(page->width(), page->height());
    QSize size(min, min);

    QSGNode* node = QQuickItemPrivate::get(page)->itemNode();
    QSGNode* parent = node->QSGNode::parent();
    QSGNode* previousSibling = node->previousSibling();
    if (parent) {
        parent->removeChildNode(node);
    }
    QSGRootNode root;
    root.appendChildNode(node);

    if (m_renderer == 0) {
#if QT_VERSION < QT_VERSION_CHECK(5, 2, 0)
        m_renderer = QQuickItemPrivate::get(this)->sceneGraphContext()->createRenderer();
#else
        m_renderer = QQuickItemPrivate::get(this)->sceneGraphRenderContext()->createRenderer();
#endif
    }
    m_renderer->setRootNode(static_cast<QSGRootNode*>(&root));

    QOpenGLFramebufferObject fbo(size);

    m_renderer->setDeviceRect(size);
    m_renderer->setViewportRect(size);
    m_renderer->setProjectionMatrixToRect(QRectF(QPointF(), size));
    m_renderer->setClearColor(Qt::transparent);

    m_renderer->renderScene(BindableFbo(&fbo));

    fbo.release();

    const QUrl& url = m_webview->url();
    QImage image = fbo.toImage().scaled(m_targetSize, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);

    // Invoke the method asynchronously.
    QMetaObject::invokeMethod(&WebThumbnailUtils::instance(), "cacheThumbnail",
                              Qt::QueuedConnection, Q_ARG(QUrl, url), Q_ARG(QImage, image));

    root.removeChildNode(node);

    if (parent) {
        if (previousSibling) {
            parent->insertChildNodeAfter(node, previousSibling);
        } else {
            parent->prependChildNode(node);
        }
    }

    Q_EMIT thumbnailRendered(url);

    return oldNode;
}

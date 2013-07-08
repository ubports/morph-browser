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

#include "webview-thumbnailer.h"

// Qt
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
{
}

WebviewThumbnailer::~WebviewThumbnailer()
{
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

void WebviewThumbnailer::renderThumbnail()
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

    QSGRenderer* renderer = QQuickItemPrivate::get(this)->sceneGraphContext()->createRenderer();
    renderer->setRootNode(static_cast<QSGRootNode*>(&root));

    QOpenGLFramebufferObject fbo(size);

    renderer->setDeviceRect(size);
    renderer->setViewportRect(size);
    renderer->setProjectionMatrixToRect(QRectF(QPointF(), size));
    renderer->setClearColor(Qt::transparent);

    renderer->renderScene(BindableFbo(&fbo));

    fbo.release();

    QImage image = fbo.toImage().scaled(m_targetSize, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
    QString filename = "test.png"; // XXX
    bool saved = image.save(filename);

    root.removeChildNode(node);

    if (parent) {
        if (previousSibling) {
            parent->insertChildNodeAfter(node, previousSibling);
        } else {
            parent->prependChildNode(node);
        }
    }

    if (saved) {
        Q_EMIT thumbnailRendered(filename);
    }

    return oldNode;
}

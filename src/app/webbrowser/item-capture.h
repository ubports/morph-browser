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

#ifndef __ITEM_CAPTURE_H__
#define __ITEM_CAPTURE_H__

// Qt
#include <QtCore/QMutex>
#include <QtCore/QString>
#include <QtCore/QUrl>
#include <QtQuick/private/qquickshadereffectsource_p.h>

class ItemCapture : public QQuickShaderEffectSource
{
    Q_OBJECT
public:
    ItemCapture(QQuickItem* parent=0);

public Q_SLOTS:
    void requestCapture(const QString& id);

Q_SIGNALS:
    void captureFinished(QUrl capture) const;

protected:
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* updatePaintNodeData);

private Q_SLOTS:
    void onParentChanged(QQuickItem* parent);
    void onParentVisibleChanged();
    void onCaptureFinished() const;

private:
    QString m_cacheLocation;
    QMutex m_mutex;
    QString m_request;
    QUrl m_capture;
};

#endif // __ITEM_CAPTURE_H__

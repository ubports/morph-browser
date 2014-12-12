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
#include <QtCore/QString>
#include <QtCore/QUrl>
#include <QtQuick/private/qquickshadereffectsource_p.h>

class QImage;

class ItemCapture : public QQuickShaderEffectSource
{
    Q_OBJECT

    Q_PROPERTY(int quality READ quality WRITE setQuality NOTIFY qualityChanged)

public:
    ItemCapture(QQuickItem* parent=0);

    const int quality() const;
    void setQuality(const int quality);

public Q_SLOTS:
    void requestCapture(const QString& id);

Q_SIGNALS:
    void qualityChanged() const;
    void captureFinished(QString request, QUrl capture) const;

protected:
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* updatePaintNodeData);

private Q_SLOTS:
    void onParentChanged(QQuickItem* parent);
    void onParentVisibleChanged();
    void saveImage(const QImage& image, const QString& filePath, const QString& request);

private:
    QString m_cacheLocation;
    QString m_request;
    int m_quality;
};

#endif // __ITEM_CAPTURE_H__

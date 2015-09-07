/*
 * Copyright 2015 Canonical Ltd.
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

#include "downloads-mimetype-model.h"
#include "downloads-model.h"

#include <QtCore/QRegExp>

/*!
    \class DownloadsMimetypeModel
    \brief Proxy model that filters the contents of a downloads model
           based on the mimetype

    DownloadsMimetypeModel is a proxy model that filters the contents of a
    downloads model based on the mimetype of downloaded files.

    The mimetype can be provided as a regular expression.

    When no mimetype is set (null or empty string), all downloads are
    included in the model.
*/
DownloadsMimetypeModel::DownloadsMimetypeModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
}

DownloadsModel* DownloadsMimetypeModel::sourceModel() const
{
    return qobject_cast<DownloadsModel*>(QSortFilterProxyModel::sourceModel());
}

void DownloadsMimetypeModel::setSourceModel(DownloadsModel* sourceModel)
{
    if (sourceModel != this->sourceModel()) {
        QSortFilterProxyModel::setSourceModel(sourceModel);
        Q_EMIT sourceModelChanged();
        Q_EMIT countChanged();
    }
}

const QString& DownloadsMimetypeModel::mimetype() const
{
    return m_mimetype;
}

void DownloadsMimetypeModel::setMimetype(const QString& mime)
{
    if (mime != m_mimetype) {
        m_mimetype = mime;
        invalidate();
        Q_EMIT mimetypeChanged();
        Q_EMIT countChanged();
    }
}

int DownloadsMimetypeModel::count() const
{
    return rowCount();
}

QVariantMap DownloadsMimetypeModel::get(int row) const
{
    if (row < 0 || row >= rowCount()) {
        return QVariantMap();
    }

    QVariantMap res;
    QHash<int,QByteArray> names = roleNames();
    QHashIterator<int, QByteArray> i(names);

    while (i.hasNext()) {
        i.next();
        QModelIndex idx = index(row, 0);
        QVariant data = idx.data(i.key());
        res[i.value()] = data;
    }

    return res;
}

bool DownloadsMimetypeModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    if (m_mimetype.isEmpty()) {
        return true;
    }
    QModelIndex index = sourceModel()->index(source_row, 0, source_parent);
    QString mime = sourceModel()->data(index, DownloadsModel::Mimetype).toString();
    QRegExp regexp(m_mimetype);
    return mime.contains(regexp);
}

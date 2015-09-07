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

#ifndef __DOWNLOADS_MIMETYPE_MODEL_H__
#define __DOWNLOADS_MIMETYPE_MODEL_H__

// Qt
#include <QtCore/QSortFilterProxyModel>
#include <QtCore/QString>

class DownloadsModel;

class DownloadsMimetypeModel : public QSortFilterProxyModel
{
    Q_OBJECT

    Q_PROPERTY(DownloadsModel* sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)
    Q_PROPERTY(QString mimetype READ mimetype WRITE setMimetype NOTIFY mimetypeChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    DownloadsMimetypeModel(QObject* parent=0);

    DownloadsModel* sourceModel() const;
    void setSourceModel(DownloadsModel* sourceModel);

    const QString& mimetype() const;
    void setMimetype(const QString& mime);

    int count() const;
    Q_INVOKABLE QVariantMap get(int row) const;

Q_SIGNALS:
    void sourceModelChanged() const;
    void mimetypeChanged() const;
    void countChanged() const;

protected:
    // reimplemented from QSortFilterProxyModel
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const;

private:
    QString m_mimetype;
};

#endif // __DOWNLOADS_MIMETYPE_MODEL_H__

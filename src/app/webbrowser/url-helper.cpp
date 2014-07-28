#include "url-helper.h"
#include <QtCore/QUrl>

UrlHelper::UrlHelper(QObject *parent) :
    QObject(parent)
{
}

QString UrlHelper::extractDomain(QString url) const
{
    QUrl parsed(url);
    if (parsed.isValid()) return parsed.host();
    else return QString();
}

#ifndef URLHELPER_H
#define URLHELPER_H

#include <QObject>

class UrlHelper : public QObject
{
    Q_OBJECT
public:
    explicit UrlHelper(QObject *parent = 0);

signals:

public slots:
    QString extractDomain(QString url) const;

};

#endif // URLHELPER_H

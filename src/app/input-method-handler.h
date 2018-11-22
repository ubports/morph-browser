#ifndef INPUTMETHODHANDLER_H
#define INPUTMETHODHANDLER_H

#include <QObject>
#include <QEvent>
#include <QKeyEvent>

class inputMethodHandler : public QObject
{
// Q_OBJECT
public:
    explicit inputMethodHandler(QObject *parent = 0);

public:
    bool eventFilter(QObject* obj, QEvent* event);

};

#endif

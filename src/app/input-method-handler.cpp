#include "input-method-handler.h"

#include <QGuiApplication>
#include <QInputMethod>
#include <QDebug>

inputMethodHandler::inputMethodHandler(QObject *parent) : QObject(parent) {}

bool inputMethodHandler::eventFilter(QObject* obj, QEvent* event)
{
    // only process input method related events
    if (event->type() != QEvent::InputMethod)
    {
        return false;
    }

    // the text field objects in the browser do not have object names.
    if (obj->objectName() != "")
    {
        return false;
    }

    //qDebug() << "input event, object is " << obj->objectName() << " is window ? " << obj->isWindowType() << " is widget ? " << obj->isWidgetType();;

    // get info about the event
    QInputMethodEvent * inputevent = static_cast<QInputMethodEvent*>(event);

    //qDebug() << "input event, predit string: " << inputevent->preeditString() << " commit string: " << inputevent->commitString();

    // if the last char of the commit string is a number, do nothing (reset would change the keyboard layout back to letter mode)
    if (! inputevent->commitString().isEmpty() && inputevent->commitString()[inputevent->commitString().length() - 1].isDigit())
    {
        return false;
    }

    // check the request contains information about the text format
    bool hasTextFormatInfo = false;

    for (auto attribute : inputevent->attributes())
    {
      if (attribute.type == QInputMethodEvent::TextFormat)
      {
         //qDebug() << "text format found.";
         hasTextFormatInfo = true;
      }
    }

    // reset if there is no text format provided
    if ( ! hasTextFormatInfo && QGuiApplication::inputMethod() )
    {
      QGuiApplication::inputMethod()->reset();
    }

    return false;
}

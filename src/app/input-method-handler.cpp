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

    if (! inputevent->commitString().isEmpty() )
    {
        QChar lastCharOfCommitString = inputevent->commitString()[inputevent->commitString().length() - 1];

        // numbers and special chars do automatically commit, no reset done here as it would change the keyboard mode
        if ( (lastCharOfCommitString != "'") && (lastCharOfCommitString != " ") && ! lastCharOfCommitString.isLetter() )
        {
            return false;
        }
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

#include "cookiestore.h"

CookieStore::CookieStore(QObject *parent)
    : QObject(parent)
{
    qRegisterMetaType<Cookies>("Cookies");
}

Cookies CookieStore::cookies() const
{
    return doGetCookies();
}

void CookieStore::setCookies(Cookies cookies)
{
    doSetCookies(cookies);
}

Cookies CookieStore::doGetCookies() const
{
    return Cookies();
}

void CookieStore::doSetCookies(Cookies cookies)
{
    Q_UNUSED(cookies);
}

QDateTime CookieStore::timeStamp() const
{
    return _timeStamp;
}

void CookieStore::moveFrom(const CookieStore *store)
{
    if (! store)
        return;

    // TODO timestamp logic
    Cookies cookies = store->cookies();
    setCookies(cookies);
}


import QtQuick 2.0

AuthenticationDialog {
    id: proxyAuthDialog
    title: i18n.tr("Proxy authentication required.")
    text: i18n.tr("The website " + model.hostname + ":" + model.port + " requires authentication.")
}

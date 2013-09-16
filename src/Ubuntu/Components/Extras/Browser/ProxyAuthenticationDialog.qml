import QtQuick 2.0

AuthenticationDialog {
    id: proxyAuthDialog
    title: i18n.tr("Proxy authentication required.")
    text: i18n.tr("The website %1:%2 requires authentication.").arg(model.hostname).arg(model.port)
}

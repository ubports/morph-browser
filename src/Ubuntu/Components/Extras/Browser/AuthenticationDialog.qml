import QtQuick 2.0

import Ubuntu.Components 0.1
import Ubuntu.Components.Popups 0.1 as Popups

Popups.Dialog {
    id: authDialog

    title: i18n.tr("Authentication required.")
    text: i18n.tr("The website %1 requires authentication.").arg(model.hostname)

    TextField {
        id: usernameInput
        placeholderText: i18n.tr("Username")
        text: model.prefilledUsername
        onAccepted: model.accept(usernameInput.text, passwordInput.text)
    }

    TextField {
        id: passwordInput
        placeholderText: i18n.tr("Password")
        echoMode: TextInput.Password
        onAccepted: model.accept(usernameInput.text, passwordInput.text)
    }

    Button {
        text: i18n.tr("OK")
        color: "green"
        onClicked: model.accept(usernameInput.text, passwordInput.text)
    }

    Button {
        text: i18n.tr("Cancel")
        color: UbuntuColors.coolGrey
        onClicked: model.reject()
    }

    Component.onCompleted: show()
}

pragma Singleton
import QtQuick 2.4
QtObject {
    property var currentDownloads: []
    readonly property string downloadIdPrefixOfCurrentSession: new Date().getTime().toString()
}

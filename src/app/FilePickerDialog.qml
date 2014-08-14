/*
 * Copyright 2014 Canonical Ltd.
 *
 * This file is part of webbrowser-app.
 *
 * webbrowser-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * webbrowser-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtQuick.Dialogs 1.0
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0 as Popups

Component {
    Popups.Dialog {
        FileDialog {
            id: fileDialog
            title: i18n.tr("Please choose a file")
            selectMultiple: model.allowMultipleFiles
    
            onAccepted: {
                var selectedFiles = []
                for(var i in fileDialog.fileUrls) {
                    selectedFiles.push(fileDialog.fileUrls[i].replace("file://", ""))
                }
                model.accept(selectedFiles)
            }
    
            onRejected: {
                model.reject()
            }
            Component.onCompleted: visible = true
        }
    }
}

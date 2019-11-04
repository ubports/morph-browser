import QtQuick 2.4
import Ubuntu.Components 1.3                  // For UbuntuShape.
import Ubuntu.Components.Popups 1.3 as Popups // For saveDialog.
import QtWebEngine 1.7
import webbrowsercommon.private 0.1           // For DomainSettingsModel singleton.
import "UrlUtils.js" as UrlUtils

// ZoomControls object to provide zoom menu, control and autofit logic for WebViewImpl.
// Scope requirements:
//     webview:             An WebViewImpl object for zoomFactor manipulation and signal bindings.
//     browser (or webapp): An Browser (or WebApp) object for settings operations.
UbuntuShape {
    z:3
    id: menu
    objectName: "zoomActions"
    visible: false
    aspect: UbuntuShape.DropShadow
    backgroundColor: theme.palette.normal.background
    width: zoomActionsRow.width + padding * 2
    height: zoomActionsRow.height + currentZoomText.height + padding * 2
    x: (webview.width - width) / 2
    y: (webview.height - height) / 2

    readonly property int padding: units.gu(1)
    readonly property alias controller: controller

    MouseArea {
        // Without that MouseArea the user can click "through" inactive parts of the page menu (e.g the text of current zoom value).
        anchors.fill: menu
    }

    ActionList {
        id: zoomActions
        Action {
            name: "fitToWidth"
            text: i18n.tr("Fit (%1%)".arg(isNaN(controller.fitToWidthFactor) ? "-" : controller.fitToWidthFactor * 100))
            iconName: "zoom-fit-best"
            enabled: !isNaN(controller.fitToWidthFactor) && (Math.abs(controller.currentZoomFactor - controller.fitToWidthFactor) >= 0.01 || controller.viewSpecificZoom === false)
            onTriggered: controller.fitToWidth()
        }
        Action {
            name: "zoomOut"
            text: i18n.tr("Zoom Out")
            iconName: "zoom-out"
            enabled: Math.abs(controller.currentZoomFactor - controller.minZoomFactor) >= 0.01
            onTriggered: controller.zoomOut()
        }
        Action {
            name: "zoomOriginal"
            text: i18n.tr("Reset") + " (%1%)".arg(controller.defaultZoomFactor * 100)
            iconName: "reset"
            enabled: controller.viewSpecificZoom || Math.abs(controller.currentZoomFactor - controller.defaultZoomFactor) >= 0.01
            onTriggered: controller.resetSaveFit()
        }
        Action {
            name: "zoomIn"
            text: i18n.tr("Zoom In")
            iconName: "zoom-in"
            enabled: Math.abs(controller.currentZoomFactor - controller.maxZoomFactor) >= 0.01
            onTriggered: controller.zoomIn()
        }
        Action {
            name: "zoomSave"
            text: i18n.tr("Save")
            iconName: "save"
            enabled: saveDomainButton.enabled || saveDefaultButton.enabled
            onTriggered: controller.save()
        }
        Action {
            name: "close"
            text: i18n.dtr('ubuntu-ui-toolkit', "Close")
            iconName: "close"
            enabled: true
            onTriggered: menu.visible = false
        }
    }

    Row {
        id: zoomActionsRow
        x: parent.padding
        y: parent.padding
        height: units.gu(6)

        Repeater {
            model: zoomActions.children
            AbstractButton {
                objectName: "pageAction_" + action.name
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                width: Math.max(units.gu(4), implicitWidth) + units.gu(1)
                action: modelData
                styleName: "ToolbarButtonStyle"
                activeFocusOnPress: false
            }
        }
    }

    Text {
        id: currentZoomText
        anchors.top: zoomActionsRow.bottom
        anchors.right: zoomActionsRow.right
        text: i18n.tr("Current Zoom") + ": " + Math.round(controller.currentZoomFactor * 100) + "%"
        + " (%1)".arg(controller.viewSpecificZoom ? i18n.tr("domain") : (controller.currentZoomFactor === controller.defaultZoomFactor ? i18n.tr("default") : i18n.tr("auto-fit")))
        color: theme.palette.normal.backgroundText
        width: zoomActionsRow.width
        horizontalAlignment: Text.AlignHCenter
    }

    onVisibleChanged: {
        console.log("[ZC] menu.visible triggered: %1 (%2)".arg(visible).arg(webview.url));
        if (visible === false || internal.currentDomainScrollWidth != 0 || webview.url == "" ) {
            return;
        }

        // Zoom menu is visible but fitToWidth percentage is not filled in, cause page's scrollWidth is not retrieved. Retrieve it now!
        internal.retrieveScrollWidth();
    }


    QtObject {
        id: controller

        // Contains domain, or scheme if webview.url has no domain.
        readonly property string currentDomain: UrlUtils.hostIs(webview.url, "") ? "scheme:" + UrlUtils.extractScheme(webview.url) : UrlUtils.extractHost(webview.url)

        readonly property real defaultZoomFactor: browser.settings ? browser.settings.zoomFactor : webapp.settings.zoomFactor
        readonly property real minZoomFactor: 0.25
        readonly property real maxZoomFactor: 5.0
        readonly property alias currentZoomFactor: internal.currentZoomFactor
        readonly property alias viewSpecificZoom: internal.viewSpecificZoom

        readonly property bool autoFitToWidthEnabled: browser.settings ? browser.settings.autoFitToWidthEnabled : webapp.settings.autoFitToWidthEnabled
        readonly property real fitToWidthFactor: internal.currentDomainScrollWidth > 0 ? Math.max(minZoomFactor, Math.min(maxZoomFactor, Math.floor((webview.width / internal.currentDomainScrollWidth) * 100) / 100)) : NaN

        function fitToWidth() {
            console.log("[ZC] controller.fitToWidth called: %1".arg(fitToWidthFactor));
            if (isNaN(fitToWidthFactor)) {
                console.log("[ZC]   not applying");
                return;
            }

            internal.viewSpecificZoom = true;
            internal.currentZoomFactor = fitToWidthFactor;
            if (! webview.incognito) {
                saveZoomFactorForCurrentDomain();
            }
        }

        function zoomIn() {
            internal.viewSpecificZoom = true;
            internal.currentZoomFactor = Math.min(maxZoomFactor, currentZoomFactor + ((Math.round(currentZoomFactor * 100) % 10 === 0) ? 0.1 : 0.1 - (currentZoomFactor % 0.1)));
            if (! webview.incognito) {
                saveZoomFactorForCurrentDomain();
            }
        }

        function resetSaveFit() {
            console.log("[ZC] controller.resetSaveFit called");
            internal.viewSpecificZoom = false;
            internal.currentZoomFactor = defaultZoomFactor;
            if (! webview.incognito) {
                saveZoomFactorForCurrentDomain();
            }

            internal.currentDomainScrollWidth = 0;
            internal.updateFitToWidth();
        }

        function zoomOut() {
            internal.viewSpecificZoom = true
            internal.currentZoomFactor = Math.max(minZoomFactor, currentZoomFactor - ((Math.round(currentZoomFactor * 100) % 10 === 0) ? 0.1 : currentZoomFactor % 0.1));
            if (! webview.incognito) {
                saveZoomFactorForCurrentDomain();
            }
        }

        function save() {
            saveDialog.show();
        }

        function saveZoomFactorForCurrentDomain() {
            if (viewSpecificZoom) {
                DomainSettingsModel.setZoomFactor(currentDomain, currentZoomFactor);
            }
            else {
                DomainSettingsModel.setZoomFactor(currentDomain, NaN);
            }
        }
    }

    // Popup dialog for saving in zoom menu.
    Popups.Dialog {
        id: saveDialog
        parent: webview
        objectName: "saveZoomFactorDialog"
        title: i18n.tr("Save Zoom")
        readonly property string saveDomainText: saveDomainButton.enabled ? i18n.tr("domain zoom (currently %1 and can be removed with reset button or from domain specific settings in privacy settings)".arg(isNaN(internal.currentDomainZoomFactor) ? i18n.tr("none") : Math.round(internal.currentDomainZoomFactor * 100) + "%")) : ""
        readonly property string saveDefaultText: saveDefaultButton.enabled ? i18n.tr("default zoom (crrently %1% and can be changed from setting menu)".arg(Math.round(controller.defaultZoomFactor * 100))) : ""
        text: i18n.tr("Current zoom (%1%) can be saved for %2 as ".arg(Math.round(controller.currentZoomFactor * 100)).arg(isWebApp ? i18n.tr("the current web app") : "morph-browser")) + "\n"
        + saveDomainText
        + (saveDomainButton.enabled && saveDefaultButton.enabled ? "\n" + i18n.tr("or") + "\n": "")
        + saveDefaultText

        Button {
            id: saveDomainButton
            text: i18n.tr("Save for domain")
            color: theme.palette.normal.positive
            objectName: "saveDomainButton"
            enabled: isNaN(internal.currentDomainZoomFactor) || Math.abs(controller.currentZoomFactor - internal.currentDomainZoomFactor) >= 0.01
            onClicked: {
                internal.viewSpecificZoom = true;
                controller.saveZoomFactorForCurrentDomain();
                saveDialog.hide();
            }
        }

        Button {
            id: saveDefaultButton
            text: i18n.tr("Save as default")
            color: theme.palette.normal.positive
            objectName: "saveDefaultButton"
            enabled: Math.abs(controller.currentZoomFactor - controller.defaultZoomFactor) >= 0.01
            onClicked: {
                if (browser.settings) {
                    browser.settings.zoomFactor = controller.currentZoomFactor;
                }
                else {
                    webapp.settings.zoomFactor = controller.currentZoomFactor;
                }
                saveDialog.hide();
            }
        }

        Button {
            objectName: "cancelButton"
            text: i18n.tr("Cancel")
            onClicked: {
                saveDialog.hide();
            }
        }
    }

    // Internal states, functions and bindings/connecions.
    QtObject {
        id: internal

        property bool viewSpecificZoom: false
        property real currentZoomFactor: controller.defaultZoomFactor

        property int currentDomainScrollWidth: 0
        property real currentDomainZoomFactor: NaN

        property bool refreshZoomOnWebViewVisible: false
        property bool anyPageLoaded: false

        // Resets scroll width, reloads page zoom and updates fit to width.
        // Or flags for update after visible, if not visible.
        function resetAndUpdate() {
            console.log("[ZC] resetAndUpdate called");

            internal.currentDomainScrollWidth = 0;

            // We need to adjust zoom settings now, or in the future.
            if (webview.visible === false) {
                // Webview is not visible, flag to update after visible and return.
                console.log("[ZC]   webview not visible, setting flag to refresh after visible and skipping zoom setting update");
                internal.refreshZoomOnWebViewVisible = true;
                return;
            }

            // Adjust zoom settings according to domainZoomFactor and fit if neccessary.
            internal.updatePageZoom();
            internal.updateFitToWidth();
        }

        function updatePageZoom() {
            console.log("[ZC] internal.updatePageZoom called: %1".arg(controller.currentDomain));
            internal.currentDomainZoomFactor = DomainSettingsModel.getZoomFactor(controller.currentDomain);
            if (isNaN(internal.currentDomainZoomFactor) ) {
                internal.viewSpecificZoom = false;
                if (controller.autoFitToWidthEnabled && internal.currentDomainScrollWidth !== 0) {
                    internal.currentZoomFactor = controller.fitToWidthFactor;
                }
                else {
                    internal.currentZoomFactor = controller.defaultZoomFactor;
                }
            }
            else {
                internal.viewSpecificZoom = true;
                internal.currentZoomFactor = internal.currentDomainZoomFactor;
            }
            console.log("[ZC]   viewSpecificZoom: %1".arg(controller.viewSpecificZoom));
            console.log("[ZC]   currentZoomFactor: %1".arg(controller.currentZoomFactor));
        }

        function updateFitToWidth() {
            console.log("[ZC] internal.updateFitToWidth called");
            if (internal.currentDomainScrollWidth !== 0) {
                // Fit to width was allready handled for this domain, so don't continue.
                console.log("[ZC]   scroll width allready retrieved");
                return;
            }

            if (internal.anyPageLoaded === false) {
                // No page loaded, we are in "greeter", don't need to auto fit.
                console.log("[ZC]   no page loaded ever");
                return;
            }

            if (webview.loading === true) {
                // If webview is currently loading a page, no need to refresh fit, cause it will be refreshed after loading (if neccessary).
                console.log("[ZC]   webview is currently loading");
                return;
            }

            // Check for automatic fit to width.
            if (controller.autoFitToWidthEnabled && controller.viewSpecificZoom === false) {
                // Automatic fit to width will update fitToWidthFactor
                internal.autoFitToWidthFromDefaultZoomFactor();
                return;
            }

            if (menu.visible === false) {
                // Zoom menu is not visible, no need to retrieve scroll width, we will do that after zoom menu is shown.
                console.log("[ZC]   zoom menu not visible");
                return;
            }

            // Retrieve scroll width and update fitToWidthFactor.
            internal.retrieveScrollWidth();
        }

        function autoFitToWidthFromDefaultZoomFactor() {
            console.log("[ZC] internal.autoFitToWidthFromDefaultZoomFactor called");
            if (internal.currentDomainScrollWidth !== 0 || webview.loading === true || controller.autoFitToWidthEnabled === false || controller.viewSpecificZoom === true) {
                console.log("WARNING: calling autoFitToWidthFromDefaultZoomFactor when not intended?");
            }
            // Zoom to defaultZoomFactor before determining scrollWidth, to allways get consistent numbers.
            webview.zoomFactor = controller.defaultZoomFactor;
            internal.autoFitToWidthTimer.restart();
        }


        function retrieveScrollWidth() {
            console.log("[ZC] internal.retrieveScrollWidth called");
            if (internal.currentDomainScrollWidth !== 0 || webview.loading === true || (controller.autoFitToWidthEnabled === true && controller.viewSpecificZoom === false) || menu.visible === false) {
                console.log("WARNING: calling retrieveScrollWidth when not intended?\n%1 %2 %3 %4 %5".arg(internal.currentDomainScrollWidth).arg(webview.loading).arg(controller.autoFitToWidthEnabled).arg(controller.viewSpecificZoom).arg(menu.visible));
            }
            webview.runJavaScript("document && document.body ? document.body.scrollWidth : null", function(width) {
                console.log("[ZC]   body.scrollWidth: %1 (%2 * %3)".arg(width).arg(webview.width).arg(webview.zoomFactor));
                internal.currentDomainScrollWidth = width > 0 ? width : 0;
            });
        }

        // This timer is here because, if we want to fit to page's scrollWidth at default zoom factor, we have to wait for css, js and other stuff on page to adjust an then fit.
        property Timer autoFitToWidthTimer: Timer {
            interval: 500
            running: false
            repeat: false
            onTriggered: {
                console.log("[ZC] internal.autoFitToWidthTimer triggered");
                // Determine page's scrollWidth, save it to currentDomainScrollWidth and use it to fit to width.
                // Keep in mind that webview.zoomFactor might be diffrent than controller.currentZoomFactor.
                webview.runJavaScript("document && document.body ? document.body.scrollWidth : null", function(width) {
                    console.log("[ZC]   body.scrollWidth: %1 (%2 * %3)".arg(width).arg(webview.width).arg(webview.zoomFactor));
                    if (width === null || width <= 0) {
                        console.log("[ZC]   not autofitting, no scrollWidth");
                        // Sync zoom factors in case they are out of sync.
                        webview.zoomFactor = currentZoomFactor;
                        return;
                    }

                    internal.currentDomainScrollWidth = width;
                    var newZoomFactor = Math.max(controller.minZoomFactor, Math.min(controller.maxZoomFactor, Math.floor((webview.width / width) * 100) / 100));

                    // If newZoomFactor is to close to currentZoomFactor, don't bother to fit.
                    if (Math.abs(controller.currentZoomFactor - newZoomFactor) < 0.1) {
                        console.log("[ZC]   not autofitting, close to currentZoomFactor");
                        // Sync zoom factors in case they are out of sync.
                        webview.zoomFactor = controller.currentZoomFactor;
                        return;
                    }

                    console.log("[ZC]   newZoomFactor: %1".arg(newZoomFactor));
                    // Adjust zoom factor to fit to page's scrollWidth.
                    internal.currentZoomFactor = newZoomFactor;
                });
            }
        }

        // This timer is here because, if app is resized with mouse, we don't want to run the auto fit code every time.
        property Timer widthChangedTimer: Timer {
            interval: 200
            running: false
            repeat: false
            onTriggered: {
                // Window width has changed. Maybe fit to width needs to be reevaluated.
                console.log("[ZC] internal.widthChangedTimer triggered");
                internal.updateFitToWidth();
            }
        }

        property Connections webviewConnections: Connections {
            target: webview
            onWidthChanged: {
                // Width has changed. If currentDomainScrollWidth was retrieved up until now, it no loger is valid. Also auto fit might be needed. But not to often ;)
                console.log("[ZC] webview.onWidthChanged triggered: %1".arg(webview.width));
                if (internal.anyPageLoaded === false) {
                    console.log("[ZC]   no page was loaded")
                    return;
                }

                // Since page width changed, the scroll width is probably not valid anymore and needs to be reevaluated in future.
                internal.currentDomainScrollWidth = 0;

                if (webview.visible === false) {
                    console.log("[ZC]   webview not visible, setting flag to refresh after visible and skipping fit to width");
                    internal.refreshZoomOnWebViewVisible = true;
                    return;
                }

                internal.widthChangedTimer.restart();
            }

            onLoadingChanged: {
                // A page loading status has been changed. If it is our current page and the status is a LoadSucceededStatus, then now is our time to handle autofit or retrieve scroll width if oom menu is visible.
                console.log("[ZC] webview.onLoadingChanged: %1".arg(webview.url));
                console.log("[ZC]   webview.loading: %1".arg(webview.loading));

                // Not our current url (e.g. finished loading of page we have already navigated away from).
                if (loadRequest.url !== webview.url) {
                    return;
                }

                if (loadRequest.status !== WebEngineLoadRequest.LoadSucceededStatus) {
                    return;
                }

                // Our current page loading succeeded.
                console.log("[ZC]   webview.onLoadingChanged: LoadSucceeded");
                internal.anyPageLoaded = true;

                // This is a workaround, because sometimes a page is not zoomed after loading (happens after manual url change),
                // although the webview.zoomFactor (and currentZoomFactor) is correctly set.
                webview.zoomFactor = controller.currentZoomFactor;
                // End of workaround.

                if (webview.visible === false) {
                    console.log("[ZC]   webview not visible, setting flag to refresh after visible and skipping fit to width");
                    internal.refreshZoomOnWebViewVisible = true;
                    return;
                }

                internal.updateFitToWidth();
            }

            // Page visibility changed. If page is currently visible, check if there is a need for fit to widh updates.
            onVisibleChanged: {
                console.log("[ZC] webview.onVisibleChanged triggered: %1 (%2)".arg(webview.visible).arg(webview.url));
                if (internal.anyPageLoaded === false) {
                    console.log("  no page was loaded")
                    return;
                }
                if (webview.visible === true && internal.refreshZoomOnWebViewVisible === true) {
                    console.log("[ZC]   refreshing zoom and fit after visible");
                    internal.refreshZoomOnWebViewVisible = false;

                    // Reload zoom levels for current domain and update fit to width if needed.
                    internal.updatePageZoom();
                    internal.updateFitToWidth();
                }
            }
        }

        property Connections domainSettingsModelConnections: Connections {
            target: DomainSettingsModel

            // If database changed, reload zoomFactor according to new db.
            // This is a workaround. Because if browser runs with previously opened pages (session), the DomainSettingsModel is not initialized yet when onCurrentDomainChanged is trigerred first time. I couldn't figure out, how to initialize DomainSettingsModel prior signaling.
            onDatabasePathChanged: {
                console.log("[ZC] DomainSettingsModel.onDatabasePathChanged triggered: %1".arg(DomainSettingsModel.databasePath));
                internal.resetAndUpdate();
            }

            // This is mainly here, to handle domain ZoomFactor changes outside this zoom menu (eg. from domain specific settings in privacy settings).
            // Also this trigger on user zoom actions, so sometimes is everything up to date and zoom doesn't need any corrections.
            onDomainZoomFactorChanged: {
                console.log("[ZC] DomainSettingsModel.onDomainZoomFactorChanged triggered: %1".arg(domain));
                if (domain != controller.currentDomain) {
                    // Not my current domain changed, nothing to do here.
                    console.log("[ZC]   not my domain (%1) changed".arg(controller.currentDomain));
                    return;
                }

                // Zoom factor for current domain was changed, check if we are up to date with the change.
                internal.currentDomainZoomFactor = DomainSettingsModel.getZoomFactor(controller.currentDomain);
                if (
                    (isNaN(internal.currentDomainZoomFactor) && internal.viewSpecificZoom === false)
                    ||
                    (!isNaN(internal.currentDomainZoomFactor) && internal.viewSpecificZoom === true && internal.currentZoomFactor === internal.currentDomainZoomFactor)
                ) {
                    // Our zoom settings are up to date to domainZoomFactor, nothing to do here.
                    console.log("[ZC]   up to date");
                    return;
                }

                internal.resetAndUpdate();
            }
        }

        // This could be in controller object, but here we have all connections together.
        property Connections controllerConnections: Connections {
            target: controller

            // If current domain has changed, we have to forget about previous zoom factors and update page zoom.
            // This also means, that loading is in progress, fit to widt updates will be done there.
            onCurrentDomainChanged: {
                console.log("[ZC] controller.onCurrentDomainChanged triggered: %1".arg(controller.currentDomain));
                internal.currentDomainScrollWidth = 0;
                internal.updatePageZoom();
            }

            // To keep webview.zoomFactor in sync with currentZoomFactor.
            onCurrentZoomFactorChanged: {
                console.log("[ZC] controller.onCurrentZoomFactorChanged: %1".arg(controller.currentZoomFactor));
                webview.zoomFactor = controller.currentZoomFactor;
            }

            // If page uses defaultZoomFactor, refresh zoom and fit to width.
            onDefaultZoomFactorChanged: {
                console.log("[ZC] controller.onDefaultZoomFactorChanged: %1 (%2)".arg(controller.defaultZoomFactor).arg(webview.url));
                updateAfterDefaultZoomFactorChangedOrAutoFitToWidthEnabledChanged();
            }

            // Changed in settings.
            onAutoFitToWidthEnabledChanged: {
                console.log("[ZC] controller.onAutoFitToWidthEnabledChanged: %1".arg(controller.autoFitToWidthEnabled));
                updateAfterDefaultZoomFactorChangedOrAutoFitToWidthEnabledChanged();
            }

            function updateAfterDefaultZoomFactorChangedOrAutoFitToWidthEnabledChanged() {
                if (internal.anyPageLoaded === false) {
                    console.log("[ZC]   no page was loaded")
                    return;
                }

                if (controller.viewSpecificZoom === true) {
                    // Page has specific zoom, defaultZoomFactor change has no impact.
                    console.log("[ZC]   page has specific zoom.")
                    return;
                }

                // Page is currently in default zoom mode, call resetAndUpdate to change current zoom and handle fit to width.
                internal.resetAndUpdate();
            }
        }
    }
}

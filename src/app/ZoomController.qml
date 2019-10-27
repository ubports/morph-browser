import QtQuick 2.4
import QtWebEngine 1.7
import webbrowsercommon.private 0.1 // For DomainSettingsModel singleton.
import Ubuntu.Components.Popups 1.3 // For PopupUtils.
import "UrlUtils.js" as UrlUtils

// ZoomController object to provide zoom controll for WebViewImpl.
// Scope requirements:
//     webview:             An WebViewImpl object for zoomFactor manipulation and signal bindings.
//     browser (or webapp): An Browser (or WebApp) object for settings operations.
//     zoomMenu:            An UbuntuShape object just to see if menu si visible.
QtObject {

    // Contains domain, or scheme if webview.url has no domain.
    readonly property string currentDomain: UrlUtils.hostIs(webview.url, "") ? "scheme:" + UrlUtils.extractScheme(webview.url) : UrlUtils.extractHost(webview.url)

    readonly property real defaultZoomFactor: browser.settings ? browser.settings.zoomFactor : webapp.settings.zoomFactor
    readonly property real minZoomFactor: 0.25
    readonly property real maxZoomFactor: 5.0
    property real currentZoomFactor: defaultZoomFactor
    property bool viewSpecificZoom: false

    readonly property bool autoFitToWidthEnabled: browser.settings ? browser.settings.autoFitToWidthEnabled : webapp.settings.autoFitToWidthEnabled
    property int currentDomainScrollWidth: 0
    property real fitToWidthFactor: currentDomainScrollWidth > 0 ? Math.max(minZoomFactor, Math.min(maxZoomFactor, Math.floor((webview.width / currentDomainScrollWidth) * 100) / 100)) : NaN

    onDefaultZoomFactorChanged: {
        console.log("ZoomController.onDefaultZoomFactorChanged: %1 (%2)".arg(defaultZoomFactor).arg(webview.url));
        if (viewSpecificZoom === false) {
            // Page is currently in default zoom mode, change current zoom and handle fit to width.
            currentZoomFactor = defaultZoomFactor;
            currentDomainScrollWidth = 0;
            if (webview.loading === false) {
                if (autoFitToWidthEnabled) {
                    autoFitToWidthFromDefaultZoomFactor();
                }
                else if (zoomMenu.visible) {
                    retrieveScrollWidth();
                }
            }
        }
    }

    onAutoFitToWidthEnabledChanged: {
        console.log("ZoomController.onAutoFitToWidthEnabledChanged: %1".arg(autoFitToWidthEnabled));
        // Handling is the same as onDefaultZoomFactorChanged, so just trigger it.
        defaultZoomFactorChanged();
    }

    onCurrentZoomFactorChanged: {
        console.log("ZoomController.onCurrentZoomFactorChanged: %1".arg(currentZoomFactor));
        webview.zoomFactor = currentZoomFactor;
    }

    onFitToWidthFactorChanged: {
        console.log("ZoomController.onFitToWidthFactorChanged: %1".arg(fitToWidthFactor));
    }

    function save() {
        var confirmDialog = PopupUtils.open(Qt.resolvedUrl("ConfirmDialog.qml"), webview);
        confirmDialog.title = i18n.tr("Default Zoom")
        confirmDialog.message = i18n.tr("Set current zoom as default zoom for %1 ? (You can change it in the settings menu)".arg(isWebApp ? i18n.tr("the current web app") : "morph-browser"))
        confirmDialog.accept.connect(function() {
            if (browser.settings) {
                browser.settings.zoomFactor = currentZoomFactor;
            }
            else {
                webapp.settings.zoomFactor = currentZoomFactor;
            }
        });
    }


    property Timer autoFitToWidthTimer: Timer {
      interval: 1000
      running: false
      repeat: false
      onTriggered: {
        console.log("autoFitToWidthTimer triggered");
        autoFitToWidth();
      }
    }

    function autoFitToWidth() {
        // This function might be called when webview.zoomFactor != currentZoomFactor.
        console.log("ZoomController.autoFitToWidth called");

        // Determine scrollWidth and use it to fit to width.
        webview.runJavaScript("document && document.body ? document.body.scrollWidth : null", function(width) {
            console.log("  body.scrollWidth: %1 (%2 * %3)".arg(width).arg(webview.width).arg(webview.zoomFactor));
            if (width > 0) {
                var newZoomFactor = Math.max(minZoomFactor, Math.min(maxZoomFactor, Math.floor((webview.width / width) * 100) / 100));
                if (Math.abs(currentZoomFactor - newZoomFactor) >= 0.1) {
                    console.log("  newZoomFactor: %1".arg(newZoomFactor));
                    currentZoomFactor = newZoomFactor;
                }
                else {
                    console.log("  not autofitting, close to currentZoomFactor");
                    webview.zoomFactor = currentZoomFactor;
                }
                currentDomainScrollWidth = width;
            }
            else {
                console.log("  not autofitting, no scrollWidth");
                webview.zoomFactor = currentZoomFactor;
            }
        });
    }

    function autoFitToWidthFromDefaultZoomFactor() {
        console.log("ZoomController.autoFitToWidthFromDefaultZoomFactor called");
        // Zoom to defaultZoomFactor before determining scrollWidth, to allways get consistent numbers.
        webview.zoomFactor = defaultZoomFactor;
        autoFitToWidthTimer.restart();
    }

    function retrieveScrollWidth() {
        console.log("ZoomController.retrieveScrollWidth called");
        webview.runJavaScript("document && document.body ? document.body.scrollWidth : null", function(width) {
            console.log("  body.scrollWidth: %1 (%2 * %3)".arg(width).arg(webview.width).arg(currentZoomFactor));
            currentDomainScrollWidth = width > 0 ? width : 0;
        });
    }

    function fitToWidth() {
        console.log("ZoomController.fitToWidth: %1".arg(fitToWidthFactor));
        if (isNaN(fitToWidthFactor)) {
            console.log("  not applying");
            return;
        }

        viewSpecificZoom = true;
        currentZoomFactor = fitToWidthFactor;
        if (! webview.incognito) {
            saveZoomFactorForCurrentDomain();
        }
    }

    function reset() {
        viewSpecificZoom = false;
        currentZoomFactor = defaultZoomFactor;
    }

    function resetSaveFit() {
        reset();
        if (! webview.incognito) {
            saveZoomFactorForCurrentDomain();
        }

        currentDomainScrollWidth = 0;
        if (webview.loading === false) {
            if (autoFitToWidthEnabled && viewSpecificZoom === false) {
                autoFitToWidthFromDefaultZoomFactor();
            }
            else {
                retrieveScrollWidth();
            }
        }
    }

    function saveZoomFactorForCurrentDomain() {
        if (viewSpecificZoom) {
            DomainSettingsModel.setZoomFactor(currentDomain, currentZoomFactor);
        }
        else {
            DomainSettingsModel.setZoomFactor(currentDomain, NaN);
        }
    }

    function zoomIn() {
        viewSpecificZoom = true;
        currentZoomFactor = Math.min(maxZoomFactor, currentZoomFactor + ((Math.round(currentZoomFactor * 100) % 10 === 0) ? 0.1 : 0.1 - (currentZoomFactor % 0.1)));
        if (! webview.incognito) {
            saveZoomFactorForCurrentDomain();
        }
    }

    function zoomOut() {
        viewSpecificZoom = true
        currentZoomFactor = Math.max(minZoomFactor, currentZoomFactor - ((Math.round(currentZoomFactor * 100) % 10 === 0) ? 0.1 : currentZoomFactor % 0.1));
        if (! webview.incognito) {
            saveZoomFactorForCurrentDomain();
        }
    }

    property Timer widthChangedTimer: Timer {
        interval: 500
        running: false
        repeat: false
        onTriggered: {
            console.log("webview.widthChangedTimer triggered");
            if (webview.loading === false) {
                if (autoFitToWidthEnabled && viewSpecificZoom === false) {
                    autoFitToWidthFromDefaultZoomFactor();
                }
                else if (zoomMenu.visible) {
                    retrieveScrollWidth();
                }
            }
        }
    }
    property bool onWidthChangedFirstCall: true

    property Connections webview_onWidthChangedConnection: Connections {
        target: webview
        onWidthChanged: {
            console.log("ZoomController: webview.onWidthChanged called: %1".arg(width));
            if (onWidthChangedFirstCall) {
                // Skip first call, cause it is the webview.width init trigger and it allways happens before page is loaded.
                console.log("  skipping first call");
                onWidthChangedFirstCall = false;
                return;
            }
            currentDomainScrollWidth = 0;
            widthChangedTimer.restart();
        }
    }

    property Connections webview_onLoadingChanged: Connections {
        target: webview
        onLoadingChanged: {
            console.log("ZoomController webview.onLoadingChanged: %1".arg(webview.url));
            console.log("  webview.loading: %1".arg(webview.loading));

            // not about current url (e.g. finished loading of page we have already navigated away from)
            if (loadRequest.url !== webview.url) {
                return;
            }

            if (loadRequest.status === WebEngineLoadRequest.LoadSucceededStatus) {
                console.log("  webview.onLoadingChanged: LoadSucceeded");
                // This is a workaround, because sometimes a page is not zoomed after loading (happens after manual url change),
                // although the webview.zoomFactor (and currentZoomFactor) is correctly set.
                webview.zoomFactor = currentZoomFactor;
                // End of workaround.

                if (currentDomainScrollWidth === 0) {
                    if (autoFitToWidthEnabled && viewSpecificZoom === false) {
                        autoFitToWidthFromDefaultZoomFactor();
                    }
                    else if (zoomMenu.visible) {
                        retrieveScrollWidth();
                    }
                }
            }
        }
    }

    function zoomPageForCurrentDomain() {
        console.log("ZoomController.zoomPageForCurrentDomain called: %1".arg(currentDomain));
        if (DomainSettingsModel.databasePath === "") {
            console.log("  no database for domain settings");
            viewSpecificZoom = false;
            currentZoomFactor = defaultZoomFactor;
            return;
        }

        currentDomainScrollWidth = 0;
        var domainZoomFactor = DomainSettingsModel.getZoomFactor(currentDomain);
        if (isNaN(domainZoomFactor) ) {
            viewSpecificZoom = false;
            currentZoomFactor = defaultZoomFactor;
        }
        else {
            viewSpecificZoom = true;
            currentZoomFactor = domainZoomFactor;
        }
        console.log("  viewSpecificZoom: %1".arg(viewSpecificZoom));
        console.log("  currentZoomFactor: %1".arg(currentZoomFactor));
    }

    onCurrentDomainChanged: {
        console.log("ZoomController.onCurrentDomainChanged triggered");
        zoomPageForCurrentDomain();
    }

    property Connections domainSettingsModel_onDatabasePathChanged: Connections {
        // If database changed, reload zoomFactor according to new db.
        // This is a workaround. Because if browser runs with previously opened pages (session), the DomainSettingsModel is not initialized yet
        // when onCurrentDomainChanged is trigerred first time. I couldn't figure out, how to initialize DomainSettingsModel prior signaling.
        // So wait, until db is initialized, then trigger onCurrentDomainChanged again.
        target: DomainSettingsModel
        onDatabasePathChanged: {
            console.log("ZoomController DomainSettingsModel.onDatabasePathChanged triggered");
            zoomPageForCurrentDomain();
        }
    }
}

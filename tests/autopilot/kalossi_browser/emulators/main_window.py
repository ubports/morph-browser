class MainWindow(object):
    """An emulator class that makes it easy to interact with the camera-app."""

    def __init__(self, app):
        self.app = app

    def get_qml_view(self):
        """Get the main QML view"""
        return self.app.select_single("QQuickView")

    def get_address_bar(self):
        """Get the browsers address bar"""
        return self.app.select_single("TextField", objectName="addressBar")

    def get_address_bar_clear_button(self):
        return self.get_address_bar().get_children_by_type("AbstractButton")[0]

    def get_web_view(self):
        return self.app.select_single("QQuickWebView")

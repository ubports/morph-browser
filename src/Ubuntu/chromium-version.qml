import QtQml 2.2
import com.canonical.Oxide 1.15

QtObject {
    Component.onCompleted: console.log("[%1]".arg(Oxide.chromiumVersion))
}

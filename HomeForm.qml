import QtQuick 2.15
import QtQuick.Controls 2.12

Page {
    Image {
        source: "qrc:/images/tray.svg"
        anchors.centerIn: parent
        fillMode: Image.PreserveAspectFit
        sourceSize: Qt.size(parent.height * 0.6, parent.height * 0.6)
    }
}

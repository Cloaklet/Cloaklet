import QtQuick 2.15
import QtQuick.Controls 2.12

Page {
    Image {
        source: "qrc:/images/tray.svg"
        anchors.centerIn: parent
        fillMode: Image.PreserveAspectFit
    }

    Label {
        text: qsTr("v0.0.1")
        anchors.verticalCenterOffset: height * 3
        anchors.centerIn: parent
    }
}

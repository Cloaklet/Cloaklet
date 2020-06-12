import QtQuick 2.15
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.0

Page {
    anchors.fill: parent
    // Update this page to show info about current selected vault
    signal currentVaultChanged(var currentVault)
    onCurrentVaultChanged: {
        nameLabel.text = qsTr("Vault: %1").arg(currentVault.name)
        pathLabel.text = currentVault.path
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.bottomMargin: parent.height * 0.6
        spacing: 2

        RowLayout {
            Layout.preferredHeight: font.pixelSize * 3
            Layout.bottomMargin: font.pixelSize * 1
            Layout.leftMargin: font.pixelSize * 2
            Layout.rightMargin: font.pixelSize * 2
            spacing: 10

            Rectangle {
                Layout.preferredHeight: parent.height
                Layout.preferredWidth: parent.height
                Image {
                    id: vaultStateIcon
                    source: "qrc:/images/lock-fill-inverted.svg"
                    sourceSize: Qt.size(parent.height * 0.6, parent.height * 0.6)
                    anchors.centerIn: parent
                    visible: false
                }
                ColorOverlay {
                    source: vaultStateIcon
                    color: "#ffffff"
                    anchors.fill: vaultStateIcon
                }

                color: "#39A635"
                radius: height
                width: height
            }

            ColumnLayout {
                spacing: 5
                // FIXME
                Layout.minimumWidth: 200
//                Layout.maximumWidth: parent.width * 0.8
                Label {
                    id: nameLabel
                    text: ""
                    font.weight: Font.Bold
                    font.pointSize: 18
                }
                Label {
                    id: pathLabel
                    text: ""
                    color: "#8C8C8C"
                }
            }
            Item {
                Layout.fillWidth: true
            }

            Label {
                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                padding: 5
                id: vaultStateLabel
                text: "locked"
                font.capitalization: Font.AllUppercase
                font.weight: Font.DemiBold
                font.pointSize: 10
                color: "#ffffff"
                background: Rectangle {
                    color: "#8C8C8C"
                    radius: parent.height
                    anchors.fill: parent
                }
            }
        }

        Button {
            Layout.alignment: Qt.AlignHCenter
            leftPadding: font.pixelSize * 1.4
            rightPadding: font.pixelSize * 1.4
            icon.source: "qrc:/images/key-2-fill.svg"
            icon.color: "#ffffff"
            text: '<font color="#ffffff">Unlock...</font>'
            font.weight: Font.Medium
            font.pointSize: 18
            background: Rectangle {
                color: "#39A635"
                border.color: "#358A32"
                radius: 3
            }
        }
        Button {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -font.pixelSize * 1.2
            icon.source: "qrc:/images/settings-3-fill.svg"
            icon.height: font.pixelSize
            icon.width: font.pixelSize
            text: "Vault Options"
            background: Rectangle {
                color: "transparent"
            }
        }
    }

}

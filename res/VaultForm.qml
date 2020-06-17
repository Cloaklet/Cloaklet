import QtQuick 2.15
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.0

Page {
    id: vaultInfo
    anchors.fill: parent
    background: Rectangle {
        color: Constant.secondaryBgColor
        anchors.fill: parent
    }

    // Update this page to show info about current selected vault
    signal currentVaultChanged(var currentVault)
    onCurrentVaultChanged: {
        vault = currentVault
    }

    property var vault: ({})
    function unlockVault(password) {
        // TODO Failure notification
        var unlockRC = vaultManager.unlockVault(vault.path, password)
        if (unlockRC !== 0) {
            console.error("Unlock failed: RC=", unlockRC)
        }
    }

    Column {
        anchors.fill: parent
        spacing: 60
        padding: 20

        // Vault information block
        RowLayout {
            width: parent.width - parent.padding * 2
            implicitHeight: font.pixelSize * 3
            spacing: 10

            Rectangle {
                Layout.preferredHeight: parent.height
                Layout.preferredWidth: parent.height
                Image {
                    id: vaultStateIcon
                    source: vaultInfo.vault.unlocked ? "qrc:/res/images/lock-unlock-fill-inverted.svg" : "qrc:/res/images/lock-fill-inverted.svg"
                    sourceSize: Qt.size(parent.height * 0.6, parent.height * 0.6)
                    anchors.centerIn: parent
                    visible: false
                }
                ColorOverlay {
                    source: vaultStateIcon
                    color: Constant.bgColor
                    anchors.fill: vaultStateIcon
                }

                color: Constant.mainColor
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
                    text: vaultInfo.vault.name || ""
                    font.weight: Font.Bold
                    font.pointSize: 18
                }

                // Vault path label
                // Clicking reveals current vault in Finder
                Button {
                    hoverEnabled: true
                    Layout.preferredHeight: font.pixelSize * 1.4
                    Layout.preferredWidth: pathLabel.contentWidth + vaultRevealIcon.width
                    contentItem: Rectangle {
                        color: Constant.secondaryBgColor
                        anchors.fill: parent
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10
                            Text {
                                id: pathLabel
                                text: vaultInfo.vault.path || ""
                                color: Constant.secondaryTextColor
                            }
                            Image {
                                id: vaultRevealIcon
                                source: "qrc:/res/images/eye-fill.svg"
                                visible: false
                                sourceSize: Qt.size(width, height)
                            }
                            ColorOverlay {
                                source: vaultRevealIcon
                                color: Constant.secondaryTextColor
                                width: vaultRevealIcon.width
                                height: vaultRevealIcon.height
                                visible: parent.parent.parent.hovered
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                    onClicked: {
                        vaultManager.revealVault(vaultInfo.vault.path)
                    }
                }

            }

            Label {
                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                padding: 2
                leftPadding: 6
                rightPadding: 6
                id: vaultStateLabel
                text: vaultInfo.vault.unlocked ? "unlocked" : "locked"
                font.capitalization: Font.AllUppercase
                font.weight: Font.Bold
                font.pointSize: 10
                color: Constant.bgColor
                background: Rectangle {
                    color: vaultInfo.vault.unlocked ? Constant.mainColor : Constant.secondaryTextColor
                    radius: parent.height
                    anchors.fill: parent
                }
            }
        }

        // Vault operation buttons
        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter

            Button {
                Layout.alignment: Qt.AlignHCenter
                leftPadding: font.pixelSize * 1.4
                rightPadding: font.pixelSize * 1.4
                icon.source: "qrc:/res/images/key-2-fill.svg"
                icon.color: Constant.bgColor
                text: '<font color="' + Constant.bgColor + '">%2</font>'.arg(qsTr("Unlock"))
                font.weight: Font.Medium
                font.pointSize: 18
                background: Rectangle {
                    color: Constant.mainColor
                    border.color: Constant.themedBorderColor
                    radius: 3
                }
                onClicked: {
                    unlockVaultDialog.open()
                }
                // Only display when the vault is locked
                visible: !vaultInfo.vault.unlocked
            }
            Button {
                Layout.alignment: Qt.AlignHCenter
                icon.source: "qrc:/res/images/settings-3-fill.svg"
                icon.height: font.pixelSize * 1.2
                icon.width: font.pixelSize * 1.2
                text: "Vault Options"
                background: Rectangle {
                    color: "transparent"
                }
                // Only display when the vault is locked
                visible: !vaultInfo.vault.unlocked
            }

            Button {
                Layout.alignment: Qt.AlignHCenter
                leftPadding: font.pixelSize * 1.4
                rightPadding: font.pixelSize * 1.4
                Layout.preferredWidth: 210
                Layout.preferredHeight: 60
                contentItem: Rectangle {
                    anchors.fill: parent
                    color: Constant.mainColor
                    radius: 3
                    border.color: Constant.themedBorderColor
                    RowLayout {
                        anchors.fill: parent
                        anchors.centerIn: parent
                        anchors.leftMargin: 10
                        Image {
                            id: revealIcon
                            source: "qrc:/res/images/hard-drive-fill-inverted.svg"
                            sourceSize: Qt.size(40, 40)
                            Layout.alignment: Qt.AlignVCenter
                            visible: false
                        }
                        ColorOverlay {
                            source: revealIcon
                            color: Constant.bgColor
                            Layout.alignment: Qt.AlignVCenter
                            // Explicit size setting is required
                            height: revealIcon.height
                            width: revealIcon.width
                        }
                        ColumnLayout {
                            Text {
                                text: qsTr("Reveal Drive")
                                color: Constant.bgColor
                                font.pointSize: 18
                                font.weight: Font.Medium
                            }
                            Text {
                                id: vaultDrivePath
                                text: vaultInfo.vault.mountpoint || ""
                                color: Constant.bgColor
                                font.pointSize: 12
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
                onClicked: {
                    vaultManager.revealMountPoint(vaultInfo.vault.path)
                }
                // Only display when the vault is locked
                visible: !!vaultInfo.vault.unlocked
            }
            Button {
                Layout.alignment: Qt.AlignHCenter
                leftPadding: font.pixelSize * 2
                rightPadding: leftPadding
                icon.source: "qrc:/res/images/key-2-fill.svg"
                icon.height: font.pixelSize * 1.2
                icon.width: font.pixelSize * 1.2
                text: qsTr("Lock")
                background: Rectangle {
                    color: Constant.bgColor
                    border.color: Constant.borderColor
                    radius: 3
                }
                onClicked: {
                    if (vaultInfo.vault.unlocked) {
                        var lockRC = vaultManager.lockVault(vaultInfo.vault.path)
                        if (lockRC !== 0) {
                            console.error("Lock failed: RC=", lockRC)
                        }
                    }
                }
                // Only display when the vault is unlocked
                visible: !!vaultInfo.vault.unlocked
            }
        }
    }

    Dialog {
        id: unlockVaultDialog
        title: vaultInfo.vault.name || ""
        modal: true
        anchors.centerIn: Overlay.overlay
        onClosed: {
            vaultPassword.clear()
        }

        contentItem: Rectangle {
            RowLayout {
                anchors.fill: parent
                Layout.preferredHeight: 120
                Image {
                    source: "qrc:/res/images/lock-fill.svg"
                    Layout.preferredHeight: 80
                    Layout.preferredWidth: 80
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.rightMargin: 10
                    sourceSize: Qt.size(Layout.preferredHeight, Layout.preferredWidth)
                }
                ColumnLayout {
                    spacing: 5
                    Label {
                        id: unlockVaultDescription
                        text: qsTr("Enter password for %1:").arg(vaultInfo.vault.name)
                    }
                    TextField {
                        id: vaultPassword
                        echoMode: TextInput.Password
                        text: ""
                        onVisibleChanged: {
                            visible && forceActiveFocus()
                        }
                        Keys.onReturnPressed: {
                            vaultInfo.unlockVault(text)
                            unlockVaultDialog.close()
                        }
                    }
                    RowLayout {
                        spacing: 0
                        Button {
                            text: qsTr("Cancel")
                            onClicked: {
                                unlockVaultDialog.close()
                            }
                            Layout.alignment: Qt.AlignLeft
                            hoverEnabled: true
                            highlighted: hovered || activeFocus
                        }
                        Button {
                            text: qsTr("Unlock")
                            onClicked: {
                                vaultInfo.unlockVault(vaultPassword.text)
                                unlockVaultDialog.close()
                            }
                            Layout.alignment: Qt.AlignRight
                            hoverEnabled: true
                            highlighted: hovered || activeFocus
                        }
                    }
                }
            }
        }
    }

}

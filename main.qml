import QtQuick 2.15
import QtQuick.Controls 2.12
import QtQuick.LocalStorage 2.12
import QtQuick.Dialogs 1.2 as Dialogs
import Qt.labs.platform 1.1 as Platform
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    visible: true
    width: 640
    height: 480
    title: Constant.appName
    flags: Qt.FramelessWindowHint

    function openDB() {
        var db = LocalStorage.openDatabaseSync("info.mynook.Cloaklet", "1.0", "Cloaklet data", 1000000, function(db){
            console.info("Database does not exist")
            db.transaction(function(tx){
                tx.executeSql(`CREATE TABLE IF NOT EXISTS vaults (name TEXT, path TEXT NOT NULL UNIQUE, mount_options TEXT)`)
            })
            db.changeVersion("", "1.0")
            console.info("Database created")
        })
        console.info("DB opened:", db)
        return db
    }

    header: ToolBar {
        id: titleBar
        background: Rectangle {
            color: Constant.mainColor
        }
        width: window.width
        height: 50
        MouseArea {
            anchors.fill: parent
            property var clickPosition
            onPressed: {
                clickPosition = { x: mouse.x, y: mouse.y }
            }
            onPositionChanged: {
                var currentPos = mousePosition.cursorPos()
                window.x = currentPos.x - clickPosition.x
                window.y = currentPos.y - clickPosition.y
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0
            Text {
                text: Qt.application.displayName
                color: Constant.bgColor
                font.pointSize: 20
                font.weight: Font.Medium
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: font.pixelSize
            }

            // Close button hides app window
            Button {
                id: closeButton
                Layout.preferredWidth: parent.height
                Layout.preferredHeight: parent.height
                Layout.alignment: Qt.AlignRight
                icon.source: "qrc:/images/close-fill.svg"
                icon.color: Constant.bgColor
                background: Rectangle {
                    color: "transparent"
                }
                onClicked: {
                    window.hide()
                }
                RotationAnimation on rotation {
                    from: 0
                    to: 90
                    duration: 100
                    // There might be a more reasonable way to reference properties of parent component,
                    // which enables us to add animation to reusable components,
                    // but I have yet to find it.
                    running: closeButton.hovered
                }
                RotationAnimation on rotation {
                    from: 90
                    to: 0
                    duration: 100
                    running: !closeButton.hovered
                }
                hoverEnabled: true
            }
        }
    }

    Drawer {
        id: drawer
        width: window.width * 0.3
        height: window.height - titleBar.height
        topMargin: titleBar.height

        modal: false
        interactive: false
        position: 1
        visible: true
        clip: true

        // This simulates a single border on the right
        background: Rectangle {
            anchors.fill: parent
            anchors.leftMargin: -border.width
            anchors.topMargin: -border.width
            anchors.bottomMargin: -border.width
            border.color: Constant.borderColor
        }

        ListView {
            property var currentVault: ({})
            id: vaultList
            anchors.fill: parent

            delegate: ItemDelegate {
                font.weight: Font.Medium
                font.pointSize: 13
                text: model.name
                width: parent.width
                icon.source: "qrc:/images/lock-fill.svg"
                icon.height: font.pixelSize * 1.6
                icon.width: font.pixelSize * 1.6
                icon.color: highlighted ? Constant.mainColor : Constant.secondaryTextColor
                highlighted: vaultList.currentVault.name === model.name
                clip: true
                background: Rectangle {
                    color: parent.highlighted ? Constant.themedSelectionBgColor : Constant.bgColor
                    border.color: Constant.mainColor
                    border.width: parent.highlighted ? 3 : 0
                    anchors.topMargin: -border.width
                    anchors.bottomMargin: -border.width
                    anchors.rightMargin: -border.width
                    anchors.fill: parent
                }

                onClicked: {
                    // If already showing vault info, do not change stackView
                    if (stackView.currentItem.objectName !== "vaultInfo") {
                        stackView.replace("VaultForm.qml", {objectName: "vaultInfo"}, StackView.Immediate)
                    }
                    // Replacing key-value won't trigger onchange, we have to replace the whole property variable
                    vaultList.currentVault = {
                        name: model.name,
                        path: model.path,
                        mount_options: model.mount_options
                    }
                }
            }
            onCurrentVaultChanged: {
                if (stackView.currentItem && stackView.currentItem.objectName === "vaultInfo") {
                    stackView.currentItem.currentVaultChanged(currentVault)
                }
            }
            model: ListModel {
                id: vaultListModel
                Component.onCompleted: {
                    openDB().transaction(function(tx){
                        // Init database tables
                        var rs = tx.executeSql(`SELECT * FROM vaults`)
                        for (var i = 0; i < rs.rows.length; i ++) {
                            var row = rs.rows.item(i)
                            console.info(row)
                            append({
                                name: row.name,
                                path: row.path,
                                mount_options: JSON.parse(row.mount_options)
                            })
                        }
                    })
                }
            }
            footer: ItemDelegate {
                id: addVault
                width: parent.width
                text: qsTr("Add Vault")
                icon.source: "qrc:/images/add-fill.svg"
                highlighted: addVaultDialog.visible
                onClicked: {
                    addVaultDialog.open()
                }
            }
        }
    }

    StackView {
        id: stackView
        initialItem: "HomeForm.qml"
        anchors.fill: parent
        width: window.width * 0.7
        anchors.leftMargin: window.width * 0.3
    }

    Dialog {
        id: addVaultDialog
        modal: true
        implicitWidth: window.width * 0.8
        anchors.centerIn: Overlay.overlay
        title: qsTr("Add Vault")
        contentItem: Image {
            fillMode: Image.PreserveAspectFit
            source: "qrc:/images/tray.svg"
        }
        footer: DialogButtonBox {
            position: DialogButtonBox.Footer
            buttonLayout: DialogButtonBox.MacLayout
            Button {
                text: qsTr("Create New Vault")
                icon.source: "qrc:/images/magic-fill.svg"
                onClicked: {
                    createNewVault.open()
                }
            }
            Button {
                text: qsTr("Add Existing Vault")
                icon.source: "qrc:/images/folder-5-fill.svg"
                onClicked: {
                    selectExistingVault.open()
                }
            }
        }
    }
    Dialogs.FileDialog {
        id: selectExistingVault
        title: qsTr("Load vault from selected GoCryptFS config file")
        folder: shortcuts.documents
        nameFilters: ["GoCryptFS config file (gocryptfs.conf)"]
        selectExisting: true
        onAccepted: {
            console.log("selected:", fileUrl)
            var path = decodeURIComponent(folder.toString().replace(/^(file:\/{3})/, ""))
            var dirname = path.slice(path.lastIndexOf("/") + 1)
            openDB().transaction(function(tx){
                tx.executeSql(`INSERT INTO vaults VALUES (?, ?, ?)`, [dirname, path, JSON.stringify({})])
                vaultListModel.append({name: dirname, path: path, mount_options: "{}"})
                console.log("Loaded vault from:", path)
                addVaultDialog.close()
            })
        }
    }
    Dialogs.FileDialog {
        id: createNewVault
        title: qsTr("Create new vault inside selected directory")
        folder: shortcuts.documents
        selectFolder: true
        onAccepted: {
            console.log("selected:", folder)
            var path = decodeURIComponent(folder.toString().replace(/^(file:\/{3})/, ""))
            var dirname = path.slice(path.lastIndexOf("/") + 1)
            // FIXME Create new vault before inserting into database
            openDB().transaction(function(tx){
                tx.executeSql(`INSERT INTO vaults VALUES (?, ?, ?)`, [dirname, path, JSON.stringify({})])
                vaultListModel.append({name: dirname, path: path, mount_options: "{}"})
                console.log("Loaded vault from:", path)
                addVaultDialog.close()
            })
        }
    }

    Platform.SystemTrayIcon {
        visible: true
        icon.source: "qrc:/images/tray.svg"
        menu: Platform.Menu {
            Platform.MenuItem {
                text: qsTr("Show")
                onTriggered: window.show()
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: qsTr("Quit")
                onTriggered: Qt.quit()
            }
        }
    }
}

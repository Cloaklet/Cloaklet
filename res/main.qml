import QtQuick 2.15
import QtQuick.Controls 2.12
import QtQuick.LocalStorage 2.12
import QtQuick.Dialogs 1.2 as Dialogs
import Qt.labs.platform 1.1 as Platform
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import MousePos 1.0
import VaultManager 1.0

ApplicationWindow {
    id: window
    visible: true
    width: 640
    height: 480
    title: Constant.appName
    flags: Qt.FramelessWindowHint

    VaultManager {
        id: vaultManager
        onVaultUnlocked: (path, mountpoint) => {
            for (var i = 0; i < vaultListModel.count; i ++) {
                var item = vaultListModel.get(i)
                if (item.path === path) {
                    item.unlocked = true
                    item.mountpoint = mountpoint
                    console.log("Vault", item.name, "unlocked, mountpoint:", mountpoint)
                    break
                }
            }

        }
        onVaultLocked: (path) => {
            for (var i = 0; i < vaultListModel.count; i ++) {
                var item = vaultListModel.get(i)
                if (item.path === path) {
                    item.unlocked = false
                    item.mountpoint = ""
                    console.log("Vault", item.name, "locked")
                    break
                }
            }
        }
        onAlert: (msg) => {
            alertMessageText.text = msg
        }
    }

    MousePos {
        id: mousePos
    }

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
                var currentPos = mousePos.pos()
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
                icon.source: "qrc:/res/images/close-fill.svg"
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
                icon.source: model.unlocked ? "qrc:/res/images/lock-unlock-fill.svg" : "qrc:/res/images/lock-fill.svg"
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
                        stackView.currentItem.onPaint
                    }
                    // Replacing key-value won't trigger onchange, we have to replace the whole property variable
                    vaultList.currentVault = model
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
                                mount_options: JSON.parse(row.mount_options),
                                unlocked: false,
                                mountpoint: ""
                            })
                        }
                    })
                }
            }
            footer: ItemDelegate {
                width: parent.width
                text: qsTr("Add Vault")
                icon.source: "qrc:/res/images/add-fill.svg"
                highlighted: addVaultDialog.visible
                onClicked: {
                    addVaultDialog.open()
                }
                background: Rectangle {
                    anchors.fill: parent
                    color: Constant.secondaryBgColor
                    border.color: Constant.borderColor
                    anchors.leftMargin: -border.width
                    anchors.rightMargin: -border.width
                    anchors.bottomMargin: -border.width
                }
            }
            footerPositioning: ListView.OverlayFooter
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
        contentItem: Rectangle {
            anchors.bottomMargin: 30
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: parent.width * 0.8
                    text: qsTr("Create New Vault")
                    icon.source: "qrc:/res/images/magic-fill.svg"
                    onClicked: {
                        createNewVault.open()
                    }
                }
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: parent.width * 0.8
                    text: qsTr("Add Existing Vault")
                    icon.source: "qrc:/res/images/folder-5-fill.svg"
                    onClicked: {
                        selectExistingVault.open()
                    }
                }
            }
        }
    }
    Dialog {
        id: createNewVault
        modal: true
        anchors.centerIn: Overlay.overlay
        title: qsTr("Create New Vault")
        contentItem: Rectangle {
            anchors.margins: 20
            GridLayout {
                anchors.fill: parent
                columns: 3

                Label {
                    text: qsTr("Name:")
                }
                TextField {
                    id: newVaultNameField
                    onVisibleChanged: {
                        visible && forceActiveFocus()
                    }
                    Layout.columnSpan: 2
                }

                Label {
                    text: qsTr("Location:")
                }
                TextField {
                    id: newVaultLocationField
                    readOnly: true
                }
                Button {
                    icon.source: "qrc:/res/images/folder-5-fill.svg"
                    onClicked: {
                        selectNewVaultDirectory.open()
                    }
                    Layout.preferredWidth: font.pixelSize * 4
                }

                Label {
                    text: qsTr("Password:")
                }
                TextField {
                    id: newVaultPasswordField
                    echoMode: TextField.Password
                    Layout.columnSpan: 2
                }

                Label {}  // This is just a placeholder to push button to 2nd column
                Button {
                    text: qsTr("Create Vault")
                    onClicked: {
                        // Form validation
                        var name = newVaultNameField.text.trim()
                        if (!name) {
                            newVaultFormValidationMsg.text = qsTr("Please provide a name for this vault")
                            return newVaultFormValidationMsg.open()
                        }

                        var location = newVaultLocationField.text.trim()
                        if (!location) {
                            newVaultFormValidationMsg.text = qsTr("Please select a location to store this vault")
                            return newVaultFormValidationMsg.open()
                        }

                        var password = newVaultPasswordField.text
                        if (!password) {
                            newVaultFormValidationMsg.text = qsTr("Please provide a password for this vault")
                            return newVaultFormValidationMsg.open()
                        }

                        // Create vault
                        enabled = false
                        var createRC = vaultManager.createNewVault(name, location, password)
                        if (createRC !== 0) {
                            newVaultFormValidationMsg.text = qsTr("Vault creation failed, return code: %1").arg(createRC)
                            enabled = true
                            return newVaultFormValidationMsg.open()
                        }

                        // Store vault info
                        openDB().transaction(function(tx){
                            var path = location+"/"+name
                            tx.executeSql(`INSERT INTO vaults VALUES (?, ?, ?)`, [name, path, JSON.stringify({})])
                            vaultListModel.append({name: name, path: path, mount_options: "{}", unlocked: false, mountpoint: ""})
                            console.log("Vault created:", path)

                            // Reset form
                            newVaultNameField.clear()
                            newVaultLocationField.clear()
                            newVaultPasswordField.clear()
                            newVaultFormValidationMsg.text = ""
                            enabled = true

                            // Hide dialogs
                            createNewVault.close()
                            addVaultDialog.close()
                        })
                    }
                }

            }

        }
        // This dialog pops up when the "new vault" form failed to validate
        Dialogs.MessageDialog {
            id: newVaultFormValidationMsg
            title: qsTr("Oops")
        }
    }

    // Dialog to select an existing gocryptfs vault
    Dialogs.FileDialog {
        id: selectExistingVault
        title: qsTr("Load vault from selected GoCryptFS config file")
        folder: shortcuts.documents
        nameFilters: ["GoCryptFS config file (gocryptfs.conf)"]
        selectExisting: true
        onAccepted: {
            console.log("selected:", fileUrl)
            var path = decodeURIComponent(folder.toString().replace(/^(file:\/{2})/, ""))
            var dirname = path.slice(path.lastIndexOf("/") + 1)
            openDB().transaction(function(tx){
                tx.executeSql(`INSERT INTO vaults VALUES (?, ?, ?)`, [dirname, path, JSON.stringify({})])
                vaultListModel.append({name: dirname, path: path, mount_options: "{}", unlocked: false, mountpoint: ""})
                console.log("Loaded vault from:", path)
                addVaultDialog.close()
            })
        }
    }
    // Dialog to create a gocryptfs vault in selected directory
    Dialogs.FileDialog {
        id: selectNewVaultDirectory
        title: qsTr("Create new vault inside selected directory")
        folder: shortcuts.documents
        selectFolder: true
        selectExisting: true
        onAccepted: {
            console.log("selected:", folder)
            var path = decodeURIComponent(folder.toString().replace(/^(file:\/{2})/, ""))
            newVaultLocationField.text = path
        }
    }

    Platform.SystemTrayIcon {
        visible: true
        icon.source: "qrc:/res/images/tray.svg"
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
    // Global alert, like toast on Android
    Popup {
        id: alert
        visible: false
        padding: 0
        x: parent.width - width
        y: parent.height - height
        rightMargin: 20
        bottomMargin: 20
        closePolicy: Popup.NoAutoClose
        background: Item {
            Rectangle {
                color: Constant.mainColor
                anchors.fill: parent
                id: alertBackground
            }
            DropShadow {
                anchors.fill: parent
                source: alertBackground
                radius: 6
                smooth: true
                color: Constant.themedBorderColor
            }
        }

        // Alert message automatically times out
        Timer {
            id: timeout
            repeat: false
            interval: 3000
            onTriggered: {
                alert.close()
                alertMessageText.text = ""
            }
        }

        contentItem: Text {
            id: alertMessageText
            color: Constant.secondaryBgColor
            font.pointSize: 16
            anchors.fill: parent
            text: ""
            padding: font.pixelSize / 3
            leftPadding: font.pixelSize
            rightPadding: font.pixelSize
            onTextChanged: {
                if (text.length > 0) {
                    alert.open()
                    timeout.restart()
                }
            }
        }
    }

}

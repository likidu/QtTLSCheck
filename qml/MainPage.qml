import QtQuick 1.0

Rectangle {
    id: root
    width: 360
    height: 640
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#2f3f6d" }
        GradientStop { position: 1.0; color: "#12192b" }
    }

    property string statusText: qsTr("Tap to start the TLS 1.2 check.")
    property bool lastOk: true

    Rectangle {
        id: titleBar
        width: parent.width
        height: 64
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0c111e" }
            GradientStop { position: 1.0; color: "#1b243c" }
        }

        Text {
            anchors.centerIn: parent
            text: qsTr("Qt TLS Check")
            font.pixelSize: 24
            font.bold: true
            color: "#f0f4ff"
        }
    }

    Column {
        id: content
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 24
        width: parent.width - 64
        anchors.verticalCenterOffset: 24

        Rectangle {
            id: runButton
            width: content.width
            height: 72
            radius: 12
            border.width: 1
            border.color: "#0b3e7c"
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#6fc1ff" }
                GradientStop { position: 1.0; color: "#2574c7" }
            }
            opacity: runArea.pressed || tlsChecker.running ? 0.8 : 1.0

            Text {
                anchors.centerIn: parent
                text: tlsChecker.running ? qsTr("Checking...") : qsTr("Run TLS Check")
                font.pixelSize: 20
                font.bold: true
                color: "#ffffff"
            }

            MouseArea {
                id: runArea
                anchors.fill: parent
                enabled: !tlsChecker.running
                onClicked: {
                    root.lastOk = true;
                    root.statusText = qsTr("Running TLS check...");
                    tlsChecker.startCheck();
                }
            }
        }

        Item {
            width: content.width
            height: 40

            Rectangle {
                id: spinner
                anchors.centerIn: parent
                width: 28
                height: 28
                radius: 14
                color: "transparent"
                border.width: 2
                border.color: "#9ebcf5"
                visible: tlsChecker.running
                smooth: true

                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: "#e8f1ff"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                }

                NumberAnimation on rotation {
                    running: tlsChecker.running
                    from: 0
                    to: 360
                    duration: 900
                    loops: Animation.Infinite
                }
            }
        }

        Text {
            id: statusLabel
            width: content.width
            text: root.statusText
            color: root.lastOk ? "#dff6ff" : "#ffd6d9"
            font.pixelSize: 18
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Connections {
        target: tlsChecker
        onFinished: {
            root.lastOk = ok;
            root.statusText = message;
        }
        onRunningChanged: {
            if (tlsChecker.running) {
                root.lastOk = true;
                root.statusText = qsTr("Running TLS check...");
            }
        }
    }
}

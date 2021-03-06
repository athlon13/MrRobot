import QtQuick 2.0
import Ubuntu.Components 1.1
import QtSensors 5.0
import QtMultimedia 5.0
import Qt.WebSockets 1.0
import MrRobot 1.0

/*!
    \brief MainView of MsRobot
*/

MainView {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "mrrobot.e"

    /*
     This property enables the application to change orientation
     when the device is rotated. The default is false.
    */
    //automaticOrientation: true

    // Removes the old toolbar and enables new features of the new header.
    useDeprecatedToolbar: false

    width: units.gu(100)
    height: units.gu(75)

    function sendCommand(msg) {
        console.debug(msg)
        if (socket.status == WebSocket.Open) {
            socket.sendTextMessage(msg)
        } else {
            console.debug("active")
            socket.active = false
            socket.active = true
        }
    }

    PageStack {
        id: stack
        Component.onCompleted: push(home)

        WebSocket {
            id: socket
            url: "ws://192.168.1.101:9099"
            onTextMessageReceived: {
                console.debug("websocket rx:" + msg)
            }
            onStatusChanged: {
                if (socket.status == WebSocket.Error) {
                    console.log("websocket error")
                } else if (socket.status == WebSocket.Open) {
                    console.debug("websocket opened")
                    socket.sendTextMessage("blue")
                    eye_image.source = "eye_blue.png"
                    eye_image.visible = true
                } else if (socket.status == WebSocket.Closed) {
                    console.log("websocket closed")
                    eye_image.visible = false

                    // stack.pop(dashboard)
                }
            }
            active: false
        }

        Page {
            id: home
            title: i18n.tr("MrRobot")
            visible: false

            Column {
                spacing: units.gu(1)
                anchors {
                    margins: units.gu(2)
                    fill: parent
                }

                TextInput {
                    id: ip
                    width: parent.width
                    height: units.gu(4)
                    text: "192.168.1.108"
                }

                Button {
                    id: connect_button
                    width: parent.width
                    height: units.gu(6)

                    text: i18n.tr("Connect")

                    onClicked: {
                        console.debug("try to connect " + ip.text)
                        socket.url = "ws://" + ip.text + ":9099"
                        socket.active = false
                        socket.active = true

                        stack.push(dashboard)
                    }
                }
            }
        }

        Page {
            id: dashboard
            visible: false

            AudioRecorder {
                id: audio
                name: "sample.wav"

                onRecordingChanged: {
                    console.debug("recording: " + recording);
                }
            }

            VoiceRecogination {
                id: ai
            }

            MediaPlayer {
                id: player
                autoPlay: true
                volume: 1.0
            }

            Image {
                id: base_image
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.height / 4

                source: "background.png"
            }

            Image {
                anchors.top: parent.top
                anchors.bottom: base_image.top
                width: parent.width

                source: "background_orange.png"
            }



            Image {
                id: robot_image
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.margins: units.gu(2)
                width: parent.width
                fillMode: Image.PreserveAspectFit
                source: "robot.png"

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        ai.request(audio.name)

                        sendCommand("robot")
                    }
                }


                // body
                MouseArea {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width / 2
                    height: parent.height / 2
                    onClicked: {
                        parent.source = "robot.png"

                        sendCommand("body")
                    }
                }

                // right hand
                MouseArea {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    width: parent.width / 5
                    height: parent.height / 2
                    onClicked: {
                        parent.source = "robot_right.png"
                        sendCommand("right")
                    }
                }

                // left hand
                MouseArea {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    width: parent.width / 5
                    height: parent.height / 2
                    onClicked: {
                        parent.source = "robot_left.png"
                        sendCommand("left")
                    }
                }
            }

            Image {
                id: eye_image
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.margins: units.gu(2)
                width: parent.width
                fillMode: Image.PreserveAspectFit
                visible: false
                source: "eye_blue.png"

                MouseArea {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width / 2
                    height: parent.height / 3
                    onClicked: {
                        var image_name = parent.source.toString()
                        if (image_name.search("eye_blue.png") > 0) {
                            parent.source = "eye_green.png"
                            sendCommand("green")
                        } else if (image_name.search("eye_green.png") > 0) {
                            parent.source = "eye_orange.png"
                            sendCommand("orange")
                        } else {
                            parent.source = "eye_blue.png"
                            sendCommand("blue")
                        }
                    }
                }
            }

            Image {
                id: voice_image
                anchors.bottom: base_image.bottom
                anchors.top: base_image.top
                anchors.margins: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter
                width: base_image.width
                fillMode: Image.PreserveAspectFit
                source: "voice.png"

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (audio.recording) {
                            console.debug("stop recording")
                            voice_image.source = "voice.png"
                            audio.stop()

                            ai.request(audio.name);

                            player.source = "end.wav";
                            player.play();
                        } else {
                            console.debug("recording")
                            voice_image.source = "voice_active.png"
                            player.source = "start.wav";
                            player.play();

                            audio.record()
                        }
                    }
                }
            }



            SensorGesture{
                gestures : ["QtSensors.shake", "QtSensors.pickup", "QtSensors.twist", "QtSensors.slam"]
                enabled: true
                onDetected:{
                    sendCommand(gesture)
                }
            }

        }
    }
}


/* 
MIT License

Copyright (c) 2020 Nils DEYBACH & Léo OUDART

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. 
*/

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick3D 1.15
import QtQuick3D.Helpers 1.15
import Qt.labs.settings 1.0

//import "./src/qml/"

Page{
    id: root
    background: Rectangle{
        radius: 10
        color: backgroundColor
    }
    leftPadding: 20
    rightPadding: 20
    required property var view3D
    required property var cam
    required property var axes
    required property bool running
    property var camVisualizer: camVisualizer
    default property alias content: root.contentItem
    padding: Math.round(root.background.radius/2)+4
    transformOrigin: Item.BottomRight

    function refresh(viewCtrlsHolder, forward){
        viewCtrlsHolder.camVisualizer.lookAt(Qt.vector3d(0,0,0))
        viewCtrlsHolder.camVisualizer.position = forward.normalized().times(-150)
    }
    function reset(viewCtrlsHolder,cam){
        viewCtrlsHolder.cam.position = Qt.vector3d(0,0,0)
        viewCtrlsHolder.cam.lookAt(Qt.vector3d(1,0,0))
    }
    signal refreshMiniFrame()

    contentItem: GridLayout{
        id: grid
        columns:3
        rows: 3
        GridLayout{
            id: viewSelector
            Layout.row:0
            Layout.column: 0
            Layout.columnSpan: 2
            Layout.rowSpan: 1
            Layout.maximumWidth: 400
            Layout.fillWidth: true
            columnSpacing: 0
            rowSpacing: 0
            //Layout.preferredHeight: maxButtonsTextRect.height*2+40

            function maxButtonTextRect(viewSelector, textMetrics){
                var maxRect = Qt.rect(0, 0, 0, 0)
                for (var i = 0; i < viewSelector.children.length; i++){
                    textMetrics.text = viewSelector.children[i].text
                    textMetrics.font = viewSelector.children[i].font
                    if(maxRect.width < textMetrics.width) maxRect.width = textMetrics.width
                    if(maxRect.height < textMetrics.height) maxRect.height = textMetrics.height
                }
                return maxRect
            }

            property var maxButtonsTextRect: Qt.rect(0, 0, 20, 20)
            Component.onCompleted: maxButtonsTextRect = Qt.rect(0, 0, maxButtonTextRect(viewSelector, textMetrics).width+topViewButton.padding+6, maxButtonTextRect(viewSelector, textMetrics).height)
            TextMetrics { id: textMetrics; }
            
            Button {
                id: topViewButton
                Layout.preferredWidth: viewSelector.maxButtonsTextRect.width
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                Layout.row:0
                Layout.column: 0
                text: "Top"
                icon.source: "qrc:/icons/top"
                display: AbstractButton.IconOnly
                onClicked: [root.cam.position=Qt.vector3d(0,500,0),root.cam.lookAt(Qt.vector3d(0,0,0)), root.refreshMiniFrame()]

                hoverEnabled: true
                Rectangle{
                    anchors.bottom: parent.top
                    //anchors.bottomMargin:0
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    ToolTip{
                        delay: 1000
                        timeout: 2500
                        visible: topViewButton.hovered
                        text: qsTr("Top")
                        background: Rectangle{color:backgroundColor}
                    }
                } 
            }

            Button{
                id: botBoutton
                Layout.preferredWidth: viewSelector.maxButtonsTextRect.width
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                Layout.row:1
                Layout.column: 0
                text:"Bottom"
                icon.source: "qrc:/icons/bottom"
                display: AbstractButton.IconOnly
                onClicked: [cam.position=Qt.vector3d(0,-500,0),cam.lookAt(Qt.vector3d(0,0,0)), root.refreshMiniFrame()]
                hoverEnabled: true
                Rectangle{
                    anchors.bottom: parent.top
                    anchors.bottomMargin:0
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    ToolTip{
                        delay: 1000
                        timeout: 2500
                        visible: botBoutton.hovered
                        text: qsTr("Bottom")
                        background: Rectangle{color:backgroundColor}
                    }
                }
            }

            Button{
                id: rightButton
                Layout.preferredWidth: viewSelector.maxButtonsTextRect.width
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                Layout.row:0
                Layout.column: 1
                text:"Right"
                icon.source: "qrc:/icons/right"
                display: AbstractButton.IconOnly
                onClicked: [cam.position=Qt.vector3d(0,0,-500),cam.lookAt(Qt.vector3d(0,0,0)), root.refreshMiniFrame()]
                hoverEnabled: true
                Rectangle{
                    anchors.bottom: parent.top
                    //anchors.bottomMargin:5
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    ToolTip{
                        delay: 1000
                        timeout: 2500
                        visible: rightButton.hovered
                        text: qsTr("Right")
                        background: Rectangle{color:backgroundColor}
                    }
                }
            }
            Button{
                id: leftButton
                Layout.preferredWidth: viewSelector.maxButtonsTextRect.width
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                Layout.row:1
                Layout.column:1
                text:"Left"
                icon.source: "qrc:/icons/left"
                display: AbstractButton.IconOnly
                onClicked: [cam.position=Qt.vector3d(0,0,500),cam.lookAt(Qt.vector3d(0,0,0)), root.refreshMiniFrame()]
                hoverEnabled: true
                Rectangle{
                    anchors.bottom: parent.top
                    //anchors.bottomMargin:0
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    ToolTip{
                        delay: 1000
                        timeout: 2500
                        visible: leftButton.hovered
                        text: qsTr("Left")
                        background: Rectangle{color:backgroundColor}
                    }
                }
            }

            Button{
                id: frontButton
                Layout.preferredWidth: viewSelector.maxButtonsTextRect.width
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                Layout.row:0
                Layout.column: 2
                text: "Front"
                icon.source: "qrc:/icons/front"
                display: AbstractButton.IconOnly
                onClicked: [cam.position=Qt.vector3d(500,0,0),cam.lookAt(Qt.vector3d(0,0,0)), root.refreshMiniFrame()]
                hoverEnabled: true
                Rectangle{
                    anchors.bottom: parent.top
                    //anchors.bottomMargin:5
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    ToolTip{
                        delay: 1000
                        timeout: 2500
                        visible: frontButton.hovered
                        text: qsTr("Front")
                        background: Rectangle{color:backgroundColor}
                    }
                }
            }
            Button{
                id: backButton
                Layout.preferredWidth: viewSelector.maxButtonsTextRect.width
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                Layout.row:1
                Layout.column: 2
                text: "Rear"
                icon.source: "qrc:/icons/rear"
                display: AbstractButton.IconOnly
                onClicked: [cam.position=Qt.vector3d(-500,0,0),cam.lookAt(Qt.vector3d(0,0,0)), root.refreshMiniFrame()]
                hoverEnabled: true
                Rectangle{
                    anchors.bottom: parent.top
                    //anchors.bottomMargin:0
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    ToolTip{
                        delay: 1000
                        timeout: 2500
                        visible: backButton.hovered
                        text: qsTr("Rear")
                        background: Rectangle{color:backgroundColor}
                    }
                }
            }
        }

        Column {
            id: gridSelector
            Settings{
                category: "checkBoxes"
                property alias parentBox: parentBox.checkState
                property alias xyBoxe: xyBoxe.checkState
                property alias xzBoxe: xzBoxe.checkState
                property alias yzBoxe: yzBoxe.checkState
            }
            Layout.row:1
            Layout.column:0
            spacing: -15
            ButtonGroup {
                id: childGroup
                exclusive: false
                checkState: parentBox.checkState
            }

            CheckBox {
                id: parentBox
                text: qsTr("All")
                checkState: childGroup.checkState
            }

            CheckBox {
                id: xyBoxe
                text: qsTr("XY Grid")
                leftPadding: indicator.width
                ButtonGroup.group: childGroup
                checked: true
                onCheckStateChanged:{
                    if (checkState === Qt.Checked)
                        return axes.enableXYGrid=true
                    else
                        return axes.enableXYGrid=false
                }

            }

            CheckBox {
                id: xzBoxe
                text: qsTr("XZ Grid")
                leftPadding: indicator.width
                ButtonGroup.group: childGroup
                
                onCheckStateChanged:{
                    if (checkState === Qt.Checked)
                        return axes.enableXZGrid=true
                    else
                        return axes.enableXZGrid=false
                }
            }
            CheckBox {
                id: yzBoxe
                text: qsTr("YZ Grid")
                leftPadding: indicator.width
                ButtonGroup.group: childGroup
                onCheckStateChanged:{
                    if (checkState === Qt.Checked)
                        return axes.enableYZGrid=true
                    else
                        return axes.enableYZGrid=false
                }
            }
        }
        Settings {
                category : "smallAxes"
                property alias axisSelector: axisSelector.checked
            }
        Switch{
            id: axisSelector
            
            Layout.row:2
            Layout.column: 0
            Layout.fillHeight: true
            text: "axes"
            checked:true
            onPositionChanged:{
                if (position === 1.0)
                        return axes.enableAxisLines=true
                    else
                        return axes.enableAxisLines=false                
            }
        }

        Button{
            id: homeButton
            text: "Home"
            icon.source: "qrc:/icons/home"
            display: AbstractButton.IconOnly
            Layout.row:0
            Layout.column:2
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            //onClicked: [cam.position=Qt.vector3d(0,0,0),root.refreshMiniFrame()]
            onClicked:[reset(viewCtrlsHolder,cam),root.refreshMiniFrame()]
            
            hoverEnabled: true
            Rectangle{
                anchors.bottom: homeButton.top
                anchors.bottomMargin:5
                anchors.horizontalCenter: parent.horizontalCenter
                color: "transparent"
                ToolTip{
                    delay: 1000
                    timeout: 2500
                    visible: homeButton.hovered
                    background: Rectangle{color:backgroundColor}
                    text: qsTr("Home")
                }                
            }
        }

        Rectangle{
            id: miniAxisViewer
            Layout.row: 1
            Layout.column: 2
            Layout.columnSpan: 1
            Layout.rowSpan: 1
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: 100
            color: "transparent"
            View3D{
                anchors.fill: parent
                renderMode: View3D.Inline
                environment: SceneEnvironment {
                    backgroundMode: SceneEnvironment.Transparent
                }
                DirectionalLight {
                    ambientColor: Qt.rgba(1.0, 1.0, 1.0, 1.0)
                }
                PerspectiveCamera {
                    id: camVisualizer
                    fieldOfViewOrientation: Camera.Horizontal
                }
                ArrowModel{
                    length: 50
                    color: "green"
                    eulerRotation.y:90
                }

                ArrowModel{
                    length:50
                    color: "blue"
                    eulerRotation.z:90
                }
                ArrowModel{
                    length:50
                    color: "red"                    
                }
            }
        }
        Column{
            id: posGroup
            //Layout.topMargin:5
            topPadding:10           
            Layout.row:1
            Layout.column:1
            Layout.rowSpan:2
            Layout.fillHeight: true            
            SpinBox{
                id: posX
                Text{
                    text: "x"
                    anchors.horizontalCenter: posX.horizontalCenter
                    anchors.top: posX.top
                    anchors.topMargin: -7
                    color: textColor
                }
                from: -1000000
                to: 1000000
                stepSize:100
                value:Math.round(cam.position.x)
                onValueModified: cam.position.x=value
                /*                     
                onValueModified:{
                    if (!running){
                        cam.position=Qt.vector3d(posX.value,posZ.value,posY.value)
                        root.refreshMiniFrame()
                    }
                }*/
                editable: true
            }
            SpinBox{
                id: posY
                property real camPosYProxy: 0
                Connections {
                    target: cam
                    function onPositionChanged(){
                        posY.camPosYProxy = Math.round(-target.position.z)
                    }
                }

                Text{
                    text: "y"
                    anchors.horizontalCenter: posY.horizontalCenter
                    anchors.top: posY.top
                    anchors.topMargin: -7
                    color: textColor
                }
                from: -1000000
                to: 1000000
                stepSize:100
                value: camPosYProxy
                onValueModified:{
                    cam.position.z = -value
                }         
                editable: true
            }
            SpinBox{
                id: posZ
                Text{
                    text: "z"
                    anchors.horizontalCenter: posZ.horizontalCenter
                    anchors.top: posZ.top
                    anchors.topMargin: -7
                    color: textColor
                }
                from: -1000000
                to: 1000000
                stepSize:100
                value:Math.round(cam.position.y)
                onValueModified: cam.position.y= value            
                editable: true
            }            
        }        
    }

    state: "CLOSED"
    states: [
        State {
            name: "OPEN"
            PropertyChanges { target: root ; scale : 1}
            PropertyChanges { target: root ; opacity : 1}
        },
        State {
            name: "CLOSED"
            PropertyChanges { target: root ; scale : 0}
            PropertyChanges { target: root ; opacity : 0}
        }
    ]

    transitions: [
        Transition {
            ParallelAnimation{
                NumberAnimation{ target: root ; properties: "scale, opacity" ; duration: 175; easing.type: Easing.InOutQuad }
            }
        }
    ]
}


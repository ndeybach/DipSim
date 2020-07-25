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

import QtQuick3D 1.15
import QtQuick3D.Helpers 1.15

import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import Qt.labs.settings 1.0
View3D{
    id: view3D
    //renderMode: View3D.Inline

    property real overlayPaddingLeft: 0
    property real overlayPaddingRight: 0

    required property var dipShapeCB

    DirectionalLight {
        ambientColor: Qt.rgba(1.0, 1.0, 1.0, 1.0)
    }
    onFocusChanged: console.log("focus changed wasd")
    Settings{
        id: view3DSettings
        category: "view3D"
        property alias viewCtrlsHolderState: viewCtrlsHolder.state
        property var camPosition: undefined
        property var camRotation: undefined
    }

    environment: SceneEnvironment {
        id: sceneEnvironment
        clearColor: "dimgray"
        backgroundMode: SceneEnvironment.Color

        antialiasingMode: SceneEnvironment.MSAA
        antialiasingQuality: SceneEnvironment.VeryHigh

        aoDither: false
    }
    
    CustomWasdController {
        id: wasdController
        controlledObject: cam
        controlledview3D: view3D
        focus: true
        // Connections {
        //     target: wasdController
        //     function onPickAt(x, y){
        //         console.log("x: " + x, " y: " + y)
        //         var pickres = view3D.pick(x/view3D.width, y/view3D.height)
        //         console.log(pickres)
        //     }
        // }
    }
    PerspectiveCamera{
        id: cam
        Component.onCompleted:{
            if(view3DSettings.camPosition === undefined) position = Qt.vector3d(600, 300, 600)
            else position = view3DSettings.camPosition
            if(view3DSettings.camRotation === undefined){
                lookAt(Qt.vector3d(0, 0, 0))
                refresh(viewCtrlsHolder, forward)
            }
            else eulerRotation = view3DSettings.camRotation
        }

        function refresh(viewCtrlsHolder, forward){
            viewCtrlsHolder.camVisualizer.position = forward.normalized().times(-100)
            viewCtrlsHolder.camVisualizer.lookAt(Qt.vector3d(0,0,0))
        }
        onPositionChanged: refresh(viewCtrlsHolder, forward)
        onEulerRotationChanged: refresh(viewCtrlsHolder, forward)

        Component.onDestruction:{
            view3DSettings.camPosition = cam.position
            view3DSettings.camRotation = cam.eulerRotation
        }
    }
    Node{
        eulerRotation: Qt.vector3d(-90,0,0) // sets z axis up instead of Y (because bug on z rotation with eulerrotation)
        
        AxisHelper{
            id: axes
            enableAxisLines: true
            enableXYGrid: true
            enableXZGrid: false
        }

        Repeater3D{
            model: hypervisor.viewModeSelected === hypervisor.viewModeList[0] ? dipModel : (hypervisor.viewModeSelected === hypervisor.viewModeList[1] ? dipModelMinEnergy : dipModelMinEnergyMC)
            delegate: Loader3D {
                source: "mycomponent.qml"
                asynchronous: true
                visible: status == Loader3D.Ready
                sourceComponent: dipShapeCB.currentIndex === 0 ? dipArrowModel : dipSphereModel
                Component{
                    id: dipArrowModel
                    NanoPartModel{
                        id: nanoPart
                        position: position3D
                        color: dipColor
                        length: hypervisor.crystalMinDist/1.3
                        Component.onCompleted: rotation = Qt.binding(function() { return quaternion })
                    }
                }
                Component{
                    id: dipSphereModel
                    Model {
                        id: dipoleMomentTip
                        property real length: hypervisor.crystalMinDist/2
                        position: position3D
                        source: "#Sphere"
                        scale: Qt.vector3d(length/100, length/100, length/100)
                        materials: PrincipledMaterial{
                            id: principledMaterial
                            baseColor: dipColor
                            metalness: 0.6
                            roughness: 0.03
                            specularAmount: 4
                            indexOfRefraction: 2.5
                            opacity: 1.0
                        }
                    }
                }
            }
        }
    }

    Item{
        id: overlaysContainer
        anchors{
            fill: parent
            leftMargin: overlayPaddingLeft
            rightMargin: overlayPaddingRight
        }

        // DebugView {
        //     source: view3D
        // }

        View3DControlsPanel{
            id: viewCtrlsHolder
            view3D: view3D
            cam: cam
            axes: axes
            running: wasdController.running
            background.opacity: 0.8
            anchors{
                bottom: parent.bottom
                right: parent.right
                rightMargin: 35
                bottomMargin: 35
            }
            onRefreshMiniFrame: cam.refresh(viewCtrlsHolder, cam.forward)
        }

        RoundButton{
            id: viewCtrlsHolderButton
            text: viewCtrlsHolder.state === "CLOSED" ? "Open" : "Closed"
            icon{
                source: "qrc:/icons/move"
                color: "white"
            }
            display: AbstractButton.IconOnly
            focusPolicy: Qt.TabFocus

            palette.button: "steelblue"
            anchors{
                bottom: viewCtrlsHolder.bottom
                right: viewCtrlsHolder.right
                rightMargin: -Math.min(Math.round(viewCtrlsHolder.anchors.rightMargin/2), viewCtrlsHolderButton.width/2)
                bottomMargin: -Math.min(Math.round(viewCtrlsHolder.anchors.bottomMargin/2), viewCtrlsHolderButton.height/2)
            }

            onClicked: viewCtrlsHolder.state === "CLOSED" ? viewCtrlsHolder.state = "OPEN" : viewCtrlsHolder.state = "CLOSED"
        }
    }
}

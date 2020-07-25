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
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import Qt.labs.settings 1.0

Drawer {
    id: root
    required property var header
    property int drawerMargins: 20
    property var dipShapeCB: dipShapeCB
    leftInset: ~~(-drawerMargins/2)
    rightInset: ~~(drawerMargins/2)
    topInset: ~~(-drawerMargins/2)
    bottomInset: ~~(-drawerMargins/2)

    y: header.height + drawerMargins
    width: 270
    height: window.height-header.height - 2*drawerMargins
    edge: Qt.RightEdge
    visible: true
    closePolicy: Popup.NoAutoClose
    modal: false
    focus: false
    Material.elevation: 0
    position: 0.0
    background: Rectangle{
        color: backgroundColor
        opacity: 0.9
        radius: root.drawerMargins
    }

    Settings{
        id: drawerSettingsSets
        category: "drawerSettings"
        property bool isOpen: false
    }
    Component.onCompleted:{
        if(!drawerSettingsSets.isOpen) root.close()
    }
    Component.onDestruction:{
        drawerSettingsSets.isOpen = root.position === 1.0
    }

    component TextContainer : Text{
        text: ""
        font.family: "Helvetica"
        fontSizeMode: Text.Fit
        elide: Text.ElideRight
        minimumPointSize: 6
        font.pointSize: 11
        wrapMode: Text.Wrap
        color: textColor
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }

    Flickable{
        id: flickable
        clip: true
        anchors{
            fill: parent
            leftMargin: root.leftInset+1
            rightMargin: 2
            topMargin: 2
        }
        contentHeight: parametersList.height

        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            width: 8
            contentItem: Rectangle {
                radius: parent.width / 2
                color: scrollBar.pressed ? setColorAlpha(iconsColor, 0.45) : setColorAlpha(iconsColor, 0.25) 
            }
        }

        ColumnLayout{
            id: parametersList
            spacing: 5
            anchors{
                right: parent.right
                left: parent.left
                rightMargin: scrollBar.width
            }
            FoldablePanel{
                title: qsTr("3DView")
                
                Layout.fillWidth: true
                Layout.leftMargin: 7
                Layout.rightMargin: 7
                
                GroupBox{
                    Layout.fillWidth: true
                    title: qsTr("Dipoles")
                    
                    ColumnLayout{
                        id: col
                        anchors.fill: parent
                        RowLayout{
                            id: genFamSelect
                            Layout.fillWidth: true
                            TextContainer{
                                Layout.fillHeight: true
                                Layout.preferredWidth: contentWidth
                                text: qsTr("Dipoles shape:")
                            }
                            ComboBox{
                                id: dipShapeCB
                                model: ["Arrow", "Sphere"]
                                Settings {
                                    category: "dipShapeCB"
                                    property alias currentIndex: dipShapeCB.currentIndex
                                }
                            }
                        }
                    }
                }              
            }
            FoldablePanel{
                title: qsTr("Simulation")
                
                Layout.fillWidth: true
                Layout.leftMargin: 7
                Layout.rightMargin: 7
                GroupBox{
                    title: qsTr("Units")
                    Layout.fillWidth: true
                    ColumnLayout{
                        anchors.fill: parent
                        TextContainer{
                            Layout.fillHeight: true
                            Layout.preferredWidth: contentWidth
                            text: qsTr("Power of the unit to use in \nsimulation distances:")
                        }
                        SpinBox{
                            id: unitSizingSPB
                            from: -30
                            to: 30
                            stepSize:1
                            value: hypervisor.distCoef
                            editable: true
                            onValueModified: hypervisor.distCoef = value

                        }
                        TextContainer{
                            Layout.fillHeight: true
                            Layout.preferredWidth: contentWidth
                            text: qsTr("Exemple now: 300 is 300.10^" + unitSizingSPB.displayText + " m")
                        }
                    }  
                }
            }
            FoldablePanel{
                title: "UI"
                
                Layout.fillWidth: true
                Layout.leftMargin: 7
                Layout.rightMargin: 7

                GroupBox{
                    Layout.fillWidth: true
                    title: qsTr("Theme")
                    
                    ColumnLayout{
                        anchors.fill: parent
                        spacing: 0
                        TextContainer{
                            Layout.fillWidth: true
                            text: qsTr("Application theme:")
                        }
                        ComboBox {
                            Layout.alignment: Qt.AlignRight
                            model: appThemes
                            onActivated: appTheme = textAt(currentIndex)
                            Component.onCompleted: currentIndex = indexOfValue(appTheme)
                        }
                    }
                }
                
                GroupBox{
                    Layout.fillWidth: true
                    title: qsTr("Colors")
                    
                    ColumnLayout{
                        anchors.fill: parent
                        spacing: 0
                        RowLayout{
                            Layout.fillWidth: true
                            TextContainer{
                                Layout.minimumWidth: contentWidth
                                text: qsTr("Accent color:")
                            }
                            Button{
                                id: accentColorButton
                                Layout.fillWidth: true
                                Material.background: accentColor
                                Material.foreground: (enableDarkAccentColor || !darkTheme) && accentColorID !== "BLACK/WHITE" ? foregroundColor : backgroundColor
                                text: qsTr("Choose")
                                icon{
                                    source: "qrc:/icons/palette"
                                    color: setColorAlpha(textColor, 0.75)
                                }
                                font.capitalization: Font.MixedCase
                                onClicked: accentMenuLoader.item.open()

                                Loader{
                                    id: accentMenuLoader
                                    x:-50
                                    function resetColors(){
                                        sourceComponent = undefined
                                        sourceComponent = accentMenuContainer
                                    }
                                    visible: true
                                    sourceComponent: accentMenuContainer
                                }

                                Component{
                                    id: accentMenuContainer
                                    Menu{
                                        id: accentMenu

                                        ListModel{
                                            id: accentColorsMaterialModel
                                            ListElement {accentColorName : qsTr("Red") ; accentColorId: "RED"}
                                            ListElement {accentColorName : qsTr("Pink") ; accentColorId: "PINK"}
                                            ListElement {accentColorName : qsTr("Purple") ; accentColorId: "PURPLE"}
                                            ListElement {accentColorName : qsTr("DeepPurple") ; accentColorId: "DEEPPURPLE"}
                                            ListElement {accentColorName : qsTr("Indigo") ; accentColorId: "INDIGO"}
                                            ListElement {accentColorName : qsTr("Blue") ; accentColorId: "BLUE"}
                                            ListElement {accentColorName : qsTr("Steelblue") ; accentColorId: "STEELBLUE"}
                                            ListElement {accentColorName : qsTr("LightBlue") ; accentColorId: "LIGHTBLUE"}
                                            ListElement {accentColorName : qsTr("Cyan") ; accentColorId: "CYAN"}
                                            ListElement {accentColorName : qsTr("Teal") ; accentColorId: "TEAL"}
                                            ListElement {accentColorName : qsTr("Green") ; accentColorId: "GREEN"}
                                            ListElement {accentColorName : qsTr("LightGreen") ; accentColorId: "LIGHTGREEN"}
                                            ListElement {accentColorName : qsTr("Lime") ; accentColorId: "LIME"}
                                            ListElement {accentColorName : qsTr("Yellow") ; accentColorId: "YELLOW"}
                                            ListElement {accentColorName : qsTr("Amber") ; accentColorId: "AMBER"}
                                            ListElement {accentColorName : qsTr("Orange") ; accentColorId: "ORANGE"}
                                            ListElement {accentColorName : qsTr("DeepOrange") ; accentColorId: "DEEPORANGE"}
                                            ListElement {accentColorName : qsTr("Brown") ; accentColorId: "BROWN"}
                                            ListElement {accentColorName : qsTr("Grey") ; accentColorId: "GREY"}
                                            ListElement {accentColorName : qsTr("BlueGrey") ; accentColorId: "BLUEGREY"}
                                            ListElement {accentColorName : qsTr("Black/White") ; accentColorId: "BLACK/WHITE"}
                                        }

                                        contentItem: GridLayout{
                                            id: menuLayout
                                            property real cellWidth: 40
                                            property real cellHeight: 40
                                            rowSpacing: 0
                                            columnSpacing: 0
                                            columns: 5
                                            width: columns*accentColorPickView.cellWidth
                                            height: Math.ceil(accentColorPickView.model.count/columns)*cellHeight

                                            Repeater{

                                                id: accentColorPickView
                                                Layout.alignment: Qt.AlignCenter
                                                implicitHeight: Math.ceil(model.count/parent.nbColumns)*parent.cellHeight
                                                implicitWidth: parent.nbColumns*parent.cellWidth
                                                model: accentColorsMaterialModel
                                                delegate: MenuItem{
                                                    id: accentColorPickerButton
                                                    implicitHeight: menuLayout.cellHeight
                                                    implicitWidth: menuLayout.cellWidth
                                                    ToolTip.visible: accentColorPickerButton.hovered
                                                    ToolTip.text: accentColorName
                                                    Rectangle{
                                                        id: accentMenuCanva
                                                        anchors.centerIn: parent
                                                        radius: height/2
                                                        height: 36
                                                        width: height
                                                        color: stylingSettings.accentColorIDToColorString(accentColorId)
                                                    }
                                                    onClicked: {
                                                        stylingSettings.setAccentColor(accentColorId)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        ButtonGroup {
                            id: childGroup
                            exclusive: false
                            checkState: enableDarkAccentColorChecker.checkState
                        }

                        CheckBox{
                            id: enableDarkAccentColorChecker
                            padding: 0
                            text: qsTr("Enable dark accent colors.")
                            checked: enableDarkAccentColor
                            onToggled: {
                                enableDarkAccentColor = !enableDarkAccentColor
                                //enableDarkAccentColorOnlyOnDarkTheme = true
                            }
                        }

                        CheckBox{
                            id: enableDarkAccentColorOnlyOnDarkThemeChecker
                            padding: 0
                            text: qsTr("Only on dark themes.")
                            checked: enableDarkAccentColorOnlyOnDarkTheme && enableDarkAccentColor
                            onToggled: if(enableDarkAccentColorChecker.checkState === Qt.Checked)  enableDarkAccentColorOnlyOnDarkTheme = !enableDarkAccentColorOnlyOnDarkTheme
                            ButtonGroup.group: childGroup
                            leftPadding: 20
                        }
                        

                    }
                }              
            }
        }
    }
}

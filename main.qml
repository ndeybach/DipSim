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
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import QtQuick3D 1.15 as Quick3D
import QtQuick3D.Helpers 1.15
import Qt.labs.settings 1.0
import QtQuick.Dialogs 1.3

//import "qrc:/src/qml/"
import "./src/qml/"


ApplicationWindow{
    id: window
    title: "DipSim - dipole moment interractions simulator"
    width: 1600
    height: 1000
    minimumHeight: 600
    minimumWidth: 1050
    visible: true
    //onActiveFocusItemChanged: print("activeFocusItem: ", activeFocusItem) // debug focus

    Shortcut {
        sequence: "Ctrl+W"
        onActivated: window.close()
    }
    Settings {
        category: "mainWindow"
        property alias x: window.x
        property alias y: window.y
        property alias width: window.width
        property alias height: window.height
    }

    //////// STYLING ////////

    property alias appTheme: stylingSettings.appTheme
    property alias appThemes: stylingSettings.appThemes
    property alias darkTheme: stylingSettings.darkTheme
    property alias highContrastTheme: stylingSettings.highContrastTheme
    property alias enableDarkAccentColor: stylingSettings.enableDarkAccentColor
    property alias enableDarkAccentColorOnlyOnDarkTheme: stylingSettings.enableDarkAccentColorOnlyOnDarkTheme

    property alias accentColorID: stylingSettings.accentColorID
    property alias accentColor: stylingSettings.accentColor
    property alias backgroundColor: stylingSettings.backgroundColor
    property alias backgroundColorAlt: stylingSettings.backgroundColorAlt 
    property alias backgroundColorAltAlt: stylingSettings.backgroundColorAltAlt
    property alias foregroundColor: stylingSettings.foregroundColor
    property alias textColor: stylingSettings.textColor
    property alias borderColor: stylingSettings.borderColor
    property alias headerColor: stylingSettings.headerColor
    property alias iconsColor: stylingSettings.iconsColor

    Material.accent: accentColor
    Material.primary : backgroundColor
    Material.background: backgroundColor
    Material.foreground: foregroundColor
    Material.theme: darkTheme ? Material.Dark : Material.Light

    StylingBackend{
        id: stylingSettings
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

    //////// GLOBAL FUNCTIONS ////////

    function setColorAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    function invertColor( mColor){
        return Qt.rgba(1 - mColor.r,1 - mColor.g,1 - mColor.b, mColor.a)
    }

    //////// WINDOW ////////

    header: ToolBar{
        id: header
        background: Rectangle{
            color: headerColor
        }

        RowLayout{
            id: headerLayout
            anchors.fill: parent

            BurgerButton{
                id: burgerButton
                Layout.leftMargin: 20 + (drawer.width - 30 - width)*drawer.position
                Layout.alignment: Qt.AlignVCenter
                position: drawer.position
                burgerColor: iconsColor
                onStateChanged: {
                    if(state === "menu" && drawer.position === 1.0) drawer.close()
                    else if(state === "back" && drawer.position === .0) drawer.open()
                }
            }

            Item{
                id: filler
                Layout.fillWidth: true
            }
            RoundButton{
                id: exportButton
                text: "Export visible dipoles"
                icon.source: "qrc:/icons/upload"
                display: AbstractButton.IconOnly
                Material.elevation: 0
                Layout.alignment: Qt.AlignVCenter
                ToolTip{
                    delay: 1000
                    visible: exportButton.hovered
                    text: exportButton.text
                }

                onClicked:{
                    if(!exportPopup.opened){
                        exportPopup.open()
                    }
                }
                
                Popup {
                    id: exportPopup
                    anchors.centerIn: Overlay.overlay
                    Material.elevation: 8
                    Settings {
                        category: "exportMenu"
                        property alias initialDipsSelectExport: initialDipsSelectExport.checked
                        property alias minEnDipsSelectExport: minEnDipsSelectExport.checked
                        property alias minEnMCDipsSelectExport: minEnMCDipsSelectExport.checked
                        property alias saveLocationText: saveLocation.text
                        property alias addDateSelectExportChecked: addDateSelectExport.checked
                    }
                    contentItem: ColumnLayout{
                        spacing: 0
                        TextContainer{
                            padding: 3
                            Layout.fillWidth: true
                            text: "Dipoles to export (in different files if many):"
                        }

                        ButtonGroup{
                            id: childGroup
                            exclusive: false
                            checkState: parentBox.checkState
                        }

                        CheckBox{
                            padding: 2
                            id: parentBox
                            checked: true
                            text: qsTr("All")
                            checkState: childGroup.checkState
                        }

                        CheckBox{
                            id: initialDipsSelectExport
                            padding: 0
                            checked: true
                            text: qsTr("Intials")
                            leftPadding: indicator.width
                            ButtonGroup.group: childGroup
                        }

                        CheckBox{
                            id: minEnDipsSelectExport
                            padding: 0
                            checked: true
                            text: qsTr("Min Energy")
                            leftPadding: indicator.width
                            ButtonGroup.group: childGroup
                        }
                        CheckBox{
                            id: minEnMCDipsSelectExport
                            padding: 0
                            text: qsTr("Min Energy M-C")
                            leftPadding: indicator.width
                            ButtonGroup.group: childGroup
                        }
                        TextContainer{
                            padding: 3
                            Layout.fillWidth: true
                            text: "Folder to export to:"
                        }
                        RowLayout{
                            Layout.fillWidth: true
                            RoundButton{
                                padding: 0
                                text: "Choose location"
                                radius: 6
                                Layout.preferredWidth: 60
                                icon{
                                    source: "qrc:/icons/folder-open"
                                    width: 22
                                    height: 22
                                }
                                display: AbstractButton.IconOnly
                                ToolTip{
                                    y: -35
                                    delay: 250
                                    visible: parent.hovered
                                    text: parent.text
                                }
                                onClicked: fileDialog.open()
                            }
                            FileDialog {
                                id: fileDialog
                                title: "Please choose a file where to export dipoles"
                                folder: shortcuts.home
                                selectFolder: true
                                onAccepted: {
                                    console.log("You chose: " + fileDialog.fileUrls)
                                    saveLocation.text = fileDialog.fileUrl
                                }
                            }
                            TextContainer{
                                id: saveLocation
                                padding: 3
                                Layout.fillWidth: true
                                text: ""
                            }
                        }
                        CheckBox{
                            id: addDateSelectExport
                            padding: 4
                            text: qsTr("Add date to export name ?")
                            checked: true
                        }
                        RoundButton{
                            padding: 0
                            text: "EXPORT !"
                            radius: 6
                            Layout.fillWidth: true
                            ToolTip{
                                y: -35
                                delay: 250
                                visible: parent.hovered
                                text: "Export with chosen parameters"
                            }
                            onClicked: {
                                var listDipsToExp = [initialDipsSelectExport.checked, minEnDipsSelectExport.checked, minEnMCDipsSelectExport.checked]
                                hypervisor.export(saveLocation.text, listDipsToExp, addDateSelectExport.checked)
                            }
                        }
                    }
                    
                }

            }
            ComboBox {
                id: dipolesInViewSelector
                model: hypervisor.viewModeList
                Layout.preferredWidth: 180
                onActivated: hypervisor.viewModeSelected = textAt(currentIndex)
                Component.onCompleted: currentIndex = indexOfValue(hypervisor.viewModeSelected)
                
                Connections {
                    target: hypervisor
                    function onViewModeSelectedChanged(){
                        dipolesInViewSelector.currentIndex = dipolesInViewSelector.indexOfValue(hypervisor.viewModeSelected)
                    }
                }
            }
            RoundButton{
                id: dipoleButton
                text: "Visible dipoles list"
                icon.source: "qrc:/icons/list-elements"
                display: AbstractButton.IconOnly
                Material.elevation: 0
                Layout.alignment: Qt.AlignVCenter
                ToolTip{
                    delay: 1000
                    visible: dipoleButton.hovered
                    text: dipoleButton.text
                }
                onClicked: popupDipoleList.open()
            }
            View3DDipoleList{
                id: popupDipoleList
                x: window.width - width - 5
                y: dipoleButton.y + (2*dipoleButton.radius) + 5
            }

            RoundButton{
                id: settingsButton
                text: "Settings"
                icon.source: "qrc:/icons/settings"
                display: AbstractButton.IconOnly
                Material.elevation: 0

                Layout.rightMargin: 6
                Layout.alignment: Qt.AlignVCenter
                ToolTip{
                    delay: 2000
                    visible: settingsButton.hovered
                    text: settingsButton.text
                }
                onClicked:{
                    if(drawerSettings.position === 1.0) drawerSettings.close()
                    else drawerSettings.open()
                }
            }            
        }
    }

    LeftDrawer{
        id: drawer
    }

    RowLayout{
        anchors.fill: parent
        View3DMod{
            id: view3D
            Layout.fillHeight: true
            Layout.fillWidth: true
            overlayPaddingLeft: drawer.width*drawer.position
            overlayPaddingRight: drawerSettings.width*drawerSettings.position
            dipShapeCB: drawerSettings.dipShapeCB
        }
    }

    SettingsDrawer{
        id: drawerSettings
        header: header
    }
}

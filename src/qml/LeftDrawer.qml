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
import QtQuick.Dialogs 1.3

Drawer {
    id: root
    property int drawerMargins: 5
    padding: drawerMargins

    leftInset: ~~(drawerMargins/2)
    rightInset: ~~(drawerMargins/2)
    topInset: ~~(-drawerMargins/2)
    bottomInset: ~~(-drawerMargins/2)

    y: header.height + drawerMargins
    width: 280
    height: window.height-header.height - 2*drawerMargins
    visible: true
    closePolicy: Popup.NoAutoClose
    modal: false
    focus: false
    Material.elevation: 0
    background: Rectangle{
        color: backgroundColor
        opacity: 0.98
        radius: drawer.drawerMargins
    }

    Settings{
        id: drawerSets
        category: "drawerEdit"
        property bool isOpen: true
        //property real genSize
    }
    Component.onCompleted:{
        if(!drawerSets.isOpen) drawer.close()
    }
    Component.onDestruction:{
        drawerSets.isOpen = drawer.position === 1.0
    }

    onPositionChanged:{
        if(position === 0) burgerButton.state = "menu"
        else if(position === 1) burgerButton.state = "back" // see if possible delete pos == 1
    }
    Component{
        id: testRect
        Rectangle{
            width: 50
            height: 50
        }
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
    component InputContainer : TextInput {
        text: hypervisor.primCellA
        selectByMouse: true
        color: textColor
        verticalAlignment: TextEdit.AlignVCenter
        wrapMode: TextEdit.Wrap
        validator: RegExpValidator{regExp: /[0-9.]+/}
    }

    Component{
        id: importGenParamsFrame
        GroupBox{
            anchors.fill: parent
            title: "Parameters"
            ColumnLayout{
                anchors.fill: parent
                TextContainer{
                    padding: 3
                    Layout.fillWidth: true
                    text: "Import from these files:"
                }
                RowLayout{
                    Layout.fillWidth: true
                    RoundButton{
                        padding: 0
                        text: "Choose imported files"
                        radius: 6
                        Layout.preferredWidth: 60
                        icon{
                            source: "qrc:/icons/download"
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
                        onClicked: fileImportDialog.open()
                    }
                    FileDialog {
                        id: fileImportDialog
                        title: "Please choose a file where to export dipoles"
                        folder: shortcuts.home
                        selectMultiple: true
                        selectFolder: false
                        nameFilters: ["CSV data files (*.csv)", "All files (*)"]
                        onAccepted: {
                            var urlList = []
                            for (let i = 0; i < fileImportDialog.fileUrls.length; i++){
                                urlList.push(fileImportDialog.fileUrls[i].toString())
                            }
                            hypervisor.importFileURLsStr = urlList
                            importList.text = urlList.join("\n")
                        }
                    }
                    TextContainer{
                        id: importList
                        padding: 3
                        Layout.fillWidth: true
                        text: hypervisor.importFileURLsStr.join("\n\n")
                    }
                }
            }
        }
    }

    Component{
        id: randomGenParamsFrame
        Frame {
            anchors.fill: parent
            // title: "Parameters"
            ColumnLayout{
                anchors.fill: parent
                RowLayout{
                    id: rndNbSelect
                    Layout.fillWidth: true
                    Text{
                        text: "Nb dipoles:"
                        fontSizeMode: Text.Fit
                        elide: Text.ElideRight
                        minimumPointSize: 6
                        font.pointSize: 10
                        wrapMode: Text.Wrap
                        color: textColor
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        Layout.fillHeight: true
                        Layout.preferredWidth: contentWidth
                    }
                    Item{Layout.preferredWidth: 16}
                    TextInput {
                        text: hypervisor.nbDipolesRdm
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        selectByMouse: true
                        color: textColor
                        verticalAlignment: TextEdit.AlignVCenter
                        wrapMode: TextEdit.Wrap
                        validator: RegExpValidator{regExp: /[0-9]+/}
                        onEditingFinished:{
                            hypervisor.nbDipolesRdm = parseInt(text)
                        }
                    }
                }
                RowLayout{
                    id: genFamSelect
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "Random gen mode:"
                        fontSizeMode: Text.Fit
                        elide: Text.ElideRight
                        minimumPointSize: 6
                        font.pointSize: 10
                        wrapMode: Text.Wrap
                        color: textColor
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        Layout.fillHeight: true
                        Layout.preferredWidth: contentWidth
                        
                    }
                    //Item{Layout.fillWidth: true }
                    ComboBox {
                        Layout.alignment: Qt.AlignRight
                        model: hypervisor.randomGenModeList
                        onActivated: hypervisor.randomGenModeSelected = textAt(currentIndex)
                        Component.onCompleted: currentIndex = indexOfValue(hypervisor.randomGenModeSelected)
                    }
                    //Item{Layout.fillWidth: true }
                }
                RowLayout{
                    id: genSizeSelect
                    Layout.fillWidth: true
                    Text {
                        text: "Gen radius:"
                        fontSizeMode: Text.Fit
                        elide: Text.ElideRight
                        minimumPointSize: 6
                        font.pointSize: 10
                        //font.capitalization: Font.AllUppercase
                        wrapMode: Text.Wrap
                        color: textColor
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        Layout.fillHeight: true
                        Layout.preferredWidth: contentWidth
                    }
                    Item{Layout.preferredWidth: 16}
                    TextInput {
                        id: edit
                        text: hypervisor.genSize
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        selectByMouse: true
                        color: textColor
                        verticalAlignment: TextEdit.AlignVCenter
                        wrapMode: TextEdit.Wrap
                        validator: RegExpValidator{regExp: /[0-9.]+/}
                        onEditingFinished:{
                            hypervisor.genSize = parseFloat(text)
                        }
                    }
                }
            }
        }
    }
    
    Component{
        id: latticeGenParamsFrame
        GroupBox {
            anchors.fill: parent
            title: "Parameters"
            padding: 10
            ColumnLayout{
                id: col
                anchors.fill: parent
                spacing: 6
                
                RowLayout{
                    id: genTypeSelect
                    TextContainer{
                        text: "Cell type:"
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }
                    ComboBox{
                        Layout.alignment: Qt.AlignRight
                        id: cbType
                        model: hypervisor.crystalTypes
                        font.capitalization: Font.Capitalize
                        onActivated: hypervisor.crystalType = textAt(currentIndex)
                        Component.onCompleted: currentIndex = indexOfValue(hypervisor.crystalType)
                        onModelChanged: currentIndex = indexOfValue(hypervisor.crystalType)
                        delegate: ItemDelegate {
                            width: cbType.width
                            contentItem: Text {
                                text: modelData
                                color: cbType.currentIndex === index ? accentColor : textColor
                                font: cbType.font
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                            highlighted: cbType.highlightedIndex === index
                        }
                        contentItem: Item{}
                        Text {
                            anchors{
                                fill: parent
                                leftMargin: 8
                                rightMargin: cbType.indicator.width + cbType.spacing
                            }
                            text: cbType.displayText
                            color: textColor
                            font: cbType.font
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
                RowLayout{
                    id: genFamSelect
                    Layout.fillWidth: true
                    TextContainer{
                        text: "Cell family:"
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }
                    ComboBox {
                        Layout.alignment: Qt.AlignRight
                        model: hypervisor.crystalFamilies
                        onActivated: hypervisor.crystalFamily = textAt(currentIndex)
                        Component.onCompleted: currentIndex = indexOfValue(hypervisor.crystalFamily)
                        onModelChanged: currentIndex = indexOfValue(hypervisor.crystalFamily)
                    }
                }
                RowLayout{
                    id: genSizeSelect
                    Layout.fillWidth: true
                    TextContainer{
                        text: "Gen radius:"
                        Layout.fillHeight: true
                        Layout.minimumWidth: contentWidth
                        Layout.fillWidth: true
                    }
                    Item{Layout.preferredWidth: 16}
                    TextInput {
                        Layout.alignment: Qt.AlignLeft
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        id: edit
                        text: hypervisor.genSize
                        selectByMouse: true
                        color: textColor
                        verticalAlignment: TextEdit.AlignVCenter
                        wrapMode: TextEdit.Wrap
                        validator: RegExpValidator{regExp: /[0-9.]+/}
                        onEditingFinished:{
                            hypervisor.genSize = parseFloat(text)
                        }
                    }
                }
                Frame {
                    Layout.fillWidth: true
                    padding: 9
                    ColumnLayout{
                        anchors.fill: parent
                        RowLayout{
                            Layout.fillWidth: true
                            TextContainer{
                                text: "a" + " :"
                                Layout.fillHeight: true
                                Layout.preferredWidth: contentWidth
                            }
                            Item{Layout.preferredWidth: 8}
                            InputContainer{
                                Layout.alignment: Qt.AlignLeft
                                Layout.fillWidth: true
                                text: hypervisor.primCellA
                                color: enabled ? textColor : setColorAlpha(textColor, 0.5) 
                                enabled: !hypervisor.primCellALocked
                                onEditingFinished: hypervisor.primCellA = parseFloat(text)
                            }
                        }
                        RowLayout{
                            Layout.fillWidth: true
                            TextContainer{
                                text: "b" + " :"
                                Layout.fillHeight: true
                                Layout.preferredWidth: contentWidth
                            }
                            Item{Layout.preferredWidth: 8}
                            InputContainer{
                                Layout.alignment: Qt.AlignLeft
                                Layout.fillWidth: true
                                text: hypervisor.primCellB
                                color: enabled ? textColor : setColorAlpha(textColor, 0.5) 
                                enabled: !hypervisor.primCellBLocked
                                onEditingFinished: hypervisor.primCellB = parseFloat(text)
                            }
                        }
                        RowLayout{
                            Layout.fillWidth: true
                            TextContainer{
                                text: "c" + " :"
                                Layout.fillHeight: true
                                Layout.preferredWidth: contentWidth
                            }
                            Item{Layout.preferredWidth: 8}
                            InputContainer{
                                Layout.alignment: Qt.AlignLeft
                                Layout.fillWidth: true
                                text: hypervisor.primCellC
                                color: enabled ? textColor : setColorAlpha(textColor, 0.5) 
                                enabled: !hypervisor.primCellCLocked
                                onEditingFinished: hypervisor.primCellC = parseFloat(text)
                            }
                        }
                        RowLayout{
                            Layout.fillWidth: true
                            TextContainer{
                                text: "gamma" + " :"
                                Layout.fillHeight: true
                                Layout.preferredWidth: contentWidth
                            }
                            Item{Layout.preferredWidth: 8}
                            InputContainer{
                                Layout.alignment: Qt.AlignLeft
                                Layout.fillWidth: true
                                text: hypervisor.primCellGamma
                                color: enabled ? textColor : setColorAlpha(textColor, 0.5)
                                enabled: !hypervisor.primCellGammaLocked
                                onEditingFinished: hypervisor.primCellGamma = parseFloat(text)
                            }
                        }
                        RowLayout{
                            Layout.fillWidth: true
                            TextContainer{
                                text: "alpha" + " :"
                                Layout.fillHeight: true
                                Layout.preferredWidth: contentWidth
                            }
                            Item{Layout.preferredWidth: 8}
                            InputContainer{
                                Layout.alignment: Qt.AlignLeft
                                Layout.fillWidth: true
                                text: hypervisor.primCellAlpha
                                color: enabled ? textColor : setColorAlpha(textColor, 0.5)
                                enabled: !hypervisor.primCellAlphaLocked
                                onEditingFinished: hypervisor.primCellAlpha = parseFloat(text)
                            }
                        }
                        RowLayout{
                            Layout.fillWidth: true
                            TextContainer{
                                text: "beta" + " :"
                                Layout.fillHeight: true
                                Layout.preferredWidth: contentWidth
                            }
                            Item{Layout.preferredWidth: 8}
                            InputContainer{
                                Layout.alignment: Qt.AlignLeft
                                Layout.fillWidth: true
                                text: hypervisor.primCellBeta
                                color: enabled ? textColor : setColorAlpha(textColor, 0.5)
                                enabled: !hypervisor.primCellBetaLocked
                                onEditingFinished: hypervisor.primCellBeta = parseFloat(text)
                            }
                        }

                        

                        RowLayout{
                            Layout.fillWidth: true
                            spacing: 2
                            Button{
                                text: "Reset parameters to default"
                                display: AbstractButton.IconOnly
                                padding: 0
                                Material.elevation: 1
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                Layout.rightMargin: 8
                                Layout.leftMargin: 2
                                implicitHeight: 40
                                implicitWidth: 40
                                ToolTip{
                                    y: -35
                                    delay: 250
                                    visible: parent.hovered
                                    text: parent.text
                                }
                                icon{
                                    source: "qrc:/icons/reset"
                                    color: iconsColor
                                    height: 18
                                    width: 18
                                }
                                onClicked: hypervisor.resetBravaisParams()
                            }
                            CheckBox {
                                padding: 2
                                checked: hypervisor.resetPrimCellParamsOnChange
                                onCheckStateChanged: hypervisor.resetPrimCellParamsOnChange ? hypervisor.resetPrimCellParamsOnChange = false : hypervisor.resetPrimCellParamsOnChange = true
                            }
                            TextContainer{
                                Layout.fillWidth: true
                                text: "Reset on type change"
                                Layout.fillHeight: true
                            }
                        }

                    }
                }
                
            }
        }
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
                id: latticeGenParams
                title: "Lattice Generation"
                
                Layout.fillWidth: true
                Layout.leftMargin: 7
                Layout.rightMargin: 7
                
                RowLayout{
                    id: genDimSelect
                    Layout.fillWidth: true
                    TextContainer{
                        padding: 0
                        text: "Gen dim:"
                        Layout.minimumWidth: contentWidth
                        Layout.fillWidth: true
                    }
                    Switch{
                        bottomPadding: 0
                        topPadding: 5
                        text: hypervisor.is2D ? "2D" : "3D"
                        checked: !hypervisor.is2D
                        onToggled: position == 0 ? hypervisor.is2D = true : hypervisor.is2D = false
                    }
                }
                TextContainer{
                    text: "Generation method:"
                    bottomPadding: 4
                    topPadding: 0
                    Layout.fillHeight: true
                    Layout.preferredWidth: contentWidth
                }
                RowLayout{
                    id: genMethodSelect
                    Layout.fillWidth: true
                    Item{Layout.fillWidth: true }
                    ComboBox {
                        id: genModeCB
                        focus: down
                        model: ["Lattice", "Random", "Import"]
                        onActivated: hypervisor.generateMode = currentText
                        Component.onCompleted: currentIndex = indexOfValue(hypervisor.generateMode)
                        Connections{
                            target: hypervisor
                            function onGenerateModeChanged(){ genModeCB.currentIndex = genModeCB.indexOfValue(hypervisor.generateMode)}
                        }
                    }
                    Item{Layout.fillWidth: true }
                }
                Item{
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                }
                Loader{
                    Layout.fillWidth: true
                    sourceComponent: hypervisor.generateMode == "Lattice" ? latticeGenParamsFrame : hypervisor.generateMode == "Random" ? randomGenParamsFrame : importGenParamsFrame 
                }
                
                RowLayout{
                    id: genBuild
                    Layout.fillWidth: true
                    RoundButton{
                        Material.elevation: 1
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: height
                        text: "Delete initial dipoles"
                        ToolTip{
                            y: -35
                            delay: 250
                            visible: parent.hovered
                            text: parent.text
                        }
                        icon{
                            source: "qrc:/icons/delete"
                            color: iconsColor
                            height: 19
                            width: 19
                        }
                        onClicked: dipModel.reset()
                    }
                    Item{Layout.preferredWidth: 16}
                    RoundButton {
                        Layout.fillWidth: true
                        Material.elevation: 1
                        Layout.alignment: Qt.AlignHCenter
                        padding: 10
                        icon{
                            source: "qrc:/icons/build"
                            color: setColorAlpha(accentColor, 0.7)
                        }
                        text: "GENERATE"
                        onClicked: hypervisor.generate()
                    }
                }
                
                
            }
            FoldablePanel{
                id: simParams
                title: "Simulation"
                
                Layout.fillWidth: true
                Layout.leftMargin: 7
                Layout.rightMargin: 7

                GroupBox{
                    Layout.fillWidth: true
                    title: qsTr("Min Energy (O K)")
                    padding: 8
                    ColumnLayout{
                        anchors.fill: parent
                        spacing: 0
                        RowLayout{
                            id: minimiseEnergyDisplay
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            TextContainer{
                                text: "Minimum Energy:"
                                Layout.minimumWidth: contentWidth
                                Layout.fillWidth: true
                            }
                            TextInput {
                                Layout.alignment: Qt.AlignLeft
                                text: hypervisor.minEnergy.toExponential(5) + " (eV)"
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                selectByMouse: true
                                readOnly: true
                                color: textColor
                                verticalAlignment: TextEdit.AlignVCenter
                                wrapMode: TextEdit.WrapAnywhere
                            }
                        }

                        Frame {
                            Layout.fillWidth: true
                            padding: 9
                            ColumnLayout{
                                anchors.fill: parent
                                spacing: 2
                                TextContainer{
                                    text: "Lock moments 2D (on plane):"
                                    //Layout.minimumWidth: contentWidth
                                    Layout.fillWidth: true
                                }
                                Switch{
                                    text: hypervisor.lock2DMinEnergy ? "locked (2D spin)" : "unlocked (3D spin)"
                                    checked: hypervisor.lock2DMinEnergy
                                    onToggled: position == 0 ? hypervisor.lock2DMinEnergy = false : hypervisor.lock2DMinEnergy = true
                                }
                            }
                        }

                        RowLayout{
                            id: minimiseEnergyBuild
                            Layout.fillWidth: true
                            RoundButton{
                                Material.elevation: 1
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: height
                                icon{
                                    source: "qrc:/icons/delete"
                                    color: iconsColor
                                    height: 19
                                    width: 19
                                }
                                onClicked: hypervisor.cancelMinEnergyCompute()
                            }
                            Item{Layout.preferredWidth: 16}
                            RoundButton {
                                enabled: !hypervisor.minEnergyRunning
                                Layout.fillWidth: true
                                Material.elevation: 1
                                Layout.alignment: Qt.AlignHCenter
                                padding: 10
                                icon{
                                    source: "qrc:/icons/build"
                                    color: setColorAlpha(accentColor, 0.7)
                                }
                                text: "Min energy"
                                onClicked: hypervisor.computeMinEnergy()
                            }
                        }
                        RowLayout{
                            id: minimiseEnergyProgress
                            Layout.fillWidth: true
                            property double deltaTime: 0
                            function convertMillisecToHrMinSec(timeMillisec) {
                                var portions = []

                                var msInHour = 1000 * 60 * 60
                                var hours = Math.trunc(timeMillisec / msInHour)
                                if (hours > 0) {
                                    portions.push(hours + 'h')
                                    timeMillisec = timeMillisec - (hours * msInHour)
                                }

                                var msInMinute = 1000 * 60
                                var minutes = Math.trunc(timeMillisec / msInMinute)
                                if (minutes > 0) {
                                    portions.push(minutes + 'm')
                                    timeMillisec = timeMillisec - (minutes * msInMinute)
                                }

                                var seconds = Math.trunc(timeMillisec / 1000)
                                if (seconds >= 0) {
                                    timeMillisec = Math.trunc((timeMillisec - (seconds * 1000))/100)
                                    portions.push(seconds + "." + timeMillisec + 's')
                                }

                                return portions.join(' ')
                            }
                            Timer {
                                interval: 100; running: hypervisor.minEnergyRunning; repeat: true
                                onTriggered:{
                                    minimiseEnergyProgress.deltaTime += interval
                                    ellapsedTimeMinEnergy.text = minimiseEnergyProgress.convertMillisecToHrMinSec(minimiseEnergyProgress.deltaTime)
                                }
                            }
                            Connections{
                                target: hypervisor
                                function onMinEnergyRunningChanged(){
                                    if(hypervisor.minEnergyRunning){
                                        minimiseEnergyProgress.deltaTime = 0
                                    }
                                }
                            }
                            TextContainer{
                                id: ellapsedTimeMinEnergy
                            }
                            ProgressBar{
                                id: energyProgressBar
                                padding: 0
                                Layout.preferredHeight: 10
                                Layout.fillWidth: true
                                value: 0.0
                                indeterminate: hypervisor.minEnergyRunning
                            }
                        }
                    }
                }
                GroupBox{
                    Layout.fillWidth: true
                    title: qsTr("Min Energy Monte-Carlo")
                    padding: 8
                    ColumnLayout{
                        anchors.fill: parent
                        spacing: 0
                        RowLayout{
                            id: minimiseEnergyMCDisplay
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            TextContainer{
                                text: "Minimum Energy:"
                                Layout.minimumWidth: contentWidth
                                Layout.fillWidth: true
                            }
                            TextInput {
                                Layout.alignment: Qt.AlignLeft
                                text: hypervisor.minEnergyMC.toExponential(5) + " (eV)" //MODIFY HERE !!!!!!!
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                selectByMouse: true
                                readOnly: true
                                color: textColor
                                verticalAlignment: TextEdit.AlignVCenter
                                wrapMode: TextEdit.WrapAnywhere
                            }
                        }

                        Frame {
                            Layout.fillWidth: true
                            padding: 9
                            ColumnLayout{
                                anchors.fill: parent
                                spacing: 2
                                TextContainer{
                                    text: "Lock moments 2D (on plane):"
                                    Layout.fillWidth: true
                                }
                                Switch{
                                    text: hypervisor.lock2DMinEnergyMC ? "locked (2D spin)" : "unlocked (3D spin)"
                                    checked: hypervisor.lock2DMinEnergyMC
                                    onToggled: position == 0 ? hypervisor.lock2DMinEnergyMC = false : hypervisor.lock2DMinEnergyMC = true
                                }
                                TextContainer{
                                    text: "Number of iterations: "
                                    Layout.preferredWidth: contentWidth
                                }
                                InputContainer{
                                    Layout.alignment: Qt.AlignRight
                                    Layout.fillWidth: true
                                    enabled: !hypervisor.minEnergyMCRunning
                                    validator: RegExpValidator{regExp: /[0-9]+/}
                                    text: hypervisor.nbIterationsMC
                                    color: textColor
                                    onEditingFinished: hypervisor.nbIterationsMC = parseInt(text)
                                }
                                TextContainer{
                                    text: "Temperature (K): "
                                    Layout.preferredWidth: contentWidth
                                }
                                InputContainer{
                                    Layout.alignment: Qt.AlignRight
                                    Layout.fillWidth: true
                                    enabled: !hypervisor.minEnergyMCRunning
                                    validator: RegExpValidator{regExp: /[0-9.]+/}
                                    text: hypervisor.temperatureMC
                                    color: textColor
                                    onEditingFinished: hypervisor.temperatureMC = parseFloat(text)
                                }
                            }
                        }

                        RowLayout{
                            id: minimiseEnergyMCBuild
                            Layout.fillWidth: true
                            // RoundButton{
                            //     Material.elevation: 1
                            //     Layout.alignment: Qt.AlignHCenter
                            //     Layout.preferredWidth: height
                            //     icon{
                            //         source: "qrc:/icons/delete"
                            //         color: iconsColor
                            //         height: 19
                            //         width: 19
                            //     }
                            //     onClicked: hypervisor.cancelMinEnergyCompute()
                            // }
                            RoundButton {
                                enabled: !hypervisor.minEnergyMCRunning
                                Layout.fillWidth: true
                                Material.elevation: 1
                                Layout.alignment: Qt.AlignHCenter
                                padding: 10
                                icon{
                                    source: "qrc:/icons/build"
                                    color: setColorAlpha(accentColor, 0.7)
                                }
                                text: "Compute Monte Carlo"
                                onClicked: hypervisor.computeMinEnergyMC()
                            }
                        }
                        RowLayout{
                            id: minimiseEnergyMCProgress
                            Layout.fillWidth: true
                            property double deltaTime: 0
                            function convertMillisecToHrMinSec(timeMillisec) {
                                var portions = []

                                var msInHour = 1000 * 60 * 60
                                var hours = Math.trunc(timeMillisec / msInHour)
                                if (hours > 0) {
                                    portions.push(hours + 'h')
                                    timeMillisec = timeMillisec - (hours * msInHour)
                                }

                                var msInMinute = 1000 * 60
                                var minutes = Math.trunc(timeMillisec / msInMinute)
                                if (minutes > 0) {
                                    portions.push(minutes + 'm')
                                    timeMillisec = timeMillisec - (minutes * msInMinute)
                                }

                                var seconds = Math.trunc(timeMillisec / 1000)
                                if (seconds >= 0) {
                                    timeMillisec = Math.trunc((timeMillisec - (seconds * 1000))/100)
                                    portions.push(seconds + "." + timeMillisec + 's')
                                }

                                return portions.join(' ')
                            }
                            Timer {
                                interval: 100; running: hypervisor.minEnergyMCRunning; repeat: true
                                onTriggered:{
                                    minimiseEnergyMCProgress.deltaTime += interval
                                    ellapsedTimeMinEnergyMC.text = minimiseEnergyMCProgress.convertMillisecToHrMinSec(minimiseEnergyMCProgress.deltaTime)
                                }
                            }
                            Connections{
                                target: hypervisor
                                function onMinEnergyMCRunningChanged(){
                                    if(hypervisor.minEnergyMCRunning){
                                        minimiseEnergyMCProgress.deltaTime = 0
                                    }
                                }
                            }
                            TextContainer{
                                id: ellapsedTimeMinEnergyMC
                            }
                            ProgressBar{
                                id: energyMCProgressBar
                                padding: 0
                                Layout.preferredHeight: 10
                                Layout.fillWidth: true
                                value: 0.0
                                indeterminate: hypervisor.minEnergyMCRunning
                            }
                        }
                    }
                }
            }
        }
    }
}

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

Rectangle{
    id: root
    clip: true
    default property alias contentItem: contentItemContainer.children
    property alias title: titleContainer.text
    color: setColorAlpha(backgroundColorAlt, 0.9)
    radius: 5

    Settings {
        category: "parameterCasePanelIntern" + root.title
        property alias state: root.state
    }
    state: "FOLDED"
    states:[
        State {
            name: "FOLDED"
            PropertyChanges { target: canvas ; rotation: -90 }
            PropertyChanges { target: root ; implicitHeight: header.height }
        },
        State {
            name: "UNFOLDED"
            PropertyChanges { target: canvas ; rotation: 0}
            PropertyChanges { target: root ; implicitHeight: header.height + contentItemContainer.height + root.radius*2}
        }
    ]
    transitions: [
        Transition {
            ParallelAnimation{
                NumberAnimation{ target: canvas ; properties: "scale, rotation" ; duration: 200; easing.type: Easing.InOutQuad }
                NumberAnimation{ target: root ; properties: "implicitHeight" ; duration: 200; easing.type: Easing.InOutQuad }
            }
        }
    ]

    Item{
        id: header
        height: 40
        anchors{
            left: parent.left
            right: parent.right
            top: parent.top
        }
        Text {
            id: titleContainer
            fontSizeMode: Text.Fit
            elide: Text.ElideRight
            minimumPointSize: 7
            font.pointSize: 12
            font.capitalization: Font.AllUppercase
            wrapMode: Text.Wrap
            color: textColor
            anchors{
                rightMargin: 5
                leftMargin: 5
                right: dropDownMouseArea.left
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle{
            anchors{
                left: parent.left
                top: parent.bottom
                right: parent.right
                leftMargin: 10
                rightMargin: 10
            }
            height: 2
            radius: height/2
            color: borderColor
        }

        MouseArea{
            id: dropDownMouseArea
            anchors{
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }
            hoverEnabled: true
            width: height
            onClicked: root.state == "FOLDED" ? root.state = "UNFOLDED" : root.state = "FOLDED"

            Rectangle{
                anchors{
                    fill: parent
                    margins: 5
                }
                radius: 5
                color: setColorAlpha(backgroundColor, dropDownMouseArea.containsMouse ? (dropDownMouseArea.pressed ? 0.65 : 0.45) : 0)
                opacity: 0.5
            }

            Canvas {
                id: canvas
                x: Math.round((parent.width-width)/2)
                y: Math.round((parent.height-height)/2)
                width: 12
                height: 8
                contextType: "2d"
                function repaint(){
                    context.reset();
                    context.moveTo(0, 0);
                    context.lineTo(width, 0);
                    context.lineTo(width / 2, height);
                    context.fillStyle = iconsColor
                    context.closePath();
                    context.fill();
                }
                onPaint: {
                    getContext("2d")
                    if(context !== null)repaint()
                }
            }
        }
    }

    ColumnLayout{
        id: contentItemContainer
        transformOrigin: Item.Top
        anchors{
            left: parent.left
            right: parent.right
            top: header.bottom
            leftMargin: root.radius
            rightMargin: root.radius
            topMargin: root.radius
        }

        //here goes children
    }
}

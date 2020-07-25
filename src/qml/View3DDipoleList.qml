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
import Qt.labs.qmlmodels 1.0


Popup{
    id: root

    height: 200
    width: 400
    property int boxWeight: 30
    property int boxLeftMargin: boxWeight/4 //5

    background: Rectangle{
            color: backgroundColor
            radius:5        
        }
    
    ListView {
        id: listView

        clip: true
        anchors.fill: parent
        boundsBehavior: Flickable.StopAtBounds
        
        model: dipModel
        header: listHeader

        delegate: RowLayout{
            id: dipoleLayout

            TextInput {
                id: text1
                text: index + 1
                color: textColor
                readOnly: true
                Layout.preferredWidth:30
            }
            TextInput{
                text: position3D.x.toFixed(5)
                color: textColor
                onEditingFinished: position3D.x=text
                // Layout.preferredWidth:boxWeight
                Layout.minimumWidth: contentWidth
                Layout.preferredWidth: 100
            }
            TextInput{
                //Layout.column:2
                text: position3D.y.toFixed(5)
                color: textColor
                onEditingFinished: position3D.y=text
                // Layout.preferredWidth:boxWeight
                Layout.minimumWidth: contentWidth
                Layout.preferredWidth: 100
            }
            TextInput{
                //Layout.column:3
                text: position3D.z.toFixed(5)
                color: textColor
                onEditingFinished: position3D.z=text
                // Layout.preferredWidth:boxWeight
                Layout.minimumWidth: contentWidth
                Layout.preferredWidth: 100
            }                                                               
        }

        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            width: 12
            contentItem: Rectangle {
                radius: parent.width / 2
                color: scrollBar.pressed ? setColorAlpha(iconsColor, 0.45) : setColorAlpha(iconsColor, 0.25) 
            } 
            anchors{
                right: parent.right
                rightMargin:0
            }
        }        
    }
    
    Component{
        id: listHeader        
        RowLayout{
            id: columnName
            spacing:5
            Text{
                id: txtIndex
                text:"index"
                color: textColor
                Layout.preferredWidth: 30
            }
            Text{
                text: "X"
                color: textColor
                Layout.leftMargin:boxLeftMargin
                Layout.preferredWidth: 100
                }
            Text{
                text: "Y"
                color: textColor
                Layout.leftMargin:boxLeftMargin
                Layout.preferredWidth: 100
            }
            Text{
                text: "Z"
                color: textColor
                Layout.leftMargin:boxLeftMargin
                Layout.preferredWidth: 100
            }
        }
    }
}

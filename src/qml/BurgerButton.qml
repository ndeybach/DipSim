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

import QtQuick 2.13
import QtQuick.Controls 2.13

TabButton {
  id: burgerButton
  onClicked: state = state === "menu" ? "back" : "menu"
  background: Item {}
  rotation: (state === "back" ? 360 : 0) - Math.round(position*180)
  implicitWidth: 28
  implicitHeight: 26
  property color burgerColor: palette.shadow
  property real radius: 1
  property real thickness: 0.4
  property int barsHeight: Math.ceil(parent.height * .15 * thickness)
  required property real position

  property int animationDuration: 250

  opacity: pressed ? 0.7 : 1.0
  Rectangle {
    id: bar1
    x: burgerButton.width * .5 * position
    y: parent.height * .25 + ( (parent.height/3) - height - parent.height * .25)*position
    width: parent.width * (1- 0.44*position)
    height: barsHeight
    radius: parent.radius
    color: burgerColor
    antialiasing: true
    rotation: Math.round(position*45)
  }

  Rectangle{
    id: bar2
    x: burgerButton.width * .2 * position
    y: parent.height * .5 + (parent.height * .5 - height - parent.height * .5)*position
    width: parent.width * (1- 0.3*position)
    height: barsHeight
    radius: parent.radius
    color: burgerColor
    antialiasing: true
  }

  Rectangle {
    id: bar3
    x: burgerButton.width * .5 * position
    y: parent.height * .75 + ( (parent.height*2/3) - height - parent.height * .75)*position
    width: parent.width * (1- 0.45*position)
    height: barsHeight
    radius: parent.radius
    color: burgerColor
    antialiasing: true
    rotation: Math.round(-position*45)
  }

  state: "menu"
  states: [
    State {name: "menu"},
    State { name: "back"}
  ]
}

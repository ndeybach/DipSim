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

Item {
    id: root
    required property Node controlledObject
    required property View3D controlledview3D

    property real speed: 1
    property real shiftSpeed: 4

    property real mouseSpeed: 0.2
    property real keySpeed: 8

    property real forwardSpeed: keySpeed
    property real backSpeed: keySpeed
    property real rightSpeed: keySpeed
    property real leftSpeed: keySpeed
    property real upSpeed: keySpeed
    property real downSpeed: keySpeed
    property real xSpeed: mouseSpeed
    property real ySpeed: mouseSpeed

    property bool xInvert: false
    property bool yInvert: true

    property bool mouseEnabled: true
    property bool keysEnabled: true

    property alias running: root.inputsNeedProcessing   // here to debug the spinbox

    readonly property bool inputsNeedProcessing: status.moveForward | status.moveBack
                                                 | status.moveLeft | status.moveRight
                                                 | status.moveUp | status.moveDown
                                                 | status.useMouse

    property alias acceptedButtons: dragHandler.acceptedButtons

    focus: keysEnabled

    signal pickAt(real x, real y)

    implicitWidth: parent.width
    implicitHeight: parent.height

    TapHandler{
        grabPermissions: PointerHandler.CanTakeOverFromHandlersOfDifferentType
        onPressedChanged: if(pressed) root.forceActiveFocus()
        onSingleTapped: root.pickAt(eventPoint.position.x, eventPoint.position.y)
        // onSingleTapped:{ // pick for info not working, maybe bug to be fixed on next update
        //     console.log("event x: " + eventPoint.position.x + " event y: " + eventPoint.position.y)
        //     var pickres = controlledview3D.pick(50, 50)
        //     console.log(pickres)
        //     console.log(pickres.distance)
        //     console.log(pickres.objectHit)
        //     console.log(pickres.scenePosition)
        //     console.log(pickres.uvPosition)
        // }
    }

    DragHandler {
        id: dragHandler
        target: null
        enabled: mouseEnabled
        grabPermissions: PointerHandler.CanTakeOverFromHandlersOfDifferentType
        onCentroidChanged: {
            //root.forceActiveFocus()
            mouseMoved(Qt.vector2d(centroid.position.x, centroid.position.y));
        }
        onGrabChanged: console.log(point)

        onActiveChanged: {
            if (active){
                root.focus = true
                mousePressed(Qt.vector2d(centroid.position.x, centroid.position.y));
            }
            else
                mouseReleased(Qt.vector2d(centroid.position.x, centroid.position.y));
        }
    }

    Keys.onPressed: if (keysEnabled) handleKeyPress(event)
    Keys.onReleased: if (keysEnabled) handleKeyRelease(event)

    function mousePressed(newPos) {
        status.currentPos = newPos
        status.lastPos = newPos
        status.useMouse = true;
    }

    function mouseReleased(newPos) {
        status.useMouse = false;
    }

    function mouseMoved(newPos) {
        status.currentPos = newPos;
    }

    function forwardPressed() {
        status.moveForward = true
        status.moveBack = false
    }

    function forwardReleased() {
        status.moveForward = false
    }

    function backPressed() {
        status.moveBack = true
        status.moveForward = false
    }

    function backReleased() {
        status.moveBack = false
    }

    function rightPressed() {
        status.moveRight = true
        status.moveLeft = false
    }

    function rightReleased() {
        status.moveRight = false
    }

    function leftPressed() {
        status.moveLeft = true
        status.moveRight = false
    }

    function leftReleased() {
        status.moveLeft = false
    }

    function upPressed() {
        status.moveUp = true
        status.moveDown = false
    }

    function upReleased() {
        status.moveUp = false
    }

    function downPressed() {
        status.moveDown = true
        status.moveUp = false
    }

    function downReleased() {
        status.moveDown = false
    }

    function shiftPressed() {
        status.shiftDown = true
    }

    function shiftReleased() {
        status.shiftDown = false
    }

    function handleKeyPress(event)
    {
        switch (event.key) {
        case Qt.Key_Z:
        case Qt.Key_Up:
            forwardPressed();
            break;
        case Qt.Key_S:
        case Qt.Key_Down:
            backPressed();
            break;
        case Qt.Key_Q:
        case Qt.Key_Left:
            leftPressed();
            break;
        case Qt.Key_D:
        case Qt.Key_Right:
            rightPressed();
            break;
        case Qt.Key_R:
        case Qt.Key_Space:
        case Qt.Key_PageUp:
            upPressed();
            break;
        case Qt.Key_F:
        case Qt.Key_Shift:
        case Qt.Key_PageDown:
            downPressed();
            break;
        case Qt.Key_Control:
            shiftPressed();
            break;
        }
    }

    function handleKeyRelease(event)
    {
        switch (event.key) {
        case Qt.Key_Z:
        case Qt.Key_Up:
            forwardReleased();
            break;
        case Qt.Key_S:
        case Qt.Key_Down:
            backReleased();
            break;
        case Qt.Key_Q:
        case Qt.Key_Left:
            leftReleased();
            break;
        case Qt.Key_D:
        case Qt.Key_Right:
            rightReleased();
            break;
        case Qt.Key_R:
        case Qt.Key_Space:
        case Qt.Key_PageUp:
            upReleased();
            break;
        case Qt.Key_F:
        case Qt.Key_Shift:
        case Qt.Key_PageDown:
            downReleased();
            break;
        case Qt.Key_Control:
            shiftReleased();
            break;
        }
    }

    Timer {
        id: updateTimer
        interval: 16
        repeat: true
        running: root.inputsNeedProcessing
        onTriggered: {
            processInputs();
        }
    }

    function processInputs()
    {
        if (root.inputsNeedProcessing)
            status.processInput();
    }

    QtObject {
        id: status

        property bool moveForward: false
        property bool moveBack: false
        property bool moveLeft: false
        property bool moveRight: false
        property bool moveUp: false
        property bool moveDown: false
        property bool shiftDown: false
        property bool useMouse: false

        property vector2d lastPos: Qt.vector2d(0, 0)
        property vector2d currentPos: Qt.vector2d(0, 0)

        function updatePosition(vector, speed, position)
        {
            if (shiftDown)
                speed *= shiftSpeed;
            else
                speed *= root.speed

            var direction = vector;
            var velocity = Qt.vector3d(direction.x * speed,
                                       direction.y * speed,
                                       direction.z * speed);
            controlledObject.position = Qt.vector3d(position.x + velocity.x,
                                                    position.y + velocity.y,
                                                    position.z + velocity.z);
        }

        function negate(vector) {
            return Qt.vector3d(-vector.x, -vector.y, -vector.z)
        }

        function processInput() {
            if (controlledObject == undefined)
                return;

            if (moveForward)
                updatePosition(controlledObject.forward, forwardSpeed, controlledObject.position);
            else if (moveBack)
                updatePosition(negate(controlledObject.forward), backSpeed, controlledObject.position);

            if (moveRight)
                updatePosition(controlledObject.right, rightSpeed, controlledObject.position);
            else if (moveLeft)
                updatePosition(negate(controlledObject.right), leftSpeed, controlledObject.position);

            if (moveDown)
                updatePosition(negate(controlledObject.up), downSpeed, controlledObject.position);
            else if (moveUp)
                updatePosition(controlledObject.up, upSpeed, controlledObject.position);

            if (useMouse) {
                // Get the delta
                var rotationVector = controlledObject.eulerRotation;
                var delta = Qt.vector2d(lastPos.x - currentPos.x,
                                        lastPos.y - currentPos.y);
                // rotate x
                var rotateX = delta.x * xSpeed
                if (xInvert)
                    rotateX = -rotateX;
                rotationVector.y += rotateX;

                // rotate y
                var rotateY = delta.y * -ySpeed
                if (yInvert)
                    rotateY = -rotateY;
                rotationVector.x += rotateY;
                controlledObject.setEulerRotation(rotationVector);
                lastPos = currentPos;
            }
        }
    }
}

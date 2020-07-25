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

Node{
    id: nanoPartModel
    // Nano particule model with arrow that points on
    property real ratioLengthTipToBody: 0.39 //ratio of tip length in regard to total size
    property real ratioRadiusTipToBody: 2 //1.71 //ratio of tip radius in regard to body radius
    property real bodyRadius: 0.1*length
    property real length: 150 //total length
    property alias color: principledMaterial.baseColor

    position: Qt.vector3d(0, 0, 0)
    eulerRotation: Qt.vector3d(0, 0, 0)
    Node{
        position: Qt.vector3d(0, 0, 0)
        eulerRotation: Qt.vector3d(0, 0, -90)
        Model {
            id: dipoleMomentTip
            source: "#Cone"
            materials: principledMaterial

            property real radius: nanoPartModel.bodyRadius*nanoPartModel.ratioRadiusTipToBody
            property real length: nanoPartModel.length*nanoPartModel.ratioLengthTipToBody
            position: Qt.vector3d(0, nanoPartModel.length*(0.5-nanoPartModel.ratioLengthTipToBody), 0)
            scale: Qt.vector3d(radius/bounds.maximum.x, length/bounds.maximum.y, radius/bounds.maximum.z)
        }
        Model {
            id: dipoleMomentBody
            source: "#Cylinder"
            materials: principledMaterial

            property real radius: nanoPartModel.bodyRadius
            property real length: nanoPartModel.length*(1-nanoPartModel.ratioLengthTipToBody)
            position: Qt.vector3d(0, -nanoPartModel.length*0.5*nanoPartModel.ratioLengthTipToBody, 0)
            scale: Qt.vector3d(radius/(bounds.maximum.x), length/(2*bounds.maximum.y), radius/(bounds.maximum.z))
        }
        PrincipledMaterial {
            id: principledMaterial
            baseColor: "steelblue"
            metalness: 0.6
            roughness: 0.03
            specularAmount: 4
            indexOfRefraction: 2.5
            opacity: 1.0
        }
    }
    
    
}

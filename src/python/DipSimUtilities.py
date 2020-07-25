# This Python file uses the following encoding: utf-8

"""
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
"""

"""
It serves as a containers for various utility functions. They can be useful in a multitude of cases.
"""
from math import cos, sin, radians, degrees, acos, atan2, pi

from PySide2.QtCore import QRandomGenerator
from PySide2.QtGui import QVector3D, QColor, QQuaternion

######## NUMBER GENERATION #########

"""
Return randomly -1 or 1 as a random sign generator.
"""
def randomSignGenerator():
    rndNum = QRandomGenerator.global_().bounded(0, 2)
    if(rndNum == 0):
        return -1.0
    else: return 1.0

######## ANGLES CONVERTIONS #########

"""
Returns rotated quaternion from a rotation (theta) applied to original
direction around specified axis.
"""
def quaternionfromAxisAndAngle(theta, qvector3D=QVector3D(0, 0, 0)):
    provVect = (qvector3D.normalized())
    s = sin(radians(theta/2))
    directionRot = QVector3D(s*provVect.x(), s*provVect.y(), s*provVect.z())
    quat = QQuaternion(cos(radians(theta/2)), directionRot.x(), directionRot.y(), directionRot.z())
    return quat

"""
Returns quaternion rotation from spherical position (following physics convention) with 
a (1,0,0) oriention initialy.
phi, theta: angles in physics convention in degrees.
"""
def anglesSphToQuaternion(phi, theta):
    x = sin(radians(theta))*cos(radians(phi))
    y = sin(radians(theta))*sin(radians(phi))
    z = cos(radians(theta))
    fromVec = QVector3D(1, 0, 0)
    toVec = QVector3D(x, y, z)
    return QQuaternion.rotationTo(fromVec, toVec)

"""
Returns orientation (following physics convention) to a quaternion representing the rotation
needed to get a vector to follow the orientation
"""
def anglesQuaternionToSph(quaternion):
    fromVect = QVector3D(1, 0, 0)
    toVect = quaternion.rotatedVector(fromVect)
    phi = atan2(toVect.y(), toVect.x())
    theta = acos(toVect.z()/toVect.length())
    return [phi, theta]

######## COLORS #########

def quaternionToColor(quaternion):
    sphAngles = anglesQuaternionToSph(quaternion)
    return angleSphToColor(sphAngles[0], sphAngles[1])

"""
Returns a color from a 3D vector of angles.
phi, theta: angles in physics convention in radians.
"""
def angleSphToColor(phi, theta):
    return QColor.fromHsl(degrees(phi)%360, 255, (degrees(pi - theta)%181)*255/180)

"""
Returns a random color.
"""
def rndColorGenerator():
    return QColor(QRandomGenerator.global_().bounded(0, 256), QRandomGenerator.global_().bounded(0, 256), QRandomGenerator.global_().bounded(0, 256))

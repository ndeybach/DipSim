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

from copy import deepcopy

from math import cos, sin, radians, degrees
from enum import Enum

from PySide2 import QtCore, QtGui
from PySide2.QtCore import QObject, QAbstractListModel, QRandomGenerator, Signal, Slot, Property
from PySide2.QtGui import QVector3D, QColor
from PySide2 import QtWidgets

from .DipSimUtilities import *
"""
Represent a dipole with all important caracteristics.
position: position in 3D space as a QVector3D with its x, y, z values
_quaternion: Rotation of the dipole as a QQuaternion
colorCorrespondToAngle: boolean representing if color was imposed or if it correspond to "_quaternion" (in HSL sperical value)
color: color to display the model with in the 3D view
moment: moment of the dipole in bohr magneton
"""
class Dipole(QObject):
    def __init__(self, positionVector=QVector3D(0.0, 0.0, 0.0), quaternion=QQuaternion(1, 0, 0, 0), color=None, isInSim = False, moment=50, parent=None):
        super(Dipole, self).__init__(parent)
        self.position = positionVector
        self._quaternion = quaternion
        self.colorCorrespondToAngle = True if color is None else False
        self.color = quaternionToColor(quaternion) if self.colorCorrespondToAngle else color
        self.moment = moment
        
    """
    Qt Property: access the quaternion inside the dipole object
    """
    def getQuaternion(self):
        return self._quaternion
    def setQuaternion(self, quaternion):
        if quaternion != self._quaternion:
            self._quaternion = quaternion
            if self.colorCorrespondToAngle:
                self.color = quaternionToColor(quaternion)
            self.quaternionChanged.emit()
    quaternionChanged = Signal()
    quaternion = Property(QQuaternion, getQuaternion, setQuaternion, notify=quaternionChanged)
    
    def __deepcopy__(self, memo):
        cls = self.__class__
        result = cls.__new__(cls)
        super(Dipole, result).__init__()
        memo[id(self)] = result
        for k, v in self.__dict__.items():
            if(k not in ("quaternion", "quaternionChanged")):
                setattr(result, k, deepcopy(v, memo))
            elif(k == "quaternion"):
                result.quaternionChanged = Signal()
                result.quaternion = Property(QQuaternion, result.getQuaternion, result.setQuaternion, notify=result.quaternionChanged)
        return result
    
    """
    A way to instantiate a dipole by composents instead of passing a QVector3D
    """
    @classmethod
    def initByComposent(cls, xPos=0.0, yPos=0, zPos=0, quaternion=QQuaternion(1, 0, 0, 0), color=None, moment=1, parent=None):
        positionVector = QVector3D(xPos, yPos, zPos)
        return cls(positionVector, quaternion, color,moment=moment, parent=parent)
    
    """
    Generates a dipole with fully random position and quaternion if respectively not passed as arguments.
    genType: round or square
    """
    @classmethod
    def rndDipoleGenerator(cls, positionVector=None, quaternion=None, color=None, genSize=5000.0, is2D=True, genType="round", parent=None):
        if(positionVector is None):
            positionVector = cls.rndPosVectGenerator(genSize, is2D, genType)
        
        if(quaternion is None):
            quaternion = cls.rndQuaternionGenerator()

        return cls(positionVector, quaternion, color, parent=parent)

    """
    Generates a random position.
    genSize: float of maximum size of generation (radius if "round", edge if "square")
    is2D: wether generation should be on a plane or in 2D space.
    genType: string of the generation mode, round or square.
    """
    @classmethod
    def rndPosVectGenerator(cls, genSize=5000.0, is2D=True, genType="round"):
        if(genType == "round"):
            initVect = QVector3D(QRandomGenerator.global_().generateDouble()*genSize, 0, 0)
            return cls.rndQuaternionGenerator(is2D=is2D).rotatedVector(initVect)
        elif(genType == "square"):
            xPos = randomSignGenerator()*QRandomGenerator.global_().generateDouble()*genSize
            yPos = randomSignGenerator()*QRandomGenerator.global_().generateDouble()*genSize
            zPos = 0.0 if is2D else randomSignGenerator()*QRandomGenerator.global_().generateDouble()*genSize
            return QVector3D(xPos, yPos, zPos)
        else: return QVector3D(0, 0, 0)
    
    """
    Generates a random Quaternion for dipoles.
    is2D: wether generation should be on a plane or in 2D space
    """
    @classmethod
    def rndQuaternionGenerator(cls, is2D = False):
        phi = QRandomGenerator.global_().generateDouble()*360
        theta = 90 if is2D else QRandomGenerator.global_().generateDouble()*180
        return anglesSphToQuaternion(phi, theta)

"""
Model containing dipoles and interacting with the QML view when data (dipoles) are changed, moved or replaced.
self.roles: represent a list of data types to be recognized and passed to QML on demand.
self.dipoles: dipoles contained by the model.
"""
class DipModel(QAbstractListModel):
    def __init__(self, dipoles, parent=None):
        super(DipModel, self).__init__(parent)

        self.roles={
            0: "position3D",
            1: "quaternion",
            2: "dipColor",
        }
        self.dipoles = dipoles
    
    """
    Empty model and signal it to the view.
    """
    @Slot()
    def reset(self):
        self.beginResetModel()
        self.dipoles = []
        self.endResetModel()
    
    """
    Empty model and add "newDipoles" list. Then signals it to the view.
    newDipoles: list of new Dipoles.
    """
    def replaceAllDipoles(self, newDipoles):
        """ replace dipoles in model by dipoles in argument list """
        self.beginResetModel()
        self.dipoles = newDipoles
        self.endResetModel()

    """
    Get a copy of dipoels inside this instance of model.
    """
    def getDipolesCopy(self):
        return deepcopy(self.dipoles)
    
    """
    Append a Dipole at end of model's list. Then signal it to view.
    """
    def append(self, dipole):
        """Append item to end of model"""
        self.beginInsertRows(QtCore.QModelIndex(),
                             self.rowCount(),
                             self.rowCount())

        self.dipoles.append(dipole)
        self.endInsertRows()

    """
    Returns data with the corresponding "index" and "roleID".
    Ex: "index" = 0 for first item in model and "roleID" = position3D to access its corressponding position
    """
    def data(self, index, roleID):
        """Return value of dipole role at index"""
        if(self.roles.get(roleID) == "position3D"): 
            return self.dipoles[index.row()].position

        elif(self.roles.get(roleID) == "quaternion"):
            return self.dipoles[index.row()].quaternion

        elif(self.roles.get(roleID) == "dipColor"):
            return self.dipoles[index.row()].color

    """
    Sets data with the corresponding "index" and "roleID" to "value"
    See data() description for more information.
    """
    def setData(self, index, value, roleID):
        """Set role of dipole at index to `value`"""
        if(self.roles.get(roleID) == "position3D"):
            self.dipoles[index.row()].position = value
            self.dataChanged.emit(index, index)

        elif(self.roles.get(roleID) == "quaternion"):
            self.dipoles[index.row()].quaternion = value
            self.dataChanged.emit(index, index)

        elif(self.roles.get(roleID) == "dipColor"):
            self.dipoles[index.row()].color = value
            self.dataChanged.emit(index, index)

        else:
            return False
            
        return True
    
    """
    Returns length of the list model.
    """
    def rowCount(self, parent=QtCore.QModelIndex()):
        """Number of dipoles in model"""
        return len(self.dipoles)

    """
    Returns list of all role names supported by this model.
    """
    def roleNames(self):
        """Role names are used by QML to map key to role"""
        byteRoles = self.roles.copy()
        for key in byteRoles:
            byteRoles[key] = QtCore.QByteArray(bytearray(byteRoles[key], 'utf-8'))
        return byteRoles

"""
Not implemented or used at the time.
Shoud represent the whole lattice with links between dipoles if possible.
"""
class LatticeModel(QAbstractListModel):
    def __init__(self, lattices, parent=None):
        super(LatticeModel, self).__init__(parent)

        self.roles = [
            "lines",
            "quaternion",
            "color",
        ]

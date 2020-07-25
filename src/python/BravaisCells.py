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
from math import cos, sin, radians, sqrt

from itertools import combinations

from PySide2.QtCore import QObject, QSettings, Signal, Slot, Property
from PySide2.QtGui import QVector3D

"""
Primitive cell for a bravias lattice. Names of the different types are based on a combinaison of family and types.

crystalType : type of crystal in cell (ex: monoclinic, hexagonal, ...)
crystalFamily : family of crystal in cell (ex: P, I, ...)
is2D: wether cell is on plane (2D) or 3D cell
a, b, c : parameters for lattice lengths
gamma, alpha, beta : angles of prim cell
minDist: minimum distance between two dipoles in cell

translations :  list of QVector3D with ratio in regard to each axis where 
                the point should be in cell. Ex: QVector3D(0.5, 0.5, 0.5) in middle.
"""
class PrimCell(QObject):
    def __init__(self,crystalType="custom", crystalFamily="P", a=None, b=None, c=None, alpha=None, beta=None, gamma=None, is2D=False, otherTranslations = None, parent=None):
        super(PrimCell, self).__init__(parent)
        
        self.crystalType = crystalType
        self.crystalFamily = crystalFamily
        self.is2D = is2D

        self.gamma = None
        self.alpha = None
        self.beta = None
        
        self.a = None
        self.b = None
        self.c = None
        self.minDist = 100

        self.translations = [] if otherTranslations is None else otherTranslations # translations in miller indices stored in QtVector3D
        self.points = []

    cellChanged = Signal()
    def generatePrimCell(self, a=None, b=None, c=None, alpha=None, beta=None, gamma=None, resetTranslations=True):
        if(self.is2D):
            self.c = 0
            self.alpha = 0
            self.beta = 0
            if(self.crystalType != "custom"):
                if(self.crystalType == "mono"):
                    self.gamma = 15 if gamma is None else gamma
                    self.a = 150 if a is None else a
                    self.b = 200 if b is None else b
                elif(self.crystalType == "ortho"):
                    self.gamma = 90
                    self.a = 300 if a is None else a
                    self.b = 200 if b is None else b
                elif(self.crystalType == "tetra"):
                    self.a = 200 if a is None else a
                    self.b = self.a
                    self.gamma = 90
                elif(self.crystalType == "hex"):
                    self.gamma = 120
                    self.a = 300 if a is None else a
                    self.b = self.a

                if resetTranslations:
                    self.translations = [QVector3D(0, 0, 0), QVector3D(1, 0, 0), QVector3D(0, 1, 0), QVector3D(1, 1, 0)]
                else:
                    self.translations += [QVector3D(0, 0, 0), QVector3D(1, 0, 0), QVector3D(0, 1, 0), QVector3D(1, 1, 0)]

                if(self.crystalFamily != "P"):
                    if(self.crystalFamily == "A"):
                        self.translations += [QVector3D(0.5, 0, 0), QVector3D(0.5, 1, 0)]
                    elif(self.crystalFamily == "B"):
                        self.translations += [QVector3D(0, 0.5, 0), QVector3D(1, 0.5, 0)]
                    elif(self.crystalFamily == "I"):
                        self.translations.append(QVector3D(0.5, 0.5, 0))
        else: # if 3D
            if(self.crystalType != "custom"):

                if(self.crystalType == "tri"):
                    self.gamma = 60. if gamma is None else gamma
                    self.alpha = 70. if alpha is None else alpha
                    self.beta = 70. if beta is None else beta
                    self.a = 200 if a is None else a
                    self.b = 200 if b is None else b
                    self.c = 300 if c is None else c
                elif(self.crystalType == "mono"):
                    self.gamma = 90.
                    self.alpha = 90.
                    self.beta = 70. if beta is None else beta
                    self.a = 200 if a is None else a
                    self.b = 200 if b is None else b
                    self.c = 300 if c is None else c
                elif(self.crystalType == "ortho"):
                    self.gamma = 90.
                    self.alpha = 90.
                    self.beta = 90.
                    self.a = 200 if a is None else a
                    self.b = 250 if b is None else b
                    self.c = 300 if c is None else c
                elif(self.crystalType == "tetra"):
                    self.gamma = 90.
                    self.alpha = 90.
                    self.beta = 90.
                    self.a = 200 if a is None else a
                    self.b = self.a
                    self.c = 300 if c is None else c
                elif(self.crystalType == "hex_rhomb"):
                    self.gamma = 60. if gamma is None else gamma
                    self.alpha = self.gamma
                    self.beta = self.gamma
                    self.a = 200 if a is None else a
                    self.b = self.a
                    self.c = self.a
                elif(self.crystalType == "hex_hex"):
                    self.gamma = 120.
                    self.alpha = 90.
                    self.beta = 90.
                    self.a = 200 if a is None else a
                    self.b = self.a
                    self.c = 300 if c is None else c
                elif(self.crystalType == "cub"):
                    self.gamma = 90.
                    self.alpha = 90.
                    self.beta = 90.
                    self.a = 200 if a is None else a
                    self.b = self.a
                    self.c = self.a


                if self.crystalType in  ["mono", "ortho", "tetra", "hex_hex", "cub"]: # for all except "hex_rhomb"
                    self.alpha = 90.
                    if self.crystalType in  ["ortho", "tetra", "hex_hex", "cub"]:
                        self.beta = 90.
                    if self.crystalType in  ["mono", "ortho", "tetra"]:
                        self.gamma = 90.
                    if self.crystalType in "hex_hex":
                        self.gamma = 120.
                
                if self.crystalType in ["tetra", "hex_rhomb", "hex_hex", "cub"]:
                    self.a = self.a
                    self.b = self.a
                    if self.crystalType in ["hex_rhomb", "cub"]:
                        self.c = self.a

                if resetTranslations:
                    self.translations = [QVector3D(0, 0, 0), QVector3D(1, 0, 0), QVector3D(0, 1, 0), QVector3D(1, 1, 0), QVector3D(0, 0, 1), QVector3D(1, 0, 1), QVector3D(0, 1, 1), QVector3D(1, 1, 1)]
                else:
                    self.translations += [QVector3D(0, 0, 0), QVector3D(1, 0, 0), QVector3D(0, 1, 0), QVector3D(1, 1, 0), QVector3D(0, 0, 1), QVector3D(1, 0, 1), QVector3D(0, 1, 1), QVector3D(1, 1, 1)]
                if(self.crystalFamily != "P"):
                    if(self.crystalFamily == "A"):
                        self.translations += [QVector3D(0, 0.5, 0.5), QVector3D(1, 0.5, 0.5)]
                    elif(self.crystalFamily == "B"):
                        self.translations += [QVector3D(0.5, 0, 0.5), QVector3D(0.5, 1, 0.5)]
                    elif(self.crystalFamily == "C"):
                        self.translations += [QVector3D(0.5, 0.5, 0), QVector3D(0.5, 0.5, 1)]
                    elif(self.crystalFamily == "F"):
                        self.translations += [QVector3D(0, 0.5, 0.5), QVector3D(1, 0.5, 0.5), QVector3D(0.5, 0, 0.5), QVector3D(0.5, 1, 0.5), QVector3D(0.5, 0.5, 0), QVector3D(0.5, 0.5, 1)]
                    elif(self.crystalFamily == "I"):
                        self.translations.append(QVector3D(0.5, 0.5, 0.5))

        if self.gamma is None:
            self.gamma = -1
        if self.alpha is None:
            self.alpha = -1
        if self.beta is None:
            self.beta = -1
        
        # init min distance in lattice cell ==> to use as a sizing unit
        self.points = []
        bxProjCoef = cos(radians(self.gamma))
        byProjCoef = sin(radians(self.gamma))
        cxProjCoef = 0.
        cyProjCoef = 0.
        for point in self.translations:
            aPointVector = QVector3D(self.a*point.x(), 0, 0)
            bPointVector = QVector3D(self.b*point.y()*bxProjCoef, self.b*byProjCoef*point.y(), 0)
            if(not self.is2D):
                cxProjCoef = cos(radians(self.beta))
                cyProjCoef = (cos(radians(self.alpha)) - cos(radians(self.beta))*cos(radians(self.gamma)))/sin(radians(self.gamma))
            if(not self.is2D):
                cPointVector = QVector3D(0, 0, 0) if self.is2D else QVector3D(self.c*cxProjCoef, self.c*cyProjCoef, abs(self.c*point.z())*sqrt(1 - (cxProjCoef)**2 - (cyProjCoef)**2))
                self.points.append(aPointVector + bPointVector + cPointVector)
            else:
                self.points.append(aPointVector + bPointVector)
        minComb = min(list(combinations(self.points, 2)), key=lambda comb: comb[0].distanceToPoint(comb[1]))
        self.minDist = minComb[0].distanceToPoint(minComb[1])
        self.cellChanged.emit()

    def isPrimCellALocked(self, is2D, crystalType):
        return False
    
    def isPrimCellBLocked(self, is2D, crystalType):
        if is2D:
            return crystalType in ("tetra", "hex")
        else:
            return crystalType in ("tetra", "hex_rhomb", "hex_hex", "cub")
    
    def isPrimCellCLocked(self, is2D, crystalType):
        if is2D:
            return True
        else:
            return crystalType in ("hex_rhomb", "cub")

    def isPrimCellGammaLocked(self, is2D, crystalType):
        if is2D:
            return crystalType in ("ortho", "tetra", "hex")
        else:
            return crystalType in ("mono", "ortho", "tetra", "hex_hex", "cub")
    
    def isPrimCellAlphaLocked(self, is2D, crystalType):
        if is2D:
            return True
        else:
            return crystalType in ("mono", "ortho", "tetra", "hex_rhomb", "hex_hex", "cub")
    
    def isPrimCellBetaLocked(self, is2D, crystalType):
        if is2D:
            return True
        else:
            return crystalType in ("ortho", "tetra", "hex_rhomb", "hex_hex", "cub")
    
    def __deepcopy__(self, memo):
        cls = self.__class__
        result = cls.__new__(cls)
        memo[id(self)] = result
        for k, v in self.__dict__.items():
            if(k not in ("cellChanged")):
                setattr(result, k, deepcopy(v, memo))
            elif(k == "cellChanged"):
                result.cellChanged = Signal()
        return result

###### CLASSES TO USE DIRECTLY FOR GENERAL BRAVAIS CELLS ######

class Mono2DCell(PrimCell):
    def __init__(self, crystalFamily = "P", theta=50., a=150, b=200, otherTranslations = None, parent=None):
        super(Mono2DCell, self).__init__(crystalType="mono", crystalFamily=crystalFamily, a=a, b=b, gamma=theta, is2D = True, otherTranslations=otherTranslations, parent=parent)

class TriangleIso2DCell(PrimCell):
    def __init__(self, crystalFamily = "P", a=150, otherTranslations = None, parent=None):
        super(TriangleIso2DCell, self).__init__(crystalType="mono", crystalFamily=crystalFamily, a=a, is2D = True, otherTranslations=otherTranslations, parent=parent)

class Ortho2DCell(PrimCell):
    def __init__(self, crystalFamily = "P", a=200, b=100, otherTranslations = None, parent=None):
        super(Ortho2DCell, self).__init__(crystalType="ortho", crystalFamily=crystalFamily, a=a, b=b, is2D = True, otherTranslations=otherTranslations, parent=parent)

class OrthoCentered2DCell(PrimCell):
    def __init__(self, crystalFamily = "I", a=200, b=100, otherTranslations = None, parent=None):
        super(OrthoCentered2DCell, self).__init__(crystalType="ortho", crystalFamily=crystalFamily, a=a, b=b, is2D = True, otherTranslations=otherTranslations, parent=parent)

class Tetra2DCell(PrimCell):
    def __init__(self, crystalFamily = "P", a=200, otherTranslations = None, parent=None):
        super(Tetra2DCell, self).__init__(crystalType="tetra", crystalFamily=crystalFamily, a=a, is2D = True, otherTranslations=otherTranslations, parent=parent)

class Hex2DCell(PrimCell):
    def __init__(self, crystalFamily = "P", a=200, otherTranslations = None, parent=None):
        super(Hex2DCell, self).__init__(crystalType="hex", crystalFamily=crystalFamily, a=a, is2D = True, otherTranslations=otherTranslations, parent=parent)

class Tri3DCell(PrimCell):
    def __init__(self, crystalFamily="P", gamma=60., alpha=70., beta=70., a=200, b=200, c=300, otherTranslations=None, parent=None):
        super(Tri3DCell, self).__init__(crystalType="tri", crystalFamily=crystalFamily, a=a, b=b, c=c, gamma=gamma, alpha=alpha, beta=beta, is2D=False, otherTranslations=otherTranslations, parent=parent)

class Mono3DCell(PrimCell):
    def __init__(self, crystalFamily="P", beta=60., a=200, b=200, c=300, otherTranslations=None, parent=None):
        super(Mono3DCell, self).__init__(crystalType="mono", crystalFamily=crystalFamily, a=a, b=b, c=c, beta=beta, is2D=False, otherTranslations=otherTranslations, parent=parent)

class Ortho3DCell(PrimCell):
    def __init__(self, crystalFamily="P", a=200, b=250, c=300, otherTranslations=None, parent=None):
        super(Ortho3DCell, self).__init__(crystalType="ortho", crystalFamily=crystalFamily, a=a, b=b, c=c, is2D=False, otherTranslations=otherTranslations, parent=parent)

class Tetra3DCell(PrimCell):
    def __init__(self, crystalFamily="P", a=200, c=300, otherTranslations=None, parent=None):
        super(Tetra3DCell, self).__init__(crystalType="ortho", crystalFamily=crystalFamily, a=a, c=c, is2D=False, otherTranslations=otherTranslations, parent=parent)

class HexRhomb3DCell(PrimCell):
    def __init__(self, crystalFamily="P", a=200, gamma=60, otherTranslations=None, parent=None):
        super(HexRhomb3DCell, self).__init__(crystalType="tri", crystalFamily=crystalFamily, a=a, gamma=gamma, is2D=False, otherTranslations=otherTranslations, parent=parent)

class HexHex3DCell(PrimCell):
    def __init__(self, crystalFamily="P", a=200, c=300, otherTranslations=None, parent=None):
        super(HexHex3DCell, self).__init__(crystalType="tri", crystalFamily=crystalFamily, a=a, c=c, is2D=False, otherTranslations=otherTranslations, parent=parent)

class Cube3DCell(PrimCell):
    def __init__(self, crystalFamily="P", a=200, otherTranslations=None, parent=None):
        super(Cube3DCell, self).__init__(crystalType="cub", crystalFamily=crystalFamily, a=a, is2D=False, otherTranslations=otherTranslations, parent=parent)

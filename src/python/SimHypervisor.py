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
This class/file represent the hypervisor, i.e.: main manager, of all properties, interactions between UI/compute and manages all computes happening behind the scene.

"""
from copy import deepcopy
from math import cos, sin, radians, degrees, sqrt, ceil

from .DipSim import Dipole, DipModel, LatticeModel
from .BravaisCells import PrimCell, Mono2DCell, TriangleIso2DCell, Ortho2DCell, OrthoCentered2DCell, Tetra2DCell, Hex2DCell, Tri3DCell, Mono3DCell, Ortho3DCell, Tetra3DCell, HexRhomb3DCell, HexHex3DCell, Cube3DCell
from .DipSimComputor import WorkerMinEnergy
from .DipSimUtilities import *
from .MonteCarlo import MonteCarlo, MonteCarloThreadWorker

from PySide2.QtCore import QObject, QSettings, Signal, Slot, Property, QSaveFile, QIODevice, QByteArray, QUrl, QDir, QDate, Qt, QFile
from PySide2.QtGui import QVector3D

class SimHypervisor(QObject):
    onLatticeGenerated = Signal()

    def __init__(self, initialDipoles=None, parent=None):
        super(SimHypervisor, self).__init__(parent)
        self.settings = QSettings()

        self._viewModeList = ["initial dipoles", "minEn dipoles", "minEn M.C. dipoles"]
        self._viewModeSelected = self._viewModeList[0]
        self._distCoef = self.settings.value("globalParams/simulation/distCoef", -9.0, float) # distance coef ex -9 indicates 10**-9 m or nm scale

        # random generation
        self._nbDipolesRdm = self.settings.value("genParams/random/nbDipoles", 500, int)
        self._randomGenModeList = ["round", "square"]
        self._randomGenModeSelected = self.settings.value("genParams/random/randomGenModeSelected", "round", str)

        # bravais cells type
        self.crystal3DTypes = ["tri", "mono", "ortho", "tetra", "hex_hex", "hex_rhomb", "cub", "custom"]
        """ tri="triclinic", mono="monoclinic", ortho="orthohombric", tetra="tetragonal", hex_rhomb="hexagonal_rhombohedral", hex_hex="hexagonal_hexagonal", cub="cubic" """
        self.crystal3DFamilies = ["P", "A", "B", "C", "F", "I"]
        self.crystal2DTypes = ["mono", "ortho", "tetra", "hex", "custom"]
        self.crystal2DFamilies = ["P", "A", "B", "I"]

        self._generateMode = self.settings.value("genParams/genMode", "Lattice", str)
        self._genSize = self.settings.value("genParams/genSize", 400, float)
        self._is2D = self.settings.value("genParams/primCell/is2D", True, bool)
        self._crystal2DType = self.settings.value("genParams/primCell/crystal2DType", "mono", str)
        self._crystal3DType = self.settings.value("genParams/primCell/crystal3DType", "cub", str)
        self._crystal2DFamily = self.settings.value("genParams/primCell/crystal2DFamily", "P", str)
        self._crystal3DFamily = self.settings.value("genParams/primCell/crystal3DFamily", "P", str)

        # import generation
        self._importFileURLsStr = []  #self.settings.value("genParams/import/importFileURLsStr", [])

        # bravais cells parameters
        self.onLatticeGenerated.connect(lambda : self.setViewModeSelected(self._viewModeList[0]))
        self._resetPrimCellParamsOnChange = self.settings.value("genParams/primCell/resetPrimCellParamsOnChange", False, bool)
        self._primCellA = self.settings.value("genParams/primCell/primCellA", -1, float)
        self._primCellB = self.settings.value("genParams/primCell/primCellB", -1, float)
        self._primCellC = self.settings.value("genParams/primCell/primCellC", -1, float)
        self._primCellGamma = self.settings.value("genParams/primCell/primCellGamma", -1, float)
        self._primCellAlpha = self.settings.value("genParams/primCell/primCellAlpha", -1, float)
        self._primCellBeta = self.settings.value("genParams/primCell/primCellBeta", -1, float)
        self.crystalTypeChanged.connect(self.primCellALockedChanged)
        self.crystalTypeChanged.connect(self.primCellBLockedChanged)
        self.crystalTypeChanged.connect(self.primCellCLockedChanged)
        self.crystalTypeChanged.connect(self.primCellGammaLockedChanged)
        self.crystalTypeChanged.connect(self.primCellAlphaLockedChanged)
        self.crystalTypeChanged.connect(self.primCellBetaLockedChanged)
        self.crystalTypeChanged.connect(lambda : self.resetBravaisParams() if self.resetPrimCellParamsOnChange else None)

        self.latices = []
        self.latticeModel = LatticeModel(self.latices)

        self.primCell = PrimCell((self._crystal2DType if self._is2D else self._crystal3DType), crystalFamily = (self._crystal2DFamily if self._is2D else self._crystal3DFamily) , is2D=self._is2D, a=300, b=300, c=300)
        initialDipoles = [] if initialDipoles is None else initialDipoles
        self.dipModel = DipModel(initialDipoles)

        self.primCell.cellChanged.connect(self.crystalMinDistChanged)
        self.generate()

        # energy compute
        self.dipModelMinEnergy = DipModel([]) #strores last dipoles computed with min energy computed (at 0K)
        self._lastMinEnergy = None
        self._lock2DMinEnergy = self.settings.value("genParams/minEnergy/lock2D", False, bool)
        self.energyCompute = WorkerMinEnergy(self)
        self.energyCompute.started.connect(self.minEnergyRunningChanged)
        self.energyCompute.finished.connect(self.minEnergyRunningChanged)
        self.energyCompute.finished.connect(lambda : self.setViewModeSelected(self._viewModeList[1]))
        self.energyCompute.resultEnergy.connect(self.setMinEnergy)
        self.energyCompute.resultDips.connect(lambda dips : self.dipModelMinEnergy.replaceAllDipoles(dips))

        # energy compute with Monte Carlo
        self.dipModelMinEnergyMC = DipModel([])
        self.threadPoolMC = [MonteCarloThreadWorker(self)]#*QtCore.QThread.idealThreadCount()
        self._lastMinEnergyMC = None
        self._lock2DMinEnergyMC = self.settings.value("genParams/minEnergyMC/lock2D", False, bool)
        self._nbIterationsMC = self.settings.value("genParams/minEnergyMC/nbIterationsMC", 10000, int)
        self._temperatureMC = self.settings.value("genParams/minEnergyMC/temperatureMC", 4, float)

        self.energyComputeMC = MonteCarlo(self)
        self.energyComputeMC.started.connect(self.minEnergyMCRunningChanged)
        self.energyComputeMC.finished.connect(self.minEnergyMCRunningChanged)
        self.energyComputeMC.finished.connect(lambda : self.setViewModeSelected(self._viewModeList[2]))
        self.energyComputeMC.resultEnergy.connect(self.setMinEnergyMC)
        self.energyComputeMC.resultDips.connect(lambda dips : self.dipModelMinEnergyMC.replaceAllDipoles(dips))

    ################################################
    ################## PROPERTIES ##################
    ################################################

    ############ VIEW 3D ############

    """
    Qt Property: returns all view modes (displayed dipoles) availables.
    """
    def getViewModeList(self):
        return list(self._viewModeList)
    viewModeListChanged = Signal()
    viewModeList = Property('QVariantList', getViewModeList, notify=viewModeListChanged)

    """
    Qt Property: determines which dipoles list is currently viewed and loaded in qml view3D.
    """
    def getViewModeSelected(self):
        return self._viewModeSelected
    def setViewModeSelected(self, viewModeSelected):
        if viewModeSelected != self._viewModeSelected:
            self._viewModeSelected = viewModeSelected
            self.viewModeSelectedChanged.emit()
    viewModeSelectedChanged = Signal()
    viewModeSelected = Property(str, getViewModeSelected, setViewModeSelected, notify=viewModeSelectedChanged)

    """
    Qt Property: determines the generation mode (Lattice / random / import).
    """
    def getGenerateMode(self):
        return self._generateMode
    def setGenerateMode(self, generateMode):
        if generateMode != self._generateMode:
            self._generateMode = generateMode
            self.settings.setValue("genParams/genMode", self._generateMode)
            self.generateModeChanged.emit()
    generateModeChanged = Signal()
    generateMode = Property(str, getGenerateMode, setGenerateMode, notify=generateModeChanged)

    """
    Qt Property: determines the generation size for modes using it (Lattice / random). In current implementation
    it will serves as radius for round generation (lattice / random) or edge in square generation.
    """
    def getGenSize(self):
        return self._genSize
    def setGenSize(self, genSize):
        if genSize != self._genSize:
            self._genSize = genSize
            self.settings.setValue("genParams/genSize", self._genSize)
            self.genSizeChanged.emit()
    genSizeChanged = Signal()
    genSize = Property(float, getGenSize, setGenSize, notify=genSizeChanged)

    ############ RANDOM GENERATION ############

    """
    Qt Property: number of random dipoles to generate.
    """
    def getNbDipolesRdm(self):
        return self._nbDipolesRdm
    def setNbDipolesRdm(self, nbDipolesRdm):
        if nbDipolesRdm != self._nbDipolesRdm:
            self._nbDipolesRdm = nbDipolesRdm
            self.settings.setValue("genParams/random/nbDipoles", self._nbDipolesRdm)
            self.nbDipolesRdmChanged.emit()
    nbDipolesRdmChanged = Signal()
    nbDipolesRdm = Property(int, getNbDipolesRdm, setNbDipolesRdm, notify=nbDipolesRdmChanged)

    """
    Qt Property: list of random generation modes available.
    """
    def getRandomGenModeList(self):
        return list(self._randomGenModeList)
    randomGenModeListChanged = Signal()
    randomGenModeList = Property('QVariantList', getRandomGenModeList, notify=randomGenModeListChanged)

    """
    Qt Property: random generation mode currently selected (between sphere and square).
    """
    def getRandomGenModeSelected(self):
        return self._randomGenModeSelected
    def setRandomGenModeSelected(self, randomGenModeSelected):
        if randomGenModeSelected != self._randomGenModeSelected:
            self._randomGenModeSelected = randomGenModeSelected
            self.settings.setValue("genParams/random/randomGenModeSelected", self._randomGenModeSelected)
            self.randomGenModeSelectedChanged.emit()
    randomGenModeSelectedChanged = Signal()
    randomGenModeSelected = Property(str, getRandomGenModeSelected, setRandomGenModeSelected, notify=randomGenModeSelectedChanged)

    ############ BRAVAIS LATTICE GENERATION ############

    """
    Qt Property: determine if lattice should be generated on a plane (2D).
    """
    def getIs2D(self):
        return self._is2D
    def setIs2D(self, is2D):
        if is2D != self._is2D:
            self._is2D = is2D
            self.settings.setValue("genParams/primCell/is2D", self._is2D)
            self.is2DChanged.emit()
    is2DChanged = Signal()
    is2D = Property(bool, getIs2D, setIs2D, notify=is2DChanged)

    """
    Qt Property: return current crystal type.
    """
    def getCrystalType(self):
        return self._crystal2DType if self._is2D else self._crystal3DType
    def setCrystalType(self, crystalType):
        if (crystalType != self._crystal2DType) and self._is2D:
            self._crystal2DType = crystalType
            self.settings.setValue("genParams/primCell/crystal2DType", self._crystal2DType)
            self.crystalTypeChanged.emit()
        elif crystalType != self._crystal3DType:
            self._crystal3DType = crystalType
            self.settings.setValue("genParams/primCell/crystal3DType", self._crystal3DType)
            self.crystalTypeChanged.emit()
    crystalTypeChanged = Signal()
    crystalType = Property(str, getCrystalType, setCrystalType, notify=crystalTypeChanged)
    
    """
    Qt Property: return current list of crystal types possible. Is changed when switching 2D<==>3D modes.
    """
    def getCrystalTypes(self):
        return self.crystal2DTypes if self._is2D else self.crystal3DTypes
    crystalTypes = Property('QVariantList', getCrystalTypes, notify=is2DChanged)

    """
    Qt Property: returns minimal distance in last generated primitive cell. Used in sizing arrows and spheres
    """
    def getCrystalMinDist(self):
        return self.primCell.minDist if self._generateMode == "Lattice" else 125
    crystalMinDistChanged = Signal()
    crystalMinDist = Property(float, getCrystalMinDist, notify=crystalMinDistChanged)

    """
    Qt Property: return current crystal family.
    """
    def getCrystalFamily(self):
        return self._crystal2DFamily if self._is2D else self._crystal3DFamily
    def setCrystalFamily(self, crystalFamily):
        if (crystalFamily != self._crystal2DFamily) and self._is2D:
            self._crystal2DFamily = crystalFamily
            self.settings.setValue("genParams/primCell/crystal2DFamily", self._crystal2DFamily)
            self.crystalFamilyChanged.emit()
        elif crystalFamily != self._crystal3DFamily:
            self._crystal3DFamily = crystalFamily
            self.settings.setValue("genParams/primCell/crystal3DFamily", self._crystal3DFamily)
            self.crystalFamilyChanged.emit()
    crystalFamilyChanged = Signal()
    crystalFamily = Property(str, getCrystalFamily, setCrystalFamily, notify=crystalFamilyChanged)

    """
    Qt Property: return current list of crystal famillies possible. Is changed when switching 2D<==>3D modes.
    """
    def getCrystalFamilies(self):
        return list(self.crystal2DFamilies if self._is2D else self.crystal3DFamilies)
    crystalFamilies = Property('QVariantList', getCrystalFamilies, notify=is2DChanged)

    ############ BRAVAIS LATTICE PARAMETERS ############

    """
    Reset bravais cells "buffer" params to -1 and thus next cell will be with default params on next generate() call.
    """
    @Slot()
    def resetBravaisParams(self):
        self.primCellA = -1
        self.primCellB = -1
        self.primCellC = -1
        self.primCellGamma = -1
        self.primCellAlpha = -1
        self.primCellBeta = -1
    
    """
    Qt Property: determines if params should be set to -1 and thus reset on next generate.
    """
    def getResetPrimCellParamsOnChange(self):
        return self._resetPrimCellParamsOnChange
    def setResetPrimCellParamsOnChange(self, resetPrimCellParamsOnChange):
        if resetPrimCellParamsOnChange != self._resetPrimCellParamsOnChange:
            self._resetPrimCellParamsOnChange = resetPrimCellParamsOnChange
            self.settings.setValue("genParams/primCell/resetPrimCellParamsOnChange", self._resetPrimCellParamsOnChange)
            self.resetPrimCellParamsOnChangeChanged.emit()
    resetPrimCellParamsOnChangeChanged = Signal()
    resetPrimCellParamsOnChange = Property(bool, getResetPrimCellParamsOnChange, setResetPrimCellParamsOnChange, notify=resetPrimCellParamsOnChangeChanged)

    """
    Qt Property: buffer for self.primCell.a to set/store lattice param a before generate is called.
    """
    def getPrimCellA(self):
        return self._primCellA
    def setPrimCellA(self, primCellA):
        if primCellA != self._primCellA:
            self._primCellA = primCellA
            self.settings.setValue("genParams/primCell/primCellA", self._primCellA)
            self.primCellAChanged.emit()
    primCellAChanged = Signal()
    primCellA = Property(float, getPrimCellA, setPrimCellA, notify=primCellAChanged)

    """
    Qt Property: buffer for self.primCell.b to set/store lattice param b before generate is called.
    """
    def getPrimCellB(self):
        return self._primCellB
    def setPrimCellB(self, primCellB):
        if primCellB != self._primCellB:
            self._primCellB = primCellB
            self.settings.setValue("genParams/primCell/primCellB", self._primCellB)
            self.primCellBChanged.emit()
    primCellBChanged = Signal()
    primCellB = Property(float, getPrimCellB, setPrimCellB, notify=primCellBChanged)

    """
    Qt Property: buffer for self.primCell.c to set/store lattice param c before generate is called.
    """
    def getPrimCellC(self):
        return self._primCellC
    def setPrimCellC(self, primCellC):
        if primCellC != self._primCellC:
            self._primCellC = primCellC
            self.settings.setValue("genParams/primCell/primCellC", self._primCellC)
            self.primCellCChanged.emit()
    primCellCChanged = Signal()
    primCellC = Property(float, getPrimCellC, setPrimCellC, notify=primCellCChanged)

    """
    Qt Property: buffer for self.primCell.gamma to set/store lattice param gamma before generate is called.
    """
    def getPrimCellGamma(self):
        return self._primCellGamma
    def setPrimCellGamma(self, primCellGamma):
        if primCellGamma != self._primCellGamma:
            self._primCellGamma = primCellGamma
            self.settings.setValue("genParams/primCell/primCellGamma", self._primCellGamma)
            self.primCellGammaChanged.emit()
    primCellGammaChanged = Signal()
    primCellGamma = Property(float, getPrimCellGamma, setPrimCellGamma, notify=primCellGammaChanged)

    """
    Qt Property: buffer for self.primCell.alpha to set/store lattice param alpha before generate is called.
    """
    def getPrimCellAlpha(self):
        return self._primCellAlpha
    def setPrimCellAlpha(self, primCellAlpha):
        if primCellAlpha != self._primCellAlpha:
            self._primCellAlpha = primCellAlpha
            self.settings.setValue("genParams/primCell/primCellAlpha", self._primCellAlpha)
            self.primCellAlphaChanged.emit()
    primCellAlphaChanged = Signal()
    primCellAlpha = Property(float, getPrimCellAlpha, setPrimCellAlpha, notify=primCellAlphaChanged)

    """
    Qt Property: buffer for self.primCell.beta to set/store lattice param beta before generate is called.
    """
    def getPrimCellBeta(self):
        return self._primCellBeta
    def setPrimCellBeta(self, primCellBeta):
        if primCellBeta != self._primCellBeta:
            self._primCellBeta = primCellBeta
            self.settings.setValue("genParams/primCell/primCellBeta", self._primCellBeta)
            self.primCellBetaChanged.emit()
    primCellBetaChanged = Signal()
    primCellBeta = Property(float, getPrimCellBeta, setPrimCellBeta, notify=primCellBetaChanged)

    """
    Qt Properties: The next properties determine if respective param isn't editable with current cell type
    and thus prevent editing since there is already a link with another one or an imposed one.
    """
    def getPrimCellALocked(self):
        return self.primCell.isPrimCellALocked(self.is2D, self.crystalType)
    primCellALockedChanged = Signal()
    primCellALocked = Property(bool, getPrimCellALocked, notify=primCellALockedChanged)

    def getPrimCellBLocked(self):
        return self.primCell.isPrimCellBLocked(self.is2D, self.crystalType)
    primCellBLockedChanged = Signal()
    primCellBLocked = Property(bool, getPrimCellBLocked, notify=primCellBLockedChanged)

    def getPrimCellCLocked(self):
        return self.primCell.isPrimCellCLocked(self.is2D, self.crystalType)
    primCellCLockedChanged = Signal()
    primCellCLocked = Property(bool, getPrimCellCLocked, notify=primCellCLockedChanged)

    def getPrimCellGammaLocked(self):
        return self.primCell.isPrimCellGammaLocked(self.is2D, self.crystalType)
    primCellGammaLockedChanged = Signal()
    primCellGammaLocked = Property(bool, getPrimCellGammaLocked, notify=primCellGammaLockedChanged)

    def getPrimCellAlphaLocked(self):
        return self.primCell.isPrimCellAlphaLocked(self.is2D, self.crystalType)
    primCellAlphaLockedChanged = Signal()
    primCellAlphaLocked = Property(bool, getPrimCellAlphaLocked, notify=primCellAlphaLockedChanged)

    def getPrimCellBetaLocked(self):
        return self.primCell.isPrimCellBetaLocked(self.is2D, self.crystalType)
    primCellBetaLockedChanged = Signal()
    primCellBetaLocked = Property(bool, getPrimCellBetaLocked, notify=primCellBetaLockedChanged)

    ############ ENERGY COMPUTE ############

    """
    Starts compute of min energy by energyCompute with standard magnetic dipole–dipole interaction formula
    by passing a copy of current initial dipoles.
    """
    @Slot()
    def computeMinEnergy(self):
        if(not self.energyCompute.isRunning()):
            self.viewModeSelected = self.viewModeList[0]
            self.dipModelMinEnergy.reset()
            self.energyCompute.compute(deepcopy(self.dipModel.dipoles), self._distCoef, self.lock2DMinEnergy)
            self.energyCompute.start()

    """
    To implement.
    Cancels minEnergy compute
    """
    @Slot()
    def cancelMinEnergyCompute(self):
        #self.energyCompute.terminate() # crash on kubuntu 20.04 with pyside 5.15 
        pass
    
    """
    Qt Property : represent if moments are locked in plane on compute of minimum energy.
    """
    def getLock2DMinEnergy(self):
        return self._lock2DMinEnergy
    def setLock2DMinEnergy(self, lock2DMinEnergy):
        if lock2DMinEnergy != self._lock2DMinEnergy:
            self._lock2DMinEnergy = lock2DMinEnergy
            self.settings.setValue("genParams/minEnergy/lock2D", self._lock2DMinEnergy)
            self.lock2DMinEnergyChanged.emit()
    lock2DMinEnergyChanged = Signal()
    lock2DMinEnergy = Property(bool, getLock2DMinEnergy, setLock2DMinEnergy, notify=lock2DMinEnergyChanged)
    
    """
    Qt Property: return if min energy MC beeing computed at the time.
    """
    def getMinEnergyRunning(self):
        return self.energyCompute.isRunning()
    minEnergyRunningChanged = Signal()
    minEnergyRunning = Property(bool, getMinEnergyRunning, notify=minEnergyRunningChanged)

    """
    Qt Property: last computed minimum energy computed with standard magnetic dipole–dipole interaction formula.
    """
    def getMinEnergy(self):
        return self._lastMinEnergy
    @Slot()
    def setMinEnergy(self, minEnergy):
        if minEnergy != self._lastMinEnergy:
            self._lastMinEnergy = minEnergy
            self.minEnergyChanged.emit()
    minEnergyChanged = Signal()
    minEnergy = Property(float, getMinEnergy, setMinEnergy, notify=minEnergyChanged)

    ############ ENERGY COMPUTE MONTE CARLO ############

    """
    Starts compute of min energy by energyComputeMC with Monte Carlo technique by passing a copy of current initial dipoles.
    """
    @Slot()
    def computeMinEnergyMC(self):
        if(not self.energyComputeMC.isRunning()):
            self.viewModeSelected = self.viewModeList[0]
            self.dipModelMinEnergyMC.reset()
            self.energyComputeMC.compute(deepcopy(self.dipModel.dipoles), self.nbIterationsMC, self.temperatureMC, self._distCoef, self.lock2DMinEnergyMC)
            self.energyComputeMC.start()

    """
    To implement. 
    Cancels compute of min energy by energyComputeMC.
    """
    @Slot()
    def cancelMinEnergyComputeMC(self):
        #self.energyComputeMC.terminate()
        pass
    
    """
    Qt Property : represent if moments are locked in plane on compute of minimum energy with Monte Carlo.
    """
    def getLock2DMinEnergyMC(self):
        return self._lock2DMinEnergyMC
    def setLock2DMinEnergyMC(self, lock2DMinEnergyMC):
        if lock2DMinEnergyMC != self._lock2DMinEnergyMC:
            self._lock2DMinEnergyMC = lock2DMinEnergyMC
            self.settings.setValue("genParams/minEnergyMC/lock2D", self._lock2DMinEnergyMC)
            self.lock2DMinEnergyMCChanged.emit()
    lock2DMinEnergyMCChanged = Signal()
    lock2DMinEnergyMC = Property(bool, getLock2DMinEnergyMC, setLock2DMinEnergyMC, notify=lock2DMinEnergyMCChanged)
    
    """
    Qt Property : return if min energy MC beeing computed at the time.
    """
    def getMinEnergyMCRunning(self):
        return self.energyComputeMC.isRunning()
    minEnergyMCRunningChanged = Signal()
    minEnergyMCRunning = Property(bool, getMinEnergyMCRunning, notify=minEnergyMCRunningChanged)

    """
    Qt Property: last computed minimum energy computed with Monte Carlo approach.
    """
    def getMinEnergyMC(self):
        return self._lastMinEnergyMC
    def setMinEnergyMC(self, minEnergyMC):
        if minEnergyMC != self._lastMinEnergyMC:
            self._lastMinEnergyMC = minEnergyMC
            self.minEnergyMCChanged.emit()
    minEnergyMCChanged = Signal()
    minEnergyMC = Property(float, getMinEnergyMC, setMinEnergyMC, notify=minEnergyMCChanged)

    """
    Qt Property: number of iteration to do with Monte Carlo approach.
    """
    def getNbIterationsMC(self):
        return self._nbIterationsMC
    def setNbIterationsMC(self, nbIterationsMC):
        if nbIterationsMC != self._nbIterationsMC:
            self._nbIterationsMC = nbIterationsMC
            self.settings.setValue("genParams/minEnergyMC/nbIterationsMC", self._nbIterationsMC)
            self.nbIterationsMCChanged.emit()
    nbIterationsMCChanged = Signal()
    nbIterationsMC = Property(int, getNbIterationsMC, setNbIterationsMC, notify=nbIterationsMCChanged)

    """
    Qt Property: temperature to compute with in Monte Carlo approach. Determines the probability of a non minimizing
    state beeing choosen in a Monte Carlo iteration.
    """
    def getTemperatureMC(self):
        return self._temperatureMC
    def setTemperatureMC(self, temperatureMC):
        if temperatureMC != self._temperatureMC:
            self._temperatureMC = temperatureMC
            self.settings.setValue("genParams/minEnergyMC/temperatureMC", self._temperatureMC)
            self.temperatureMCChanged.emit()
    temperatureMCChanged = Signal()
    temperatureMC = Property(float, getTemperatureMC, setTemperatureMC, notify=temperatureMCChanged)

    ############ IMPORT/EXPORT ############

    """
    Pre select dipoles selected for export by setting a boolean at index of "boolListToExport". 
    Index correspond to index of self.viewModeList.
    fileURL : directory to export dipoles to.
    addDateToExport : specify if date and time should be added to export file name.
    """
    @Slot(str, 'QVariantList', bool)
    def export(self, directoryURL, boolListToExport, addDateToExport):
        if boolListToExport[0]: # exports initial dipoles
            self.exportDipsToURL(self.dipModel.getDipolesCopy(), directoryURL, self.viewModeList[0], addDateToExport)
        if boolListToExport[1]: # exports minEn dipoles
            self.exportDipsToURL(self.dipModelMinEnergy.getDipolesCopy(), directoryURL, self.viewModeList[1], addDateToExport)
        if boolListToExport[2]: # exports minEn M.C. dipoles
            self.exportDipsToURL(self.dipModelMinEnergyMC.getDipolesCopy(), directoryURL, self.viewModeList[2], addDateToExport)
    
    """
    Export dipoles in .csv file.
    Columns order is : x,y,z, phi, theta, moment.
    dipoles : dipoles to export
    directoryURL : directory to export dipoles to.
    fileName : file name to save dipoles to.
    addDateToExport : specify if date and time should be added to export file name.
    """
    def exportDipsToURL(self, dipoles, directoryURL, fileName, addDateToExport = True):
        dateStr = ("-" + QDate.currentDate().toString(Qt.ISODate)) if addDateToExport else ""
        filename = QUrl(directoryURL).toLocalFile() + (QDir.separator() + fileName + dateStr + ".csv").replace(" ", "_")
        file = QSaveFile(filename)
        file.open(QIODevice.WriteOnly)
        file.write(QByteArray(bytearray("x,y,z,phi (°),theta (°),moment (mu_B)\n", 'utf-8')))
        for dip in dipoles:
            angles = anglesQuaternionToSph(dip.quaternion)
            line = str(dip.position.x()) + "," + str(dip.position.y()) + "," + str(dip.position.z()) + "," + str(degrees(angles[0])) + "," + str(degrees(angles[1])) + "," + str(dip.moment) + "\n"
            line = QByteArray(bytearray(line, 'utf-8'))
            file.write(line)
        file.commit()
        if(file.errorString() == "Unknown error"):
            return True
        else:
            return False

    """
    Qt Property: all imports URLs to import dipoles from.
    """
    def getImportFileURLsStr(self):
        print("reading: " + str(self._importFileURLsStr))
        return self._importFileURLsStr
    def setImportFileURLsStr(self, importFileURLsStr):
        if importFileURLsStr != self._importFileURLsStr:
            print("writting")
            self._importFileURLsStr = importFileURLsStr
            # self.settings.setValue("genParams/import/importFileURLsStr", [self._importFileURLsStr])
            self.importFileURLsStrChanged.emit()
    importFileURLsStrChanged = Signal()
    importFileURLsStr = Property('QStringList', getImportFileURLsStr, setImportFileURLsStr, notify=importFileURLsStrChanged)

    """
    Import dipoles from .csv file and places them in intial dipoles.
    Columns order is : x,y,z, phi, theta, moment.
    fileURLsStr: string of url of file to import.
    """
    def importDips(self, fileURLsStr):
        self.dipModel.reset()
        for filePath in fileURLsStr:
            file = QFile(QUrl(filePath).toLocalFile())
            if (not file.open(QIODevice.ReadOnly)):
                print("impossible to open file \" " + filePath +" \", error is:" + file.errorString())
                continue
            while not file.atEnd():
                line = str(file.readLine(), encoding='utf-8')
                lineCells = line.split(',')
                try:
                    float(lineCells[0])
                except ValueError:
                    continue
                dip = Dipole.initByComposent(xPos=float(lineCells[0]), yPos=float(lineCells[1]), zPos=float(lineCells[2]), quaternion=anglesSphToQuaternion(float(lineCells[3]), float(lineCells[4])), parent=self.dipModel)
                self.dipModel.append(dip)


    ############ GLOBAL PARAMS ############

    """
    Qt Property: coeficient for all units in DipSim. exemple -9 will be for nanometers with 10^-9 applied later in compute functions
    """
    def getDistCoef(self):
        return self._distCoef
    def setDistCoef(self, distCoef):
        if distCoef != self._distCoef:
            self._distCoef = distCoef
            self.settings.setValue("globalParams/simulation/distCoef", self._distCoef)
            self.distCoefChanged.emit()
    distCoefChanged = Signal()
    distCoef = Property(float, getDistCoef, setDistCoef, notify=distCoefChanged)


    ################################################
    ################## FUNCTIONS ###################
    ################################################

    """
    generates dipoles for intial dipoles list with respect to _generateMode selected.
    """
    @Slot()
    def generate(self):
        self.primCell.is2D = self._is2D
        if(self._generateMode == "Lattice"):
            self.primCell.a = None if self.primCellA <= 0 else self.primCellA
            self.primCell.b = None if self.primCellB <= 0 else self.primCellB
            self.primCell.c = None if self.primCellC <= 0 else self.primCellC
            self.primCell.gamma = None if self.primCellGamma <= 0 or self.primCellGamma is None else self.primCellGamma
            self.primCell.alpha = None if self.primCellAlpha <= 0 or self.primCellAlpha is None else self.primCellAlpha
            self.primCell.beta = None if self.primCellBeta <= 0 or self.primCellBeta is None else self.primCellBeta
            self.primCell.crystalFamily = self.crystalFamily
            self.primCell.crystalType = self.crystalType
            self.primCell.generatePrimCell(a=self.primCell.a, b=self.primCell.b, c=self.primCell.c, gamma=self.primCell.gamma, alpha=self.primCell.alpha, beta=self.primCell.beta)
            self.primCellA = self.primCell.a
            self.primCellB = self.primCell.b
            self.primCellC = self.primCell.c
            self.primCellGamma = self.primCell.gamma
            self.primCellAlpha = self.primCell.alpha
            self.primCellBeta = self.primCell.beta

            self.dipModel.replaceAllDipoles(self.generateLatticeDipoles(self._genSize))
        elif self._generateMode == "Random":
            self.dipModel.replaceAllDipoles(self.getRandomDipoles(initNumber=self.nbDipolesRdm, genSize=self._genSize, is2D=self.primCell.is2D, genType=self.randomGenModeSelected))
        elif self._generateMode == "Import":
            self.importDips(self.importFileURLsStr)
        self.onLatticeGenerated.emit()

    """
    generate list of random dipoles.
    initNumber: number of dipoles to generate.
    genSize: size of generation
    is2D: generate on plane (2D) or in 3D space
    positionVector: if specified will set all dipoles to have this exact position
    quaternion: if specified will set all dipoles to have this exact quaternion
    parent: qObject's parent
    """
    def getRandomDipoles(self, initNumber=50, genSize=500, is2D=True, genType="round", positionVector=None, quaternion=None, parent=None):
        return [Dipole.rndDipoleGenerator(genSize=genSize, is2D=is2D, genType=genType, positionVector=positionVector, quaternion=quaternion) for i in range(initNumber)]

    """
    Add all dipoles of ONE primitive cell to dipoles with ia ib ic the translations indices
    on each respective translation axis of the point(0,0,0) of the prim cell to add.
    (i) Intermediate function for "generateLatticeDipoles()".
    """
    def addPointFromTranslations(self, dipoles, pCell, ia, ib, ic, maxDist, quaternion=None):
        aBasePointVector = QVector3D(ia*pCell.a, 0, 0)
        bxProjCoef = cos(radians(pCell.gamma))
        byProjCoef = sin(radians(pCell.gamma))
        bBasePointVector = QVector3D(ib*pCell.b*bxProjCoef, ib*pCell.b*byProjCoef, 0)
        cxProjCoef = 0.
        cyProjCoef = 0.
        if(not pCell.is2D):
            cxProjCoef = cos(radians(pCell.beta))
            cyProjCoef = (cos(radians(pCell.alpha)) - cos(radians(pCell.beta))*cos(radians(pCell.gamma)))/sin(radians(pCell.gamma))
            czBaseComp = ic*abs(pCell.c)*sqrt(1 - (cxProjCoef)**2 - (cyProjCoef)**2)
            cBasePointVector = QVector3D(0, 0, 0) if pCell.is2D else QVector3D(ic*pCell.c*cxProjCoef, ic*pCell.c*cyProjCoef, czBaseComp) #QVector3D(ic*pCell.c*cos(pCell.gamma)*cos(pCell.alpha), ib*pCell.b*sin(pCell.gamma), 0)
            basePoint = aBasePointVector + bBasePointVector + cBasePointVector
        else:
            basePoint = aBasePointVector + bBasePointVector
        
        if(basePoint.length() > maxDist): # if outside radius of simulation
            pass
        for points in pCell.translations:
            aPointVector = QVector3D(pCell.a*points.x(), 0, 0)
            bPointVector = QVector3D(pCell.b*points.y()*bxProjCoef, pCell.b*byProjCoef*points.y(), 0)
            if(not pCell.is2D):
                cPointVector = QVector3D(0, 0, 0) if pCell.is2D else QVector3D(cxProjCoef, cyProjCoef, sqrt(1 - (cxProjCoef)**2 - (cyProjCoef)**2))*abs(pCell.c)*points.z()
                pointVect = aPointVector + bPointVector + cPointVector
            else: 
                pointVect = aPointVector + bPointVector
            pointVect += basePoint
            if(pointVect.length() <= maxDist): # if inside radius of simulation
                if(quaternion is None):
                    dipoles.append(Dipole(pointVect, Dipole.rndQuaternionGenerator(is2D=pCell.is2D)))
                else:
                    dipoles.append(Dipole(pointVect, quaternion))

    """
    Generate dipoles with current hypervisor lattice params with maximum generation  distance specified with "maxDist".
    """
    def generateLatticeDipoles(self, maxDist=500):
        dipoles = []
        pCell = self.primCell # deepcopy(self.primCell) to implement/debug
        for i in range(len(pCell.translations)-1, -1, -1): #eliminate points on outer planes/lines to avoir doubling on generation
            if any(((pCell.translations[i].x() == 1), (pCell.translations[i].y() == 1), (pCell.translations[i].z() == 1))):
                del pCell.translations[i]
        cxProjCoef = cos(radians(pCell.beta))
        cyProjCoef =  1.0 if pCell.is2D else (cos(radians(pCell.alpha)) - cos(radians(pCell.beta))*cos(radians(pCell.gamma)))/sin(radians(pCell.gamma))
        aMaxR = int(ceil(abs(maxDist)/(sin(radians(pCell.gamma))))//pCell.a)+1
        bMaxR = int(ceil(abs(maxDist)/(sin(radians(pCell.gamma))))//pCell.b)+1
        cMaxR = 0 if pCell.is2D else int(ceil(abs(maxDist)/1)//pCell.c)+1
        for ia in range(-aMaxR, aMaxR+1):
            for ib in range(-bMaxR, bMaxR+1):
                for ic in range(-cMaxR, cMaxR+1):
                    self.addPointFromTranslations(dipoles, pCell, ia, ib, ic, maxDist)

        return dipoles

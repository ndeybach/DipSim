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
This class file represent the compute of minimizing energy with the Monte-Carlo method, using the Metropolis algorithm
There is two class:
-One wich use this algorithm in multiple thread to reduce computing time (actually not working)
-The other one using only one thread to compute in background
"""
from copy import deepcopy

import numpy as np
from scipy.constants import k as kb

from PySide2 import QtWidgets
from PySide2 import QtCore, QtGui

from .DipSimUtilities import *
from .DipSim import *
from .DipSimComputor import *

#########################################################
### Method of Monte-Carlo running on multpile threads ###
############## /!\ Actually not working /!\ #############
#########################################################
"""
dipole: list of dipoles (DipModel)
nbIteration: number of iterations (int)
temperature: temperature of the system (float)
lock2D: compute on 3D or 2D (bool)
unitCoef: power of the distance, 0 is meter, 10**-9 is nanometer (float)
"""   
class MonteCarloThreadWorker(QThread):
    resultDips = Signal(list)
    error = Signal()
    def __init__(self, parent=None):
        super(MonteCarloThreadWorker, self).__init__(parent=parent)
        self.dipoles = None
        self.nbIteration = 1
        self.temperature = 1
        self.lock2D = False
        self.unitCoef=10**-11

        self.nbIterMutex = None
        self._currentNbIterations = None

        self.id = -1
    
    def compute(self, nbIterMutex, dipoles, nbIteration, currentNbIterations, temperature, distCoef=0.0, lock2D=False, id = -1):
        self.id = id
        self.nbIterMutex = nbIterMutex
        self._currentNbIterations = currentNbIterations
        self.dipoles = dipoles
        self.nbIteration = nbIteration
        self.unitCoef=10**distCoef
        self.temperature = temperature
        self.lock2D = lock2D
        self.start()
    
    def run(self):
        try:
            resDips = self.monteCarloThread(self.dipoles, self.nbIteration, self.temperature, self.lock2D)
            self.resultDips.emit(resDips)
        except:
            self.error.emit()

    """
    Minimisation with Monte-Carlo working on multiple threads
    Return the list of dipoles with new computed directions 

    dipoles: list of dipoles 
    N:number of iteration(int) 
    T: temperature(float)
    lock2D: compute on 2D or 3D (boolean)
    """
    def monteCarloThread(self, dipoles, N, T, lock2D):
        dipCopy = deepcopy(dipoles)
        current_energy = self.computeEnergy(dipCopy)
        while True:
            moment_to_change_indice = np.random.randint(len(dipCopy))
            moment_to_change = dipCopy[moment_to_change_indice].quaternion #moment i-1
            dipCopy[moment_to_change_indice].quaternion = Dipole.rndQuaternionGenerator(is2D=lock2D) # we replace the moment i-1 by a new random one
            new_energy = self.computeEnergy(dipCopy)
            r = np.random.random()
            numerator = new_energy - current_energy  # unit: eV
            denominator = -(kb*T* 6.242 * 10**18)    # unit: eV

            if r<min(1, np.exp( numerator/denominator)): #determine to add or not energy as new minimum
                current_energy = new_energy
            else:
                dipCopy[moment_to_change_indice].quaternion = moment_to_change # we put moment_i = moment_i-1
            #verify if max number of iteration (of all threads) rechead and/or add this one
            self.nbIterMutex.lock()
            if(self._currentNbIterations > self.nbIteration):
                self.nbIterMutex.unlock()
                dipCopy[moment_to_change_indice].quaternion = moment_to_change # disregard last changes and return
                break
            else:
                self._currentNbIterations += 1
            self.nbIterMutex.unlock()
        return dipCopy

    """
    Compute the total energy (Magnetic dipole-dipole interaction) of a dipole configuration /!\ in eV /!\ 
    It take one argument:
    -dipol: list of all dipoles (DipModel)
    """
    def computeEnergy(self, dipol):
        positions = []
        moment=[]
        E=0
        a=0
        if len(dipol)>1:
            for i in dipol:
                positions.append([i.position.x()*self.unitCoef,i.position.y()*self.unitCoef,i.position.z()*self.unitCoef])
                angle = [anglesQuaternionToSph(i.quaternion)[0],anglesQuaternionToSph(i.quaternion)[1]]
                MI = i.moment * 9.27 * 10**-24
                phiI= angle[0]
                thetaI= angle[1]
                moment.append([cos(phiI)*sin(thetaI)*MI,sin(phiI)*sin(thetaI)*MI,cos(thetaI)*MI]) #create al list of all moment: [[m1_x,m1,y,m1_z],[m2_x,m2_y,m2_z]]
            
            """ Formula of energy of magnetic dipole–dipole interaction """
            for i in range(len(positions)):
                for j in range(len(positions)):
                    if j != i:
                        vectIJ= np.subtract(positions[j],positions[i])                    
                        normIJ= np.linalg.norm(vectIJ)
                        E+=(np.dot(moment[i],moment[j]))/(normIJ**3) - (3*np.dot(moment[i],vectIJ)*np.dot(moment[j],vectIJ))/(normIJ**5)
            E=(E*mu_0/(8*pi)) # E in J
            return (E * 6.242 * 10**18) # convert J to eV
        else:
            return(0)

###################################################
### Method of Monte-Carlo running on one thread ###
###################################################

"""
dipole: list of dipoles (DipModel)
nbIteration: number of iterations (int)
temperature: temperature of the system (float)
lock2D: compute on 3D or 2D (bool)
unitCoef: power of the distance, 0 is meter, 10**-9 is nanometer (float)
"""

class MonteCarlo(QThread):
    resultDips = Signal(list)
    resultEnergy = Signal(float)
    error = Signal()
    def __init__(self, parent=None):
        super(MonteCarlo, self).__init__(parent=parent)
        self.dipoles = None
        self.nbIteration = 1
        self.temperature = 1
        self.lock2D = False
        self.unitCoef=10**-11

        self._multiTreaded = False
        self.nbIterMutex = QMutex()
        self._currentNbIterations = 0
        self.threadPool = None

        self.allMinEnergies = []

    """Link between main program and qthread run fonction"""
    @Slot()
    def compute(self, dipoles, nbIteration, temperature, distCoef=0.0, lock2D=False, multiTreaded = False):
        # For the time beeing only one thread used because race condition happens. Some more debugging is necessary for a precise understanding. 
        # QtCore.QThread.idealThreadCount() is maximum nb of threads supported by your system. When 2 or more threads are used
        # only the last one execute the function. It may be a bug in qt or a bad implementation of the qthread API iin this file.

        self.threadPool = [MonteCarloThreadWorker()]*1#*QtCore.QThread.idealThreadCount()
        for thread in self.threadPool:
            thread.resultDips.connect(lambda dips : self.minEnergiesDipolesList.append(dips))
        self.dipoles = dipoles
        self.unitCoef=10**distCoef
        self.nbIteration = nbIteration
        self.temperature = temperature
        self.lock2D = lock2D
        
        self._multiTreaded = multiTreaded
        self.minEnergiesDipolesList = []
        self.start()
    
    """Starts QThread and Mont-Carlo compute of the minimum energy of multiple dipoles"""
    def run(self):
        self._currentNbIterations = 0
        if(self._multiTreaded):
            for index, thread in enumerate(self.threadPool): #start all threads compute
                thread.compute(self.nbIterMutex, deepcopy(self.dipoles), self.nbIteration, self._currentNbIterations, self.temperature, self.lock2D, id=index)
            for thread in self.threadPool: # rejoin all threads
                while thread.isRunning():
                    pass
            allMinEnergies = [self.computeEnergy(dips) for dips in self.minEnergiesDipolesList]
            indexMinEn = allMinEnergies.index(min(allMinEnergies))
            minEnDips = self.minEnergiesDipolesList[indexMinEn]
            resEn = self.computeEnergy(minEnDips)
            self.resultDips.emit(minEnDips)
            self.resultEnergy.emit(resEn)
        else:
            try:
                resDips = self.monteCarloOneThread(self.dipoles, self.nbIteration, self.temperature, self.lock2D)
                resEn = self.computeEnergy(resDips)
                self.resultDips.emit(resDips)
                self.resultEnergy.emit(resEn)
            except:
                self.error.emit()

    """
    Minimisation with Monte-Carlo working on multiple threads
    Return the list of dipoles with new computed directions 

    dipoles: list of dipoles 
    N:number of iteration(int) 
    T: temperature(float)
    lock2D: compute on 2D or 3D (boolean)
    """
    def monteCarloOneThread(self, dipoles, N, T, lock2D):
        dipCopy = deepcopy(dipoles)
        current_energy = self.computeEnergy(dipCopy)
        
        for i in range(N):
            moment_to_change_indice = np.random.randint(len(dipCopy))
            moment_to_change = dipCopy[moment_to_change_indice].quaternion #moment i-1
            dipCopy[moment_to_change_indice].quaternion = Dipole.rndQuaternionGenerator(is2D=lock2D) # we replace the moment i-1 by a new random one
            new_energy = self.computeEnergy(dipCopy)
            r = np.random.random()  #take a number between 0 and 1
            numerator = new_energy - current_energy  # unit: eV
            denominator = -(kb*T* 6.242 * 10**18)    # unit: eV
            if r<min(1, np.exp( numerator/denominator)):    #determine to add or not energy as new minimum
                current_energy = new_energy     
            else:
                dipCopy[moment_to_change_indice].quaternion = moment_to_change # we put moment_i = moment_i-1
        return dipCopy

    """
    Compute the total energy (Magnetic dipole-dipole interaction) of a dipole configuration /!\ in eV /!\ 
    It take one argument:
    -dipol: list of all dipoles (DipModel)
    """
    def computeEnergy(self, dipol):
        positions = []
        E=0
        moment=[]
        a=0
        if len(dipol)>1:
            for i in dipol:
                positions.append([i.position.x()*self.unitCoef,i.position.y()*self.unitCoef,i.position.z()*self.unitCoef])
                angle = [anglesQuaternionToSph(i.quaternion)[0],anglesQuaternionToSph(i.quaternion)[1]] 
                MI = i.moment * 9.27 * 10**-24
                phiI= angle[0]
                thetaI= angle[1]
                moment.append([cos(phiI)*sin(thetaI)*MI,sin(phiI)*sin(thetaI)*MI,cos(thetaI)*MI])   #create al list of all moment: [[m1_x,m1,y,m1_z],[m2_x,m2_y,m2_z]]

            """ Formula of energy of magnetic dipole–dipole interaction """
            for i in range(len(positions)):
                for j in range(len(positions)):
                    if j != i:
                        vectIJ= np.subtract(positions[j],positions[i])                    
                        normIJ= np.linalg.norm(vectIJ)
                        E+=(np.dot(moment[i],moment[j]))/(normIJ**3) - (3*np.dot(moment[i],vectIJ)*np.dot(moment[j],vectIJ))/(normIJ**5)
            E=(E*mu_0/(8*pi)) # E in J
            return (E * 6.242 * 10**18) # convert J to eV
        else:
            return(0)
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
This class file represent the compute of minimizing energy with a SciPy function : optimize.fmin_cg
The compute is made in a thread, in background
"""
from PySide2 import QtWidgets
from PySide2 import QtCore, QtGui
from PySide2.QtCore import *
from PySide2.QtGui import *
from PySide2.QtGui import *

from copy import deepcopy
from math import cos, sin, radians, degrees
from scipy.constants import mu_0, pi
from scipy import optimize

import numpy.matlib 
import numpy as np 

from .DipSimUtilities import *
from .DipSim import *

""" lunch the minimizing function in a thread """
class DipSimComputor(QObject):
    
    def __init__(self):
        super(DipSimComputor, self).__init__()
        self._workerThreadMinEn = WorkerMinEnergy(self)


class WorkerMinEnergy(QThread):
    resultDips = Signal(list)
    resultEnergy = Signal(float)
    error = Signal()
    def __init__(self, parent=None):
        super(WorkerMinEnergy, self).__init__(parent=parent)
        self.dipoles = None
        self.lock2D = False
        self.unitCoef=10**-9
    
    """
    dipoles: dipoles list (DipModel)
    distCoeff: power of the distance unit, 0 is meter, -9 is nanometer (float)
    lock2D: dipoles are on a 2D plan or 3D (boolean)
    """
    @Slot()
    def compute(self, dipoles, distCoef=0.0, lock2D=False):
        self.dipoles = dipoles
        self.unitCoef=10**distCoef
        self.lock2D = lock2D
        self.start()

    def run(self):
        try:
            resDips = self.getMinEnergy(self.dipoles, self.lock2D)
            resEn = self.computeEnergyDipoles(resDips)
            self.resultDips.emit(resDips)
            self.resultEnergy.emit(resEn)
        except:
            self.error.emit()

    def setDipoles(self, dipoles):
        self.dipoles = dipoles
    
    """
    Return the configuration of moments that minimize the total energy(magnetic dipole-dipole interaction) of the dipoles
    It take two argument: 
    -dipoles: the list of the dipoles (DipModel)
    -lock2D: boolean, if true the moments will be on a 2D plan (theta=0)
    """
    def getMinEnergy(self, dipoles, lock2D):
        momentIntensity= 1
        positions = []
        angle = []
        nul= []
        a=0

        #Find the minimum configuration in 3D
        if lock2D == False:
            for i in dipoles:
                angle.append([anglesQuaternionToSph(Dipole.rndQuaternionGenerator(is2D=True))[0],anglesQuaternionToSph(Dipole.rndQuaternionGenerator(is2D=True))[1]])
                positions.append([i.position.x(),i.position.y(),i.position.z()]) # [[x1,y1,z1], [x2,y2,z2]]
                nul.append([0,0])
            pos=tuple(positions)
            res1= optimize.fmin_cg(self.computeEnergy,angle,args=pos,maxiter=10000) #Minimize the computeEnergy function, variables are the orientation of the moments (in 3D) 
            #res1 is a liste of angle : [phi1, theta1, phi2, theta2]
            for i in dipoles:
                i.quaternion = anglesSphToQuaternion(degrees(res1[a]),degrees(res1[a+1]))
                a+=2
            return(dipoles)
                
        elif lock2D == True: #Find the minimum configuration in 2D
            for i in dipoles:
                angle.append(anglesQuaternionToSph(Dipole.rndQuaternionGenerator(is2D=True))[0])
                positions.append([i.position.x(),i.position.y(),i.position.z()]) # [[x1,y1,z1], [x2,y2,z2]]
                nul.append(0)
            pos=tuple(positions)
            res1= optimize.fmin_cg(self.computeEnergy2D,angle,args=pos,maxiter=10000)   #Minimize the computeEnergy function, variables are the orientation of the moments (in 2D)            
            #res1 is a list of angle: [phi1, phi2, phi3]
            for i in dipoles:
                i.quaternion = anglesSphToQuaternion(degrees(res1[a]),90) # change the quaternion to the minimized one
                a+=1
            return(dipoles)

    """
    Compute the total energy (Magnetic dip to dip)
    It take two argument:
    -angle: list of angles of each dipole : [[phi1,theta1],[phi2,theta2]]
    -args: tuple of list of the positions of each dipole: ([[x1,y1,z1],[x2,y2,z2])
    """
    def computeEnergy(self, angle,*args): 
        E=0                              
        moment=[]
        for i in range(int(len(angle)/2)):
                phiI= angle[2*i]
                thetaI= angle[2*i+1]
                moment.append([cos(phiI)*sin(thetaI),sin(phiI)*sin(thetaI),cos(thetaI)]) #create al list of all moment: [[m1_x,m1,y,m1_z],[m2_x,m2_y,m2_z]]

        """ Formula of energy of magnetic dipole–dipole interaction """
        for i in range(len(args)):
            for j in range(len(args)):
                if j != i:
                    vectIJ= np.subtract(args[j],args[i])                    
                    normIJ= np.linalg.norm(vectIJ)
                    E+=(np.dot(moment[i],moment[j]))/(normIJ**3) - (3*np.dot(moment[i],vectIJ)*np.dot(moment[j],vectIJ))/(normIJ**5)               
        return ((E*mu_0/(8*pi))*10**18)
    
    """
    Compute the total energy (Magnetic dip to dip) in J
    It take two argument:
    -angle: list of angles of each dipole (in polar coordinate) : [phi1,phi2,phi3] 
    -args: tuple of list of the positions of each dipole: ([[x1,y1,z1],[x2,y2,z2])
    """
    def computeEnergy2D(self, angle,*args): 
        E=0                                 
        moment=[]
        for i in range(len(angle)):
                phiI= angle[i]
                thetaI= pi/2
                moment.append([cos(phiI)*sin(thetaI),sin(phiI)*sin(thetaI),cos(thetaI)]) #create al list of all moment: [[m1_x,m1,y,m1_z],[m2_x,m2_y,m2_z]]

        """ Formula of energy of magnetic dipole–dipole interaction """
        for i in range(len(args)):
            for j in range(len(args)):
                if j != i:
                    vectIJ= np.subtract(args[j],args[i]) # r_IJ vector                   
                    normIJ= np.linalg.norm(vectIJ) # ||r_IJ||
                    E+=(np.dot(moment[i],moment[j]))/(normIJ**3) - (3*np.dot(moment[i],vectIJ)*np.dot(moment[j],vectIJ))/(normIJ**5)               
        E=(E*mu_0)/(8*pi)
        return (E*(10**18))


    """
    Compute the total energy (Magnetic dip to dip) of a dipole configuration in J
    It take one argument:
    -dipol: list of all dipoles (DipModel)
    """
    def computeEnergyDipoles(self, dipol):
        positions = []
        angle = []
        E=0
        moment=[]
        if len(dipol)>1: #if there is only one dipole, the energy is zero
            for i in dipol:
                angle.append([anglesQuaternionToSph(i.quaternion)[0],anglesQuaternionToSph(i.quaternion)[1]]) # [[phi1,theta1],[phi2,theta2]]
                positions.append([i.position.x()*self.unitCoef,i.position.y()*self.unitCoef,i.position.z()*self.unitCoef]) # [[x1,y1,z1], [x2,y2,z2]]
            
            for i in range(len(angle)):
                    MI = dipol[i].moment * 9.27 * 10**-24 #convert the moment intensity of the dipole in J/T (µ_b -> J/T)
                    phiI= angle[i][0]
                    thetaI= angle[i][1]
                    moment.append([cos(phiI)*sin(thetaI)*MI,sin(phiI)*sin(thetaI)*MI,cos(thetaI)*MI]) #create al list of all moment: [[m1_x,m1,y,m1_z],[m2_x,m2_y,m2_z]]

            """ Formula of energy of magnetic dipole–dipole interaction """
            for i in range(len(positions)):
                for j in range(len(positions)):
                    if j != i:
                        vectIJ= np.subtract(positions[j],positions[i])  # r_IJ vector                   
                        normIJ= np.linalg.norm(vectIJ)  # ||r_IJ||
                        E+=(np.dot(moment[i],moment[j]))/(normIJ**3) - (3*np.dot(moment[i],vectIJ)*np.dot(moment[j],vectIJ))/(normIJ**5)
            E=(E*mu_0/(8*pi))
            return (E*6.242 * 10**18) #convert E in J to eV
        else:
            return(0)

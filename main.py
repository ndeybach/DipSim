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

import sys
import os

from math import cos, sin, radians, degrees
from copy import deepcopy

from PySide2.QtGui import QGuiApplication, QQuaternion
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide2.QtCore import Qt

from src.python.DipSim import Dipole, DipModel, LatticeModel
from src.python.SimHypervisor import SimHypervisor
from src.python.DipSimUtilities import *
from src.python.DipSimComputor import WorkerMinEnergy

from PySide2.QtGui import QVector3D, QColor

import ressource

def shutdown():
    '''Delete engine and qml object before python garbage collection'''
    del globals()["engine"]

if __name__ == "__main__":
    #QGuiApplication.setAttribute(Qt.AA_EnableHighDpiScaling) #bug on linux scaling if activated
    sys.argv += ['--style', 'material']
    app = QGuiApplication(sys.argv)
    app.aboutToQuit.connect(shutdown)

    # set variables for settings
    app.setApplicationName("DipSim")
    app.setOrganizationName("IPR")
    app.setOrganizationDomain("IPR.com")

    hypervisor = SimHypervisor() # python compute hypervisor
    engine = QQmlApplicationEngine() # UI engine

    # add necesaary object linking UI and python data
    engine.rootContext().setContextProperty("hypervisor", hypervisor)
    engine.rootContext().setContextProperty("primCell", hypervisor.primCell)
    engine.rootContext().setContextProperty("dipModel", hypervisor.dipModel)
    engine.rootContext().setContextProperty("dipModelMinEnergy", hypervisor.dipModelMinEnergy)
    engine.rootContext().setContextProperty("dipModelMinEnergyMC", hypervisor.dipModelMinEnergyMC)
    
    engine.load(os.path.join(os.path.dirname(__file__), "main.qml"))
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec_())

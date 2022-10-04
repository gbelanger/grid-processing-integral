# -*- coding: utf-8 -*-
"""
Created on Thu Sep 29 14:18:28 2022

@author: Philippe Laurent, CEA
"""

import numpy as np
import sys

if len(sys.argv)==1:
     angleref = 5. #degré
     fichout  = 'points.txt'
elif len(sys.argv)==3:
    angleref = float(sys.argv[1])
    fichout  = str(sys.argv[2])
else:
    print("Il faut deux arguments, l'angle de référence et le fichier texte de destination")
    sys.exit()
    
angle1   = (2*angleref-1)*np.pi/180.
nangle   = int(np.pi/2/angle1)

angle2   = 0.85*angleref*np.pi/180.
nangle2  = int(np.pi/2/angle2)
polar    = np.arange(nangle2)*angle2
npol     = len(polar)
ecartpol = np.cos(polar)*np.arccos(1-(1 - np.cos(angle1))/np.cos(polar)/np.cos(polar))
nangaz   = []
for i in range(npol-1):
    nangaz.append(int(2*np.pi/ecartpol[i]))

naz = max(nangaz)
azimuth  = np.zeros((npol,naz))
for i in range(npol-1):
  for j in range(nangaz[i]):
    azimuth[i][j] = j*ecartpol[i]

fileout = open(fichout,"w")
for i in range(npol-1):
  for j in range(nangaz[i]):
    fileout.write("%f  %f \n"%(polar[i]*180./np.pi,azimuth[i][j]*180./np.pi))
fileout.close()

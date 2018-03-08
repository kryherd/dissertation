#!/usr/bin/env python
# -*- coding: utf8 -*-
import os, sys, re

file = open("results.txt", "r+").read()

listEff = []
listCon = []
iteration = []

p = re.compile(r"(\d)\s(\d\.\d+)\s(\d\.\d+)",re.MULTILINE)

matches = p.finditer(file)

for m in matches:
	values = m.groups()
	iteration += [values[0]]
	listEff += [values[1]]
	listCon += [values[2]]

minEff = str(min(listEff))
indexOfMinEff = str(listEff.index(min(listEff))+1)
minCon =  str(min(listCon))
indexOfMinCon = str(listCon.index(min(listCon))+1)

file = open("results.txt", "a")
file.write("\n")
file.write("Lowest Stim Value "+minEff+" in iteration "+indexOfMinEff)
file.write("\n")
file.write("Lowest Contrast Value "+minCon+" in iteration "+indexOfMinCon)
file.close()
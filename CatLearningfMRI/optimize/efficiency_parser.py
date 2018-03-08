#!/usr/bin/env python
import re #regex module
import numpy as np
import sys

#Usage: efficiency_parser.py out.txt
#Parse the output of 3dDeconvole -nodata stored in out.txt


#make a dictionary to store the results
results = {'Contrast': [], 'eff': []}
resultsGLT = {'GLT': [], 'effGLT': []}

#TODO: open the 3dDeconvolve output filename stored in sys.argv[1]
with open(sys.argv[1], 'r') as fd:
	s = fd.read()

#TODO: read all the lines in the file into a string s. 
#Make sure s is a string, not a list

#compile the regex
#use re.MULTILINE since we need to match across lines
p = re.compile(r"^Stimulus:\s+(.+)\s+.+ ([.0-9]+)", re.MULTILINE)
#p = re.compile(r"^.+:\s+(.+)\s+.+=\s+([.0-9]+)", re.MULTILINE)
#p = re.compile(r"^Stimulus|Test:.+:\s+(.+)\s+.+=\s+([.0-9]+)", re.MULTILINE)
pGLT = re.compile(r"^General Linear Test:\s+(.+)\s+.+ ([.0-9]+)", re.MULTILINE)

#find all of the matches in s and return an interator in matches

matches = p.finditer(s)
matchesGLT = pGLT.finditer(s)

#TODO: iterate through matches and copy the values to the results dicttionary
#for each match, m, you get from the iterator, m.groups() is a tuple
#try m=p.search() to see what the first one looks like
for m in matches:
	values = m.groups()
	results['Contrast'] = results['Contrast'] + [values[0]]
	results['eff'] = results['eff'] + [float(values[1])]
for m in matchesGLT:
	values = m.groups()
	resultsGLT['GLT'] = resultsGLT['GLT'] + [values[0]]
	resultsGLT['effGLT'] = resultsGLT['effGLT'] + [float(values[1])]



#TODO: calculate the summed efficiency of all the stimulus functions and contrasts (i.e. sum the 'eff' key in the dictionary)
#try np.sum()
eff = np.sum(results['eff'])
effGLT = np.sum(resultsGLT['effGLT'])


#TODO print the summed efficiency
print eff,
print effGLT
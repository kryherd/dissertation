#!/usr/bin/env python2.7
import re
import os
import pandas as pd
import numpy as np

directory = "/Users/Kayleigh/dissertation/DataAnalysis/Exp1_Sloutsky/Data"

os.chdir(directory)

stack = np.hstack(('Block', 'StimType', 'Stimulus', 'KEY', 'RESP', 'Accuracy', 'RT', 'Subject', 'Order'))

for filename in os.listdir(directory):
    if filename.endswith(".tsv"): 
    	r = re.compile("[0-9]{4}")
    	m = r.search(filename)
        num = m.group(0)
        r2 = re.compile("order([0-9]{1})_")
        m2 = r2.search(filename)
        ord = m2.group(1)
        data = pd.read_table(filename)
        data['Subject'] = num
        data['Order'] = ord
        stack = np.vstack((stack, data))

np.savetxt("fulldata.tsv", stack, fmt='%s', delimiter='\t', newline='\n', header='', footer='', comments='# ')
        
		
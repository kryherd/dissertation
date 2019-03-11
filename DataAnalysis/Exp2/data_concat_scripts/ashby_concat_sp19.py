#!/usr/bin/env python2

import glob
import pandas as pd
import numpy as np
import os
import datetime
import re

# get current directory
data_dir = os.getcwd()

# change to data directory
## change this if data location changes
os.chdir('/Volumes/EEG/CategoryLearning/Data/Exp2/Ashby')

# make a list of all data filenames
filenames = glob.glob('*.tsv')

# create regular expressions to find...
## subject number
subj = re.compile("(\d{4})")

# this function uses a regular expression on a list
# it puts the last match into a new list
# if there is no match, it puts NA
def ext_fn_part(regex, fn_list):
	result = []
	for i in range(0,len(fn_list)):
		m = re.search(regex, fn_list[i])
		if m:
			match = m.group(len(m.groups()))
			result.append(match)
		else:
			result.append('NA')
	return result

# make a list of subjects and blocks
subjects = ext_fn_part(subj, filenames)
	
# stack all of the data files together vertically		
data = pd.DataFrame()
for i in range(0,len(filenames)):
	df = pd.read_table(filenames[i], delimiter = '\t') # read data
	df.insert(loc=3, column = 'Trial', value = df.index.values.astype(int) + 1) # add trial column based on row index
	frames = [data,df]
	data = pd.concat(frames)
	
# find current date and time
now = datetime.datetime.now()
dt = now.strftime("%m-%d-%y_%H%M")

# save data
data.to_csv(data_dir + '/Ashby_concat_' + dt + '.csv', index = False)
#!/usr/bin/env python2

import glob
import pandas as pd
import numpy as np
import os
import datetime

# get current directory
data_dir = os.getcwd()

# change to data directory
## change this if data location changes
os.chdir('/Volumes/EEG/CategoryLearning/Data/Exp2/Sloutsky')

# make a list of all data filenames
filenames = glob.glob('*.tsv')

# extract subject numbers from filenames and put in a list
subjlist = []
for i in range(0,len(filenames)):
	name = filenames[i][4:8] # find subject number based on location in string
	subjlist.append(name)
	
trial = range(1,41)
fourblocks = trial + trial + trial + trial
blocknums = [1]*40 + [2]*40 + [3]*40 + [4]*40

	
# stack all of the data files together vertically	
data = pd.DataFrame()
for i in range(0,len(filenames)):
	df = pd.read_table(filenames[i], delimiter = '\t') # read data
	df.insert(loc=0, column = 'Subject', value = subjlist[i]) # add subject column
	df.insert(loc=2, column = 'BlockNum', value = blocknums) 
	df.insert(loc=3, column = 'Trial', value = fourblocks) 
	frames = [data,df]
	data = pd.concat(frames)
	
# find current date and time
now = datetime.datetime.now()
dt = now.strftime("%m-%d-%y_%H%M")

# save data
data.to_csv(data_dir + '/Sloutsky_concat_' + dt + '.csv', index = False)
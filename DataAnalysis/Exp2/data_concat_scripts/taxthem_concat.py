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
os.chdir('/Volumes/EEG/CategoryLearning/Data/Exp2/Tax_Them')

# make a list of all data filenames
filenames = glob.glob('*.csv')

# get experiment name for each data file
explist = []
for i in range(0,len(filenames)):
	exp = filenames[i].split('_')[0]
	explist.append(exp)

# stack all of the data files together vertically	
data = pd.DataFrame()
for i in range(0,len(filenames)):
	df = pd.read_csv(filenames[i]) # read data
	df['Experiment'] = explist[i] # add experiment column
	frames = [data,df]
	data = pd.concat(frames)

# find current date and time	
now = datetime.datetime.now()
dt = now.strftime("%m-%d-%y_%H%M")

# save data
data.to_csv(data_dir + '/taxthem_concat_' + dt + '.csv', index = False)
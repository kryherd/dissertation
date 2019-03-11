#!/usr/bin/env python2

import glob
import pandas as pd
import numpy as np
import os
import datetime
import re

# change to data directory
## change this if data location changes
os.chdir('/Volumes/EEG/CategoryLearning/Data/Exp2/')

# make a list of all data filenames
flanker = glob.glob('Flanker/*/flanker-[0-9]*.csv')
switcher = glob.glob('Switcher/*/switch-summary-*csv')
tol = glob.glob('ToL/*/tol-summary-*csv')

# find current date and time
now = datetime.datetime.now()
dt = now.strftime("%m-%d-%y_%H%M")
	
# stack all of the data files together vertically	

def stack_data(filenames):	
	data = pd.DataFrame()
	for i in range(0,len(filenames)):
		df = pd.read_csv(filenames[i]) # read data
		frames = [data,df]
		data = pd.concat(frames)
	return(data);

flank_dat = stack_data(flanker)
flank_dat.to_csv('~/dissertation/DataAnalysis/Exp2/data_files/flanker_concat_' + dt + '.csv', index = False)

switch_dat = stack_data(switcher)
switch_dat.to_csv('~/dissertation/DataAnalysis/Exp2/data_files/switcher_concat_' + dt + '.csv', index = False)

tol_dat = stack_data(tol)
tol_dat.to_csv('~/dissertation/DataAnalysis/Exp2/data_files/tol_concat_' + dt + '.csv', index = False)

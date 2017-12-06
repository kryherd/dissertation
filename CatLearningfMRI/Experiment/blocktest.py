# import psychopy modules
from psychopy import visual, core, event, sound, gui, data, logging
# import math (for rounding function)
import math
import numpy as np 
import random
import pandas as pd

#set parent directory
parent_dir = "./"

#get some startup information from the user
info = {'ID Number':'', 'Order': ''}
dlg = gui.DlgFromDict(info, title='Category Learning Task')
if not dlg.OK:
    core.quit()


blockInstr = pd.read_table('blockInstr.csv', sep=',')

#create dictionary for which type of block matches to which number
block = {1: "UnsupervisedSparse", 2: "UnsupervisedDense", 3: "SupervisedSparse", 4: "SupervisedDense"}
# create dictionary that allows you to run in order
order = {1: "Block1", 2: "Block2", 3: "Block3", 4: "Block4"}
# read in whole order spreadsheet
order_list = pd.read_table('blockOrders.csv', sep=',')
# select the row that has the order entered in initially
sel_order = order_list.loc[order_list['Order'] == int(info['Order'])]
# run through the blocks in ORDER!!!
for i in range(1, 5):
    blockName = block[sel_order.iloc[0][order[i]]]
    sel_instr = blockInstr.loc[blockInstr['BlockName'] == blockName, 'Instr']
    block_instr = sel_instr.iloc[0][0:]




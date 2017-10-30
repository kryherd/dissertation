# import psychopy modules
from psychopy import visual, core, event, sound, gui, data, logging
import numpy as np
# load module for list randomization
import random

#set parent directory
parent_dir = "/Users/kryherd/dissertation/CategorizationExps/Ashby"

#get some startup information from the user
info = {'participant_id':''}
dlg = gui.DlgFromDict(info, title = 'Ashby Task Startup')
if not dlg.OK:
    core.quit()

win = visual.Window([2560,1440], monitor='LabDesktop')

instruct_txt = visual.TextStim(win, text = "Today you will be learning about two categories. Each category is equally likely. \n\
Perfect performance is possible. You will receive feedback to help you learn the categories. \n\
Please be as quick and accurate as you can. \n \n\
Press SPACE to continue.",
                        color = "black",
                        height = 48,
                        units = "pix",
                        alignHoriz='center',
                        alignVert='center',
                        font = "Arial",
                        wrapWidth= 2000,
                        autoLog=True)

instruct_txt2 = visual.TextStim(win, text = "When you see the picture, press the D key for Category A and the J key for Category B.\n \n\
Press SPACE to continue.",
                        color = "black",
                        height = 48,
                        units = "pix",
                        alignHoriz='center',
                        alignVert='center',
                        font = "Arial",
                        wrapWidth= 2000,
                        autoLog=True)

right_txt = visual.TextStim(win, text = "Correct",
                        color = "black",
                        height = 48,
                        units = "pix",
                        alignHoriz='center',
                        alignVert='center',
                        font = "Arial",
                        wrapWidth= 2000,
                        autoLog=True)

wrong_txt = visual.TextStim(win, text = "Incorrect",
                        color = "black",
                        height = 48,
                        units = "pix",
                        alignHoriz='center',
                        alignVert='center',
                        font = "Arial",
                        wrapWidth= 2000,
                        autoLog=True)

slow_txt = visual.TextStim(win, text = "Too Slow",
                        color = "black",
                        height = 48,
                        units = "pix",
                        alignHoriz='center',
                        alignVert='center',
                        font = "Arial",
                        wrapWidth= 2000,
                        autoLog=True)

prefix = 'AshbyTask-RB-sub%s' % (info['participant_id'])

#logging data 
# overwrite (filemode='w') a detailed log of the last run in this dir
errorLog = logging.LogFile(prefix + "_errorlog.log", level=logging.DATA, filemode='w')

# in the data source, there are three columns: ii.freq, ii.or, category
# load in our stimulus timing xlsx file
TRIAL_LIST = data.importConditions(fileName = "RB_PatchParameters.csv")
totalTrials = len(TRIAL_LIST)

def check_exit():
#abort if esc was pressed
    if event.getKeys('escape'):
        win.close()
        core.quit()

#instructions 1
instruct_txt.draw()
win.flip() 
#waiting for space bar to continue
keys =event.waitKeys(keyList=['space'])
#instructions 2
instruct_txt2.draw()
win.flip() 
#waiting for space bar to continue
keys =event.waitKeys(keyList=['space'])


TRIAL_LIST_RAND = TRIAL_LIST
random.shuffle(TRIAL_LIST_RAND)

# header for data log
data = np.hstack(("Type","Category", "KEY", "RESP", "Accuracy", "RT"))

############## II BLOCK GOES FIRST

for index in range(len(TRIAL_LIST_RAND)):
    #draw so we are ready to flip
    
    #wait until the right moment
    #abort if esc was pressed
    #exit will be delayed until the end of a block
    check_exit()
    stim = visual.GratingStim(win, tex='sin', mask='gauss', 
                    sf=TRIAL_LIST_RAND[index]['rb_freq'], 
                    size=5, 
                    ori=TRIAL_LIST_RAND[index]['rb_or'], 
                    units='deg',
                    autoLog=True)
    stim.draw()
    win.flip()
    t0 = core.getTime()
    while core.getTime()-t0 <= 5:
        #abort if esc was pressed
        check_exit()
        KEY = event.getKeys(keyList=["d","j"])
        if KEY != []:
            t1 = core.getTime()
            win.flip()
            break
# map keypress to meaningful response type
    if KEY == []:
        KEY = "None"
        RESP = "None"
    elif KEY == ["d"]:
        RESP = "a"
    elif KEY == ["j"]:
        RESP = "b"

# determine the accuracy of the response, calculate reaction time, and give feedback
    if RESP == "None":
        ACC = 0; RT = 9999
        slow_txt.draw(); win.flip(); core.wait(1)
    elif RESP == TRIAL_LIST_RAND[index]["category"]:
        ACC = 1; RT = t1-t0
        right_txt.draw(); win.flip(); core.wait(1)
    elif RESP != TRIAL_LIST_RAND[index]["category"]:
        ACC = 0; RT = t1-t0
        wrong_txt.draw(); win.flip(); core.wait(1)

# store data into the numpy array
    data = np.vstack((data, np.hstack(("RB",
                                    TRIAL_LIST_RAND[index]['category'],
                                    KEY, 
                                    RESP,
                                    ACC, 
                                    "%.3f" %RT))))

np.savetxt(prefix+"_results.tsv",
            data, fmt='%s', delimiter='\t', newline='\n',
            header='', footer='', comments='# ')

# close everything
win.close()
core.quit()


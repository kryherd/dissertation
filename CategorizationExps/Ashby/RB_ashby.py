# import psychopy modules
from psychopy import visual, core, event, sound, gui, data, logging
import numpy as np
# load module for list randomization
import random

#set parent directory
parent_dir = "./"

#get some startup information from the user
info = {'ID Number':''}
dlg = gui.DlgFromDict(info, title = 'Ashby Task Startup - RB')
if not dlg.OK:
    core.quit()

### CHANGE 'MacScreen' to visual angle parameters for the computer you are using
### For Kayleigh's laptop: 30cm away
win = visual.Window([1440,900], monitor='MacScreen')

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
                        wrapWidth= 1200,
                        autoLog=True)

instruct_txt2 = visual.TextStim(win, text = "When you see the picture, press the D key for Category A and the J key for Category B.\n \n\
Press SPACE to continue.",
                        color = "black",
                        height = 48,
                        units = "pix",
                        alignHoriz='center',
                        alignVert='center',
                        font = "Arial",
                        wrapWidth= 1200,
                        autoLog=True)

right_txt = visual.TextStim(win, text = "Correct",
                        color = "black",
                        height = 48,
                        units = "pix",
                        alignHoriz='center',
                        alignVert='center',
                        font = "Arial",
                        wrapWidth= 1200,
                        autoLog=True)

wrong_txt = visual.TextStim(win, text = "Incorrect",
                        color = "black",
                        height = 48,
                        units = "pix",
                        alignHoriz='center',
                        alignVert='center',
                        font = "Arial",
                        wrapWidth= 1200,
                        autoLog=True)

slow_txt = visual.TextStim(win, text = "Too Slow",
                        color = "black",
                        height = 48,
                        units = "pix",
                        alignHoriz='center',
                        alignVert='center',
                        font = "Arial",
                        wrapWidth= 1200,
                        autoLog=True)

invalid_key = visual.TextStim(win, text = "Invalid Key",
                        color = "black",
                        height = 48,
                        units = "pix",
                        alignHoriz='center',
                        alignVert='center',
                        font = "Arial",
                        wrapWidth= 1200,
                        autoLog=True)

prefix = 'AshbyTask-RB-sub%s' % (info['ID Number'])

#logging data 
# overwrite (filemode='w') a detailed log of the last run in this dir
errorLog = logging.LogFile("results/" + prefix + "_errorlog.log", level=logging.DATA, filemode='w')

# in the data source, there are three columns: ii.freq, ii.or, category
# load in our stimulus timing xlsx file
TRIAL_LIST = data.importConditions(fileName = "RB_PatchParameters.csv")
totalTrials = len(TRIAL_LIST)

#create clock
globalClock = core.Clock()
logging.setDefaultClock(globalClock)

# function for getting key presses
def get_keypress():
    keys = event.getKeys(timeStamped=globalClock)
    # if escape was pressed...
    if keys and keys[0][0] == 'escape':
        # save the data in a modified format named "early_quit"
        np.savetxt(parent_dir + "results/early_quit_" + prefix + ".tsv", data, fmt='%s', delimiter='\t', newline='\n', header='', footer='', comments='# ')
        # and exit
        win.close()
        core.quit()
    # otherwise, return the keypress object
    elif keys:
        return keys
    # if no keys were pressed, return None
    else:
        return None

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
data = np.hstack(("Subject","Run","Type","Category", "key_pressed", "RESP", "Accuracy", "RT"))
for i in range(1,4): # runs 3 runs. Change the second number here to increase/decrease number of runs.
    for index in range(len(TRIAL_LIST_RAND)):
        #draw so we are ready to flip
        stim = visual.GratingStim(win, tex='sin', mask='gauss', 
                        sf=TRIAL_LIST_RAND[index]['rb_freq'], 
                        size=11, 
                        ori=TRIAL_LIST_RAND[index]['rb_or'], 
                        units='deg',
                        autoLog=True)
        stim.draw()
        win.flip()
        t0 = globalClock.getTime()
        while globalClock.getTime()-t0 <= 5:
            #abort if esc was pressed
            KEY = get_keypress()
            if KEY != None:
                break
        # map keypress to meaningful response type
        if KEY != None:
            resp = KEY[0][0]
            RT = KEY[0][1] - t0
            if resp == "d":
                RESP = "a"
            elif resp == "j":
                RESP = "b"
            else:
                RESP = "invalid key"
        elif KEY == None:
            resp = "None"
            RESP = "None"
        # determine the accuracy of the response, calculate reaction time, and give feedback
        if RESP == "None":
            ACC = 0; RT = 9999
            slow_txt.draw(); win.flip(); core.wait(1)
        elif RESP == "invalid key":
            ACC = 0
            invalid_key.draw(); win.flip(); core.wait(1)
        elif RESP == TRIAL_LIST_RAND[index]["category"]:
            ACC = 1
            right_txt.draw(); win.flip(); core.wait(1)
        elif RESP != TRIAL_LIST_RAND[index]["category"]:
            ACC = 0
            wrong_txt.draw(); win.flip(); core.wait(1)
        # store data into the numpy array
        data = np.vstack((data, np.hstack((info['ID Number'],
                                        i,
                                        "RB",
                                        TRIAL_LIST_RAND[index]['category'],
                                        resp, 
                                        RESP,
                                        ACC, 
                                        "%.3f" %RT))))

np.savetxt(prefix+"_results.tsv",
            data, fmt='%s', delimiter='\t', newline='\n',
            header='', footer='', comments='# ')

# close everything
win.close()
core.quit()


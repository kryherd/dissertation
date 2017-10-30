# import psychopy modules
from psychopy import visual, core, event, sound, gui, data, logging

#get some startup information from the user
info = {'participant_id':''}
#dlg = gui.DlgFromDict(info, title = 'Ashby Task Startup')
#if not dlg.OK:
#    core.quit()

win = visual.Window(size = [1440,900],
                    color = "gray",
                    fullscr = True, allowGUI=False,
units = "pix")

grating = visual.GratingStim(win, tex='sin', mask='gauss', sf=1.15, size=512, ori=54.7, units='norm')
grating.draw()
win.flip()
core.wait(3)
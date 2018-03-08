## To-Do List: Cat Learning fMRI Experiment

### Experimental Design
* ~~Determine number of trials per condition - see papers from Roeland~~
	* 65 trials/condition (Turner & Miller, 2013)
* Create additional stimuli
	* Currently have 32 target for unsupervised, 16 for supervised
	* Also 16 distractor for each
* Determine timing (remove self-paced? or just add jitter?)


## Script usage

#### Optimization scripts

You can use `opt_loop.sh` to test different TRs and number of experimental trials.

`sh opt_loop.sh TR`

e.g., `sh opt_loop.sh 2`

To change the rep options, go into `opt_loop.sh` and edit line 3. You can test multple numbers of repetitions with this loop.

You can go into the folders that are created and look at the `results.txt`. At the bottom you will see what the lowest efficiency values are. Once you find a design that is optimally efficient, use the `testiter.sh` script to create a timing file for experimental presentation software.

Navigate into the folder that has the most optimal design. Then run `sh testiter.sh XX`, where `XX` is the number of the iteration you'd like to use.

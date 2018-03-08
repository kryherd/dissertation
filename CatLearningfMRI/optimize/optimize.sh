#!/bin/bash
#the number of iterations
N=$1 #the number of iterations
TR=$2
n_reps=$3 # number of trials
prefix=`echo reps-${n_reps}_tr-${TR}`

NT=`echo "$(( TR * ( 10 + n_reps) ))"`

mkdir $prefix
cd $prefix

echo "" > results.txt
echo "iter stimEff contrastEff seed" > results.txt

#portable method of getting a random number
for i in $(seq 1 $N); do
seed=`cat /dev/random|head -c 256|cksum |awk '{print $1}'`

#generate many random sequences with 3 conditions:
#1 - target
#2 - distractor
#3 - catch
RSFgen \
-nt ${NT} -num_stimts 3 \
-nreps 1 ${n_reps}		\
-nreps 2 ${n_reps} 	\
-nreps 3 10		\
-seed ${seed} 	\
-prefix rsf_${i}_


#convert binary files to timing in seconds, this will be a local timing file, where each run starts at t=0
make_stim_times.py -files rsf_${i}_*.1D -prefix stim.${i} -nt ${NT} -tr 2 -nruns 1

#evaluate the efficiency of the design
3dDeconvolve \
-nodata ${NT} 2 \
-polort 2 \
 -num_stimts 3 \
 -stim_times 1 stim.${i}.01.1D 'GAM' \
 -stim_label 1 'Target' \
 -stim_times 2 stim.${i}.02.1D 'GAM' \
 -stim_label 2 'Distractor' \
 -stim_times 3 stim.${i}.03.1D 'GAM' \
 -stim_label 3 'Catch' \
 -gltsym "SYM: 1.0*Target -1.0*Distractor" > efficiency.${i}.txt

eff=`../efficiency_parser.py efficiency.${i}.txt`

echo "$i $eff $seed" >> results.txt
#end loop
done

python ../findLowest.py

cp ../testiter.sh .
cp ../timingtotal.py .
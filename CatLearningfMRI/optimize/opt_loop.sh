#!/bin/bash
TR=$1
for n_rep in 20 40 65 80 #change rep options here
do
	sh optimize.sh 100 ${TR} ${n_rep}
done
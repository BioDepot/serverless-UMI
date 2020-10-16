#!/bin/bash
nruns=$1
for ((n=0;n<nruns;n++)); do
	echo "async run $n"
	./runAll.sh
	./cleanup.sh &> /mnt/data/cleanupLog
done

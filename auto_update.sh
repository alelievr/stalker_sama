#!/bin/sh

while true
do
	nc -l 4200
	cd ~/stalker_sama && git pull
	./stop.sh
	./run.sh 2>&1 > stalker.log &
done

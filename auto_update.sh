#!/bin/sh

while true
do
	if nc -l 4200 | grep -iq "\[prod ready\]"; then
		cd ~/stalker_sama && git pull
		./stop.sh
		./run.sh | tee stalker.log &
	fi
done

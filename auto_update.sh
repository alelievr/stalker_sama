#!/bin/sh

while true
do
	nc -l 4200
	cd ~/stalker_sama && git pull
	./stop.sh
	./start.sh
done

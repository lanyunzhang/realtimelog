#!/bin/bash
#
LOG_DIR=/home/s/logs/dxue.app/counter
DATA_DIR=/da2/s/var/qss/line2/sxml.out

[ -d $LOG_DIR ] || mkdir -p $LOG_DIR
TIMESTAMP=$(date +"%Y%m%d%H%M")

for i in $(seq 0 9)
do
	cat  /da2/s/var/qss/line2/sxml.out/0000$i/2013*/line2* | ./parseLine.pl -host p02.se.zzbc.qihoo.net -port 6380  -product qss -send-per-num 2000 2>$LOG_DIR/counter.$TIMESTAMP.log | wc -l > /dev/null 
done
#cat $DATA_DIR/*/*/* | ./parseLine.pl -host p02.se.zzbc.qihoo.net -port 6380 -product qss -send-per-num 2000 > /tmp/counter.$TIMESTAMP.log
#cat  /da2/s/var/qss/line2/sxml.out/00000/2013*/line2*

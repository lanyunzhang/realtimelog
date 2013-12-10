#!/bin/bash
#
APPDIR=$(dirname $0)
CONF_DIR=../$APPDIR/config
LOG_DIR=/home/s/logs/dxue.app/counter
[ -d $LOG_DIR ] || mkdir -p $LOG_DIR

$APPDIR/redis-server $CONF_DIR/redis.conf --port 6380 & >> $LOG_DIR/redis.log 2>&1

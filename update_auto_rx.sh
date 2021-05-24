#!/bin/bash

# -----------------------------------
#  radiosonde_auto_rx docker updater
# -----------------------------------
#
#  To be run by cron to update docker container daily
#  This must be run on the host system, not from within the docker container


# define log file location
LOG_FILE=~/radiosonde_auto_rx/log/docker_updates.log

echo "-----------------------------" | tee -a $LOG_FILE
echo "-  " $(date '+%Y-%m-%d  %T') "    -" | tee -a $LOG_FILE
echo "- UPDATING DOCKER CONTAINER -" | tee -a $LOG_FILE
echo "-----------------------------" | tee -a $LOG_FILE

echo "* Pulling the latest container..." | tee -a $LOG_FILE
# While pulling local container and teeing to log file, check if the STDOUT status contains$
if  docker pull ghcr.io/projecthorus/radiosonde_auto_rx:latest | tee -a $LOG_FILE | grep    "Status: Image is up to date for ghcr.io/projecthorus/radiosonde_auto_rx:latest";
then
   # Container is up to date - Report this to the log then do nothing
   echo "Current Container is the latest version." | tee -a $LOG_FILE
else
   # The container is either not the latest version, or docker has reported something else.$
   echo "* Stopping the existing container..." | tee -a $LOG_FILE
   docker stop radiosonde_auto_rx >> $LOG_FILE


   echo "* Removing the existing container..." | tee -a $LOG_FILE
   docker rm radiosonde_auto_rx >> $LOG_FILE

   echo "* Starting docker container..." | tee -a $LOG_FILE
   docker run \
     -d \
     --name radiosonde_auto_rx \
     --restart="always" \
     --device=/dev/bus/usb \
     --network=host \
     -v ~/radiosonde_auto_rx/station.cfg:/opt/auto_rx/station.cfg:ro \
     -v ~/radiosonde_auto_rx/log/:/opt/auto_rx/log/ \
     ghcr.io/projecthorus/radiosonde_auto_rx:latest  | tee -a $LOG_FILE


fi

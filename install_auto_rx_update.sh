#!/bin/bash

# Define colours for script output
RED="31"
GREEN="32"
YELLOW="33"
BOLDGREEN="\e[1;${GREEN}m"
BOLDYELLOW="\e[1;${YELLOW}m"
ITALICRED="\e[3;${RED}m"
ENDCOLOR="\e[0m"

# See who is logged in
echo -e "${BOLDGREEN}Finding username...${ENDCOLOR}"
shopt -s lastpipe
logname | read username

# If argument 'uninstall' was passed then remove all relevant files except for this script
if [ $1 == "uninstall" ]
then
    echo "Removing cron job..."
    sudo rm /etc/cron.d/updateautorx
    echo "Removing auto_rx_auto_update (including log)..."
    sudo rm -r /home/$username/auto_rx_auto_update
    echo "auto_rx_auto_update has been removed"
    exit 0
fi

echo ""
echo ""
echo -e "${BOLDGREEN}-----------------------------------------------------------"
echo -e "- INSTALLING radiosonde_auto_rx DOCKER IMAGE AUTO UPDATER -"
echo -e "-----------------------------------------------------------${ENDCOLOR}"
echo -e "Setting up scripts for user: ${ITALICRED}$username${ENDCOLOR}"


# If auto_rx_auto_update directory does not exist then create it
if [ ! -d "/home/$username/auto_rx_auto_update" ]
then
    #Create directory for script files
    mkdir /home/$username/auto_rx_auto_update
fi

# Move into auto_rx_auto_update directory
cd /home/$username/auto_rx_auto_update/

# If the run_docker.sh script exists do not recreate the run_docker.sh file
if [ -f  "run_docker.sh" ]
then
    echo "Docker configuration exists - Skipping creation of run_docker.sh ..."
else
    # Create a .sh script for running the docker container
    echo -e "${BOLDGREEN}Creating run_docker shell script...${ENDCOLOR}"
    echo "Modify the arguments to match your requirements"
    echo "Please do not change the last line"
    echo "<< Press any key to edit the file >>"
    read -n 1
    cat <<'EOF' > run_docker.sh
        docker run \
          -d \
          --name radiosonde_auto_rx \
          --restart="always" \
          --device=/dev/bus/usb \
          --network=host \
          -v ~/radiosonde_auto_rx/station.cfg:/opt/auto_rx/station.cfg:ro \
          -v ~/radiosonde_auto_rx/log/:/opt/auto_rx/log/ \
          ghcr.io/projecthorus/radiosonde_auto_rx:latest
EOF
    nano run_docker.sh
    # Make the run_docker script executable
    chmod 755 run_docker.sh

fi

# Create a shell script which checks if docker image is up to date.  If it's not the script will shutdown and remove the current container to update the image
echo -e "${BOLDGREEN}Creating Update Script...${ENDCOLOR}"
cat <<'EOF' > update_auto_rx.sh
    #!/bin/bash

    # -----------------------------------
    #  radiosonde_auto_rx docker updater
    # -----------------------------------
    #
    #  To be run by cron to update docker container daily
    #  This must be run on the host system, not from within the docker container

    # define log file location
EOF

echo "    LOG_FILE=/home/$username/auto_rx_auto_update/update_attempts.log" >> update_auto_rx.sh

cat <<'EOF' >> update_auto_rx.sh
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
       # The container is either not the latest version, or docker has reported something else.
       echo "* Stopping the existing container..." | tee -a $LOG_FILE
       docker stop radiosonde_auto_rx >> $LOG_FILE


       echo "* Removing the existing container..." | tee -a $LOG_FILE
       docker rm radiosonde_auto_rx >> $LOG_FILE

       echo "* Starting docker container..." | tee -a $LOG_FILE
EOF
# Adda a call for the run_docker script then add end if statement from the block above
cat run_docker.sh >> update_auto_rx.sh
echo "        ./run_docker.sh | tee -a $LOG_FILE" >> update_auto_rx.sh
echo "    fi" >> update_auto_rx.sh


# Make the update script executable
chmod 755 update_auto_rx.sh

# Calculate scheduled time for cron job in local time by converting from Zulu/UTC
# Set UTC time for cron schedule
zulu_hrs=18
zulu_mins=0

# Get local timezone info
zone_sign=$(date +%z | cut -c1-1)
zone_hours=$(date +%z | cut -c2-3)
zone_mins=$(date +%z | cut -c4-5)

# Apply timezone to scheduled time
if [ $zone_sign == '+' ]
then
   cron_hour="$((10#$zone_hours + $zulu_hrs))"
   cron_min="$((10#$zone_mins + $zulu_mins))"
elif [ $zone_sign == '-' ]
then
   cron_hour="$((10#$zone_hours - $zulu_hrs))"
   cron_min="$((10#$zone_mins - $zulu_mins))"
else
   # Did not get suitable sign, revert to local time
   cron_hour=$zone_hours
   cron_min=$zone_mins
fi

# Correct for overflow in application of timezone to scheduled time
if [ "$cron_hour" -gt "23" ]
then
  cron_hour=$(($cron_hour-24))
elif [ "$cron_hour" --lt "0" ]
then
  cron_hour=$(($cron_hour+24))
fi

if [ "$cron_min" -gt 59 ]
then
  cron_min=$(($cron_min-60))
elif [ "$cron_min" -lt 0 ]
then
  cron_min=$(($cron_min+60))
fi


# Create cron.d job to update the radiosonde_auto_rx docker image.
echo -e "${BOLDYELLOW}Creating cron job to run update daily at $cron_hour:$cron_min...${ENDCOLOR}"
sudo echo "# Attempt to update radiosonde_auto_rx docker image at $zulu_hrs:$zulu_mins UTC ($cron_hour:$cron_min local time) every day." > /etc/cron.d/updateautorx
sudo echo "$cron_min $cron_hour * * * $username ~/auto_rx_auto_update/update_auto_rx.sh" >> /etc/cron.d/updateautorx

echo -e "${BOLDGREEN}Running update script now...${ENDCOLOR}"
./update_auto_rx.sh

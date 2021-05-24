#!/bin/bash

# define colours
RED="31"
GREEN="32"
YELLOW="33"
BOLDGREEN="\e[1;${GREEN}m"
BOLDYELLOW="\e[1;${YELLOW}m"
ITALICRED="\e[3;${RED}m"
ENDCOLOR="\e[0m"

echo ""
echo ""
echo -e "${BOLDGREEN}-----------------------------------------------------------"
echo -e "- INSTALLING radiosonde_auto_rx DOCKER IMAGE AUTO UPDATER -"
echo -e "-----------------------------------------------------------${ENDCOLOR}"

# See who is logged in
echo -e "${BOLDGREEN}Finding username...${ENDCOLOR}"
shopt -s lastpipe
logname | read username
echo -e "Setting up scripts for user: ${ITALICRED}$username${ENDCOLOR}"

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

echo -e "${BOLDGREEN}Creating Update Script...${ENDCOLOR}"	
# create update script
cat <<'EOF' > testupdate.sh
    #!/bin/bash

    # -----------------------------------
    #  radiosonde_auto_rx docker updater
    # -----------------------------------
    #
    #  To be run by cron to update docker container daily
    #  This must be run on the host system, not from within the docker container


    # define log file location
EOF

echo "    LOG_FILE=/home/$username/radiosonde_auto_rx/log/docker_updates.log" >> testupdate.sh

cat <<'EOF' >> testupdate.sh
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

# Add customised docker_arguments file to script then end if statement from the block above
cat run_docker.sh >> testupdate.sh
echo "        ./run_docker.sh | tee -a $LOG_FILE" >> testupdate.sh
echo "    fi" >> testupdate.sh

# Make the update script executable
chmod 755 testupdate.sh

# Create cron.d job to update the radiosonde_auto_rx docker image.
echo -e "${BOLDYELLOW}Creating cron job to run update daily at 3.30am...${ENDCOLOR}"
sudo echo "# Attempt to update radiosonde_auto_rx docker image at 3.30am every day." > /etc/cron.d/updateautorx
sudo echo "30 3 * * * $username ~/update_auto_rx.sh" >> /etc/cron.d/updateautorx

echo -e "${BOLDGREEN}Running update script now...${ENDCOLOR}"
./testupdate.sh


#!/bin/bash

# Define colours for script output
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

#Create directory for script files
mkdir /home/$username/auto_rx_auto_update
cd /home/$username/auto_rx_auto_update/

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

echo "    LOG_FILE=/home/$username/radiosonde_auto_rx/log/docker_updates.log" >> update_auto_rx.sh

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

# Create cron.d job to update the radiosonde_auto_rx docker image.
echo -e "${BOLDYELLOW}Creating cron job to run update daily at 18:00UTC...${ENDCOLOR}"
sudo echo "# Attempt to update radiosonde_auto_rx docker image at 18:00 UTC every day." > /etc/cron.d/updateautorx
sudo echo "CRON_TZ=UTC" >> /etc/cron.d/updateautorx
sudo echo "0 18 * * * $username ~/update_auto_rx.sh" >> /etc/cron.d/updateautorx

echo -e "${BOLDGREEN}Running update script now...${ENDCOLOR}"
./update_auto_rx.sh


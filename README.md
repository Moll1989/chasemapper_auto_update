# auto_rx_auto_update
This project is a set of shell scripts for automatically updating projecthorus/radiosonde_auto_rx docker images.  These scripts should only be used on Docker based installs of 
auto_rx and SHOULD NOT be used on 'native' installs of auto_rx.<br>
<br>
This script is targeted at the Raspberry Pi, running Raspbian Lite.  It may not operate correctly on other platforms.<br>
<br>
When installing auto_update, there are 3 files created:<br>

* __~/auto_rx_auto_update/run_docker.sh__ - This script has all of the arguments that should be passed to docker when launching auto_rx.  This should be customised by the user.
* __~/auto_rx_auto_update/update_auto_rx.sh__ - This is the script which checks whether your docker container is up to date with the latest version, and if not launches run_docker.sh
* __/etc/cron.d/updateautorx__ - This cron file launches the update_auto_rx.sh script daily.


## Installation Instructions
Installation of the auto_updater is easy.  There is a single convenient install script which can be downloaded from this project.<br>
<br>
Simply download the script, make it executable and then run it:

    cd ~/
    wget https://raw.githubusercontent.com/Moll1989/auto_rx_auto_update/main/install_auto_rx_update.sh
    chmod 755 install_auto_rx_update.sh
    ./install_auto_rx_update.sh

The install script will now create the other required script files.
<br><br>
During the installation an instance of the nano editor will open to remind you to configure your run_docker.sh script.  Once you have made any required changes to the run_docker.sh script, simply press CTRL+O then CTRL+X.
<br><br>
By default a daily cron job will be inserted to run updates at 3.30am local time.
<br><br>
At the conclusion of the script an update will be run.
<br><br>
If you are setting up a fresh install of project_horus/radiosonde_auto_rx you can run the above codeblock in place of the first time you launch docker.

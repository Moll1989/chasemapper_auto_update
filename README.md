# chasemapper_auto_update
This project is a set of shell scripts for automatically updating projecthorus/chasemapper docker images.  These scripts should only be used on Docker based installs of 
chasemapper and SHOULD NOT be used on 'native' installs of auto_rx.<br>
<br>
This script is targeted at the Raspberry Pi, running Raspbian Lite.  It may not operate correctly on other platforms.<br>
<br>
When installing auto_update, there are 3 files created:<br>

* __~/chasemapper_auto_update/run_docker.sh__ - This script has all of the arguments that should be passed to docker when launching chasemapper.  This should be customised by the user.
* __~/chasemapper_auto_update/update_auto_rx.sh__ - This is the script which checks whether your docker container is up to date with the latest version, and if not launches run_docker.sh
* __/etc/cron.d/updatechasemapper__ - This cron file launches the update_chasemapper.sh script daily.


## Installation Instructions
Installation of the auto_updater is easy.  There is a single convenient install script which can be downloaded from this project.<br>
<br>
Simply download the script, make it executable and then run it with root permission:

    cd ~/
    wget https://raw.githubusercontent.com/Moll1989/chasemapper_auto_update/main/install_chasemapper_update.sh
    chmod 755 install_chasemapper_update.sh
    sudo ./install_chasemapper_update.sh

The install script will now create the other required script files.
<br><br>
During the installation an instance of the nano editor will open to remind you to configure your run_docker.sh script.  Once you have made any required changes to the run_docker.sh script, simply press CTRL+O then ENTER then CTRL+X.
<br><br>
By default a daily cron job will be inserted to run updates at 18:30 UTC.
<br><br>
At the conclusion of the script an update will be run.
<br><br>
If you are setting up a fresh install of project_horus/chasemapper you can run the above codeblock in place of the first time you launch docker.

## Uninstall Instructions
auto_updater is easy to uninstall.  Simply run the install script with the 'uninstall' argument.  Make sure you elevate the user, otherwise you may not be able to remove the cron.d file.

    sudo ./install_chasemapper_update.sh uninstall

This will remove all chasemapper_auto_update files, including logs, except for the install script.  The install script can be removed with:

    rm install_chasemapper_update.sh

Removing the auto_updater will not impact your instance of chasemapper.

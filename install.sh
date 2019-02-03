#!/bin/bash

#######################################################
# CHANGE THE FOLLOWING VARIABLES TO SUIT YOUR NEED    #
#######################################################
user=alona                                # insert your username here
install_location=/home/alona              # insert where you want the sync.sh to be installed to
backup_location=/home/alona/dropbox_backup # insert the FULL PATH where you want your dropbox backup to be located
dropbox_folder=/home/alona/Dropbox        # insert the FULL PATH of where your already existing Dropbox folder is
cron_hour=10                              # insert what hour you want the script to run at (24-hour time)
cron_minute=10                            # insert what minute you want the script to run at
                                          # cron_hour and cron_minute will form the time
daily=true                                # if you want the script to run every day, true is run every day, false is use the next variable
day=                                      # leave empty if you want it to run every day
                                          # if you want to run every, sunday: 0, monday: 1, tuesday: 2, ... sunday: 6
cron_location=/etc/cron.d/anacron         # you SHOULDN'T have to change this

########################################################
# You shouldn't need to change the following variables #
########################################################
current_dir=`pwd`
install_dir=$install_location/sync.sh

# check for root
if [ "$EUID" -ne 0 ]; then
  echo 'This script needs to be run as root'
  exit
fi
function gensync {
  # Generate the sync.sh script.
  # TODO: There has to be a better way to do this.
  echo '#!/bin/bash' >> $install_dir
  echo 'dat=`date +%d-%m-%y`' >> $install_dir
  echo "path=${install_location}" >> $install_dir
  echo "bac=${backup_location}" >> $install_dir
  echo "dropbx=${dropbox_folder}" >> $install_dir
  echo 'function sync() {' >> $install_dir
  echo 'if [ ! -d $path/$bac/ ]; then' >> $install_dir
  echo 'mkdir $path/$bac' >> $install_dir
  echo 'sync()' >> $install_dir
  echo 'elif [ ! -d $path/$bac/$dat]; then' >> $install_dir
  echo 'mkdir $path/$bac/$dat' >> $install_dir
  echo 'cp -r $path/$dropbx' >> $install_dir
  echo 'tar -czvf $path/$bac/$dat.tar.gz $path/$bac/$dat/'>> $install_dir
  echo 'rm -rf $path/$bac/$dat' >> $install_dir
  echo 'else' >> $install_dir
  echo 'exit' >> $install_dir
  echo 'fi' >> $install_dir
  echo '}' >> $install_dir
  # Make file executable
  chmod +x $install_dir
}

# Check if sync.sh is full
if [ -s $install_dir ]; then
  # File is empty, go ahead and generate sync.sh in #install_dir
  gensync
else
  # Back up current sync.sh
  mv $install_dir $install_dir.bak
  # overwrite contents
  echo '' > $install_dir
  gensync
fi

# Add the crontab entry
# if daly is set to true
if [[ $daily == "true" ]]; then
  echo "$cron_minute $cron_hour * * * $user bash $install_dir" >> $cron_location
fi
# if daily is set to false
if [[ $daily == "false" ]]; then
  echo "$cron_minute $cron_hour * * $day $user bash $install_dir" >> $cron_location
fi
#if daily is set to false and day is false, return an error and exit
if [[ $daily == "false" && -z "$day" ]]; then
  echo 'Please either set the daily variable to true, or specify a day'.
  echo 'Exiting so you can fix this error.'
  exit
fi

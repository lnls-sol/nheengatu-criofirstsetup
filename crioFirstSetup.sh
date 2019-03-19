#!/bin/bash

USER=$1

if [ -z $USER ]
    then
        echo "No user name inserted to create. usage : ./setup.sh <USERNAME>"
        exit
fi
# Check firmware if updated. 
if [`uname -r` != "4.9.47-rt37-6.1.0f0"] 
    then
        echo "Kernel was not updated to 4.9.47-rt37-6.1.0f0. Please update firmware from NI-MAX."
        exit
fi

# Print repositories 2018.5
cat /etc/opkg/base-feeds.conf

#Update and install useful stuff
sudo opkg update
sudo opkg install nfs-utils-client git vim rsync



#Create user
echo "Adding user $USER"
useradd $USER

#Add user to sudo group
usermod -aG sudo $USER
sed -i 's/# %sudo\tALL=(ALL) ALL/%sudo\tALL=(ALL) ALL/g' /etc/sudoers

#Move home folder to ABTLUS
mkdir /home/ABTLUS
rsync -aXS /home/$USER /home/ABTLUS/$USER
usermod -m -d /home/ABTLUS/$USER $USER


#!/bin/bash

USER=SOL

# Check firmware if updated. 
if [`uname -r` != "4.9.47-rt37-6.1.0f0"] 
    then
        echo "Kernel was not updated to 4.9.47-rt37-6.1.0f0. Please update firmware from NI-MAX."
        exit
fi

# Print repositories 2018.5
cat /etc/opkg/base-feeds.conf

#Update and install useful stuff
opkg update
opkg install nfs-utils-client git vim rsync



#Create user
echo "Adding user $USER"
useradd $USER -p '$6$UebZimA8$ch0bVw0/RyDnOy31dVtHASPVKbM7VaTw0BXZejSQxzY4rCedtpYc9p63iz618Me18bHW.wVr8USR7usDrRDeV/'

#Add user to sudo group
usermod -aG sudo $USER

#Add to ni  group so that can open shared memory
usermod -aG ni $USER

sed -i 's/# %sudo\tALL=(ALL) ALL/%sudo\tALL=(ALL) ALL/g' /etc/sudoers

#Move home folder to ABTLUS
mkdir /home/ABTLUS
#rsync -aXS /home/$USER /home/ABTLUS/$USER
usermod -m -d /home/ABTLUS/$USER $USER

#Surpass NI terminal bug
chmod 755 /bin/hostname


echo "------------DONE SETTING UP USER AND REPOSITORIES---------------"
echo "..."
echo "-------------SETTING UP IOCS SCRIPT---------------"
sudo cp iocs /etc/init.d
sudo cp init-functions /etc/init.d
sudo ln -s /etc/init.d/iocs /bin/
sudo /usr/sbin/update-rc.d iocs defaults
echo "------------DONE SETTING UP IOCS SCRIPT---------------"
echo "..."
echo "-------------SETTING UP AutoSave folder ---------------"
mkdir -p /opt/autosave
chmod 777 /opt/autosave
echo "..."
echo "-------------SETTING UP NFS---------------"
echo "..."
mkdir /usr/local/epics
mkdir /usr/local/epics-nfs

BL=`hostname | /usr/bin/cut -f1 -d'-'` 
HOST=`hostname | /usr/bin/cut -f2 -d'-'` 

echo "10.2.105.218:/usr/local/epics-nfs       /usr/local/epics-nfs    nfs     defaults        0       0" >> /etc/fstab
echo "10.2.105.218:/usr/local/setup-bl/$BL/$HOST/epics       /usr/local/epics    nfs     defaults        0       0" >> /etc/fstab

mount -a

cp epics.sh /etc/profile.d

echo "/usr/local/epics/base/lib/linux-x86_64" > /etc/ld.so.conf.d/epics.conf
echo "/usr/local/epics-nfs/lib/crio-libs/2019_06_28_01/lib" >> /etc/ld.so.conf.d/epics.conf
ldconfig

. /etc/profile.d/epics.sh

cp S95mountnfs /etc/rc5.d

# umount nfs partitions before stop server (this prevent bug on reboot/shutdown)
cp K19umount /etc/rc6.d/
cp K19umount /etc/rc0.d/
echo "-------------DONE SETTING UP NFS---------------"

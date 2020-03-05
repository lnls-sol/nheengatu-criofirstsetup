#!/bin/bash

USER=SOL


if [ -z $1 ]
    then
    echo "Wrong number of inputs. usage: ./crioFirstSetup.sh <Active Directory enabled user>"
    exit  
else
    ADUSER=$1
    echo $ADUSER
fi


# Check firmware if updated. 
if [ `uname -r` != "4.14.87-rt49-cg-7.0.0f0-x64-189" ] && [ `uname -r` != "4.14.87-rt49-cg-7.1.0f0-x64-41" ]
    then
        echo "Kernel was not updated to 4.14.87-rt49-cg-7.0.0f0-x64-189 or 4.14.87-rt49-cg-7.1.0f0-x64-41. Please update firmware from NI-MAX."
        exit
else
	echo "Found up-to-date firmware version. continuing..."
fi


# Print repositories 2019
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
echo ""
echo ""
echo "------------Setting up PBIS. You will need to insert the AD USER password when prompted ---------------"
#pbis configuration
echo "arch amd64 16" >> /etc/opkg/arch.conf
opkg install --force-overwrite files/pbis-open-upgrade_9.1.0.551_amd64.deb files/pbis-open-dev_9.1.0.551_amd64.deb files/pbis-open_9.1.0.551_amd64.deb
/opt/pbis/bin/domainjoin-cli join --ou "ou=DC,ou=LNLS,dc=abtlus,dc=org,dc=br" abtlus.org.br $ADUSER
/opt/pbis/bin/config AssumeDefaultDomain true
/opt/pbis/bin/config HomeDirTemplate %H/%D/%U
/opt/pbis/bin/config LoginShellTemplate /bin/bash
echo "-------------SETTING UP IOCS SCRIPT---------------"
sudo cp files/iocs /etc/init.d
sudo cp files/init-functions /etc/init.d
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

# Hostname example: s-mnc-rio01-b
#
# s:      short for Lnls
# mnc:    short for MANACA beamline
# rio01:  CompactRIO #01
# b:      hutch B
BL=`hostname | tr a-z A-Z | /usr/bin/cut -f2 -d'-'`
LOC=`hostname | tr a-z A-Z | /usr/bin/cut -f4 -d'-'`
HOST=`hostname | tr a-z A-Z | /usr/bin/cut -f3 -d'-'`


echo "10.10.10.13:/usr/local/epics-nfs       /usr/local/epics-nfs    nfs     defaults        0       0" >> /etc/fstab
echo "10.10.10.13:/usr/local/setup-bl/$BL/C$LOC-$HOST/epics       /usr/local/epics    nfs     defaults        0       0" >> /etc/fstab

mount -a

cp files/epics.sh /etc/profile.d

echo "/usr/local/epics/base/lib/linux-x86_64" > /etc/ld.so.conf.d/epics.conf
echo "/usr/local/epics-nfs/lib/crio-libs/2019_12_12_01/lib" >> /etc/ld.so.conf.d/epics.conf
ldconfig

. /etc/profile.d/epics.sh

cp files/fstab /etc/network/if-up.d/.

# umount nfs partitions before stop server (this prevent bug on reboot/shutdown)
cp files/K19umount /etc/rc6.d/
cp files/K19umount /etc/rc0.d/
echo "-------------DONE SETTING UP NFS---------------"
echo "rebooting..."
reboot

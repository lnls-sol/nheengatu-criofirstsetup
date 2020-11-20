#!/bin/bash

USER=SOL

reboot () { echo 'Reboot? (y/n)' && read x && [[ "$x" == "y" ]] && /sbin/reboot; }

if [ -z $1 ]
    then
    echo "Wrong number of inputs. usage: ./crioFirstSetup.sh <Active Directory enabled user>"
    exit  
else
    ADUSER=$1
#    echo $ADUSER
fi


# Check firmware if updated. 
if [ `uname -r` != "4.14.146-rt67-cg-8.0.0f1-x64-139" ] 
    then
        echo "Kernel was not updated to 4.14.146-rt67-cg-8.0.0f1-x64-139. Please update firmware from NI-MAX."
        exit
else
	echo "Found up-to-date firmware version. continuing..."
fi

# Print repositories 2019
cat /etc/opkg/base-feeds.conf

#Update and install useful stuff
opkg update
opkg install nfs-utils-client git vim rsync python3 screen ntpdate




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
cp files/iocsstart /etc/init.d
cp files/init-functions /etc/init.d
cp files/iocs /bin/
ln -s /etc/init.d/iocsstart /etc/rc2.d/S99iocsstart
ln -s /etc/init.d/iocsstart /etc/rc3.d/S99iocsstart
ln -s /etc/init.d/iocsstart /etc/rc4.d/S99iocsstart
ln -s /etc/init.d/iocsstart /etc/rc5.d/S99iocsstart
echo "------------DONE SETTING UP IOCS SCRIPT---------------"
echo "..."
echo "-------------SETTING UP AutoSave folder ---------------"
mkdir -p /opt/autosave
chmod 777 /opt/autosave
echo "..."
echo "-------------SETTING UP NFS & EPICS ---------------"
echo "..."
mkdir /usr/local/epics
mkdir /usr/local/epics-nfs

# Hostname example: s-mnc-rio01-b
#
# s:      short for Lnls
# mnc:    short for MANACA beamline
# b:      hutch B
# rio01:  CompactRIO #01


BL=`hostname | tr a-z A-Z | /usr/bin/cut -f2 -d'-'`
LOC=`hostname | tr a-z A-Z | /usr/bin/cut -f3 -d'-'`
HOST=`hostname | tr a-z A-Z | /usr/bin/cut -f4 -d'-'`


echo "10.10.10.13:/usr/local/epics-nfs       /usr/local/epics-nfs    nfs     defaults        0       0" >> /etc/fstab
echo "10.10.10.13:/usr/local/setup-bl/$BL/$LOC-$HOST/epics       /usr/local/epics    nfs     defaults        0       0" >> /etc/fstab

cp files/fstab /etc/network/if-up.d/.

mount -a

cp files/epics.sh /etc/profile.d
echo "/usr/local/epics/base/lib/linux-x86_64" > /etc/ld.so.conf.d/epics.conf
echo "/usr/local/epics-nfs/lib/crio-libs/2020_08_21_01/lib" >> /etc/ld.so.conf.d/epics.conf
ldconfig

. /etc/profile.d/epics.sh


# umount nfs partitions before stop server (this prevent bug on reboot/shutdown)
cp files/umountnfs /etc/init.d/
ln -s /etc/init.d/umountnfs /etc/rc6.d/K01umountnfs
ln -s /etc/init.d/umountnfs /etc/rc1.d/K01umountnfs
ln -s /etc/init.d/umountnfs /etc/rc0.d/K01umountnfs



echo "-------------Installing recsync script---------------"
cp files/iocsd.py /usr/bin
cp files/iocsd /etc/init.d/
ln -s /etc/init.d/iocsd /etc/rc2.d/S99iocsd
ln -s /etc/init.d/iocsd /etc/rc3.d/S99iocsd
ln -s /etc/init.d/iocsd /etc/rc4.d/S99iocsd
ln -s /etc/init.d/iocsd /etc/rc5.d/S99iocsd


echo "-------------Fixing date time ---------------"
rm /etc/natinst/share/localtime
ln -s /usr/share/zoneinfo/Etc/GMT+3 /etc/natinst/share/localtime
ntpdate ntp.cnpem.br

opkg install ntp ntp-utils 
sed -i 's/server 0.natinst.pool.ntp.org//g' /etc/ntp.conf
sed -i 's/server 1.natinst.pool.ntp.org//g' /etc/ntp.conf
sed -i 's/server 2.natinst.pool.ntp.org//g' /etc/ntp.conf
sed -i 's/server 3.natinst.pool.ntp.org//g' /etc/ntp.conf
echo "server ntp.cnpem.br" >> /etc/ntp.conf
ntpq -p

hwclock -w

reboot

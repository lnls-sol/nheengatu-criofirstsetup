#!/bin/bash

CRIOLOC=$1
CRIONAME=$2
CRIOIOCPATH=$3

if [ -z $CRIONAME ] || [ -z $CRIOIOCPATH ] || [ -z $CRIOLOC ]
    then
        echo "CRIO chassi name postfix or latest CRIO IOC folder name not inserted."
        echo "usage: ./crioSetupBlFolders.sh <CRIO LOCATION> <CRIO POSTFIX> <CRIO IOC FOLDER NAME>"
        echo "example: ./crioSetupBlFolder.sh A CRIO06 2019_12_12_01"
        exit
fi

if [ ! -d /usr/local/epics-nfs/apps/R3.15.6/crio-ioc/$CRIOIOCPATH ]
    then
        echo "WARNING: Directory /usr/local/epics-nfs/apps/R3.15.6/crio-ioc/$CRIOIOCPATH does not exist."
fi

mkdir -p "$CRIOLOC-$CRIONAME"
cd "$CRIOLOC-$CRIONAME"
mkdir -p epics/apps/config 
cd epics
ln -s /usr/local/epics-nfs/base/R3.15.6 base
cd apps
ln -s /usr/local/epics-nfs/apps/R3.15.6/crio-ioc/$CRIOIOCPATH crio-ioc

cat << 'EOF' >   config/crio-ioc.cmd
#!/usr/local/epics/apps/crio-ioc/bin/linux-x86_64/CRIO


epicsEnvSet("TOP","/usr/local/epics/apps/crio-ioc")
epicsEnvSet("EPICS_BASE","/usr/local/epics-nfs/base/R3.15.6")
epicsEnvSet("IOC","iocCRIO")
epicsEnvSet("CONFIG","/usr/local/epics/apps/config/crio-ioc")
epicsEnvSet("AUTOSAVE","/opt/autosave")
epicsEnvSet("RECCASTER", "/usr/local/epics-nfs/apps/recsync/1.4_epics_3.15/client")

cd ${TOP}

## Register all support components
dbLoadDatabase "dbd/CRIO.dbd"
CRIO_registerRecordDeviceDriver pdbbase

#Init recSync
< "$(CONFIG)/init-recsync.cmd"


set_requestfile_path($(CONFIG))
set_savefile_path($(AUTOSAVE))
set_pass1_restoreFile("crioioc.sav", "")

crioSupSetup("${CONFIG}/cfg.ini" , 1)

## Load record instances
cd ${TOP}/iocBoot/${IOC}

dbLoadTemplate "${CONFIG}/bi.db.sub"
dbLoadTemplate "${CONFIG}/bo.db.sub"
dbLoadTemplate "${CONFIG}/ai.db.sub"
dbLoadTemplate "${CONFIG}/ao.db.sub"
dbLoadTemplate "${CONFIG}/scaler.db.sub"
dbLoadTemplate "${CONFIG}/waveform.db.sub"
dbLoadTemplate "${CONFIG}/mbbi.db.sub"
dbLoadTemplate "${CONFIG}/mbbo.db.sub"
iocInit

#Set initial value to a PV
< "$(CONFIG)/init-pv.cmd"

create_monitor_set("crioioc.req", 1, "")

dbl

EOF

chmod 755 config/crio-ioc.cmd

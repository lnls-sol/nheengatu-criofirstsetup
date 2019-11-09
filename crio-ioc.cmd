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

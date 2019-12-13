#!/bin/bash

CRIOLOC=$1
CRIONAME=$2
CRIOIOCPATH=$3

if [ -z $CRIONAME ] || [ -z $CRIOIOCPATH ] || [ -z $CRIOLOC ]
    then
        echo "CRIO chassi name postfix or latest CRIO IOC folder name not inserted."
        echo "usage: ./crioSetupBlFolders.sh <CRIO LOCATION> <CRIO POSTFIX> <CRIO IOC FOLDER NAME>"
        exit
fi

if [ ! -d /usr/local/epics-nfs/apps/R3.15.6/crio-ioc/$CRIOIOCPATH ]
    then
        echo "WARNING: Directory /usr/local/epics-nfs/apps/crio-ioc/$CRIOIOCPATH does not exist."
fi

mkdir -p "$CRIOLOC-$CRIONAME"
cd "$CRIOLOC-$CRIONAME"
mkdir -p epics/apps/config 
cd epics
ln -s /usr/local/epics-nfs/base/R3.15.6 base
cd apps
ln -s /usr/local/epics-nfs/apps/R3.15.6/crio-ioc/$CRIOIOCPATH crio-ioc
cp ../../../crio-ioc.cmd config/.

# Nheengatu CRIO setup

This project contains several scripts that prepare the compactRIO for running the IOC. Our setup requires NFS. More information can be found [here](https://github.com/lnls-sol/project-nheengatu/tree/master/docs).

## crioFirstSetup.sh

Run this script to setup your cleanly formatted CRIO and creates a newuser with sudo.

## Run

    $ crioFirstSetup.sh


# crioSetupBlFolders

Run this script to automatically generated CRIO NFS folder heirarchy. After that
you will just need to copy the crio-ioc config folder.

## Run

    $ ./crioSetupBlFolders.sh <CRIO LOCATION> <CRIO POSTFIX> <CRIO IOC FOLDER NAME>

## Example

    $ ./crioSetupBlFolders.sh A CRIO06 2021_02_15_01

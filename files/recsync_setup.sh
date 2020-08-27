#/bin/sh

cp files/iocsd.py /usr/bin
cp files/iocsd /etc/init.d/
ln -s /etc/init.d/iocsd /etc/rc2.d/S99iocsd
ln -s /etc/init.d/iocsd /etc/rc3.d/S99iocsd
ln -s /etc/init.d/iocsd /etc/rc4.d/S99iocsd
ln -s /etc/init.d/iocsd /etc/rc5.d/S99iocsd


screen -dm iocsd.py



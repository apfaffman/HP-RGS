#!/bin/bash

echo -e "****************************\n********* WARNING! *********\n****************************\nREBOOT REQUIRED. RUN AS ROOT.\nThis creates a new local user ('rgs'), configures audio for RGS, and modifies the following files: \n* /etc/opt/hpremote/rgsenderconfig \n* /etc/pam.d/rgsender \n* /etc/X11/xorg.conf \n* /etc/sysconfig/modules/rgs-snd-aloop.modules \nBackups will be saved to /root/rgs.old"

read -rsn1 -p "Press any key to proceed or 'ctrl-C' to cancel.";echo

## variables
rgs=/etc/opt/hpremote/rgsender/
pam=/etc/pam.d/
xorg=/etc/X11/
backup=/root/rgs.old
check=/etc/opt/hpremote/rgsender/rgsenderconfig

## root check
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." 
   exit 1
fi

## meat n potatoes
if test -f "$check"; then

    ## new user
    adduser rgs
    echo rgs | passwd rgs --stdin

    ## create cfg backup directory
    mkdir /root/rgs.old

    ## /etc/opt/hpremote/rgsender/rgsenderconfig
    cp  $rgs/rgsenderconfig $backup/rgsenderconfig.old
    sed -i '/Rgsender.Collaboration.AlwaysAcceptCollaborators/c Rgsender.Collaboration.AlwaysAcceptCollaborators=1' $rgs
    sed -i '/\Rgsender.Collaboration.AlwaysAcceptCollaborators/a Rgsender.Collaboration.AlwaysEnableIo=1' $rgs
    sed -i '/Rgsender.Network.HPVelocity.Enabled/c \Rgsender.Network.HPVelocity.Enabled=0' $rgs
    sed -i '/Rgsender.Clipboard.IsEnabled/c \Rgsender.Clipboard.IsEnabled=1' $rgs
    sed -i '/Rgsender.IsDisconnectOnLogoutEnabled/c \Rgsender.IsDisconnectOnLogoutEnabled=0' $rgs

    ## /etc/pam.d/rgsender
    cp $pam/rgsender $backup/rgsender.old
    echo "session  include  password-auth" >> $pam

    ## /etc/X11/xorg.conf
    cp $xorg/xorg.conf $backup/xorg.conf.old
    sed -i '/\"Module"/a Load "rge"' $xorg

    ## configure alsa audio -- this portion copied directly from HP's alsa setup script: /opt/hpremote/rgsender/audio/rg_alsa_config.sh
    printf '%s\n\n%s\n' '#!/bin/sh' 'modprobe snd-aloop >/dev/null 2>&1' >> /etc/sysconfig/modules/rgs-snd-aloop.modules
    chmod 755 /etc/sysconfig/modules/rgs-snd-aloop.modules
    sed -i '/Rgsender.Audio.Linux.DeviceName/c \Rgsender.Audio.Linux.DeviceName=plughw:Loopback,1' /etc/opt/hpremote/rgsender/rgsenderconfig
    sed -i '/Rgsender.Audio.Linux.RecorderApi/c \Rgsender.Audio.Linux.RecorderApi=alsa' /etc/opt/hpremote/rgsender/rgsenderconfig

else
    echo "RGS is not installed.\nRun the HP RGS install script, then re-run this script."
    exit 1
fi

echo -e "********************************************************\nConfigs updated. Old configs backed up to /root/rgs.old.\n********************************************************"

read -rsn1 -p "Press any key to reboot, CTRL-C to cancel.";echo
reboot
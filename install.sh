#!/bin/bash
# This Guacamole Server installation is only for Ubuntu 22.04 and Respbian OS!

# check logs by error's 
# tail -f /log/messages 
# tail -f /var/log/syslog 
# tail -f /var/log/tomcat*/*.out 
# tail -f /var/log/mysql/*.log

# check if user has read the Script
while true; do

read -p "This Script works only with Ubuntu Server 22.04 or Respbian OS, Do you want to proceed? (y/n) " yn

case $yn in 
	[yY] ) echo ok, we will proceed;
		break;;
	[nN] ) echo exiting...;
		exit;;
	* ) echo invalid response;;
esac

done

echo "thanks for using this script :)"

sleep 2

# check if system is updated
echo "checking updates and upgrades"
if ((updates == 0)); then
    echo "No updates are available"
else
    echo "update and upgrade your system first"
fi

# check if user is root or sudo  
if ! [ $( id -u ) = 0 ]; then
    echo "Please run this Script as sudo or root" 1>&2
    exit 1
fi

# Version number of Guacmaole to install
GUACVERSION=1.5.0

# Not all Distros have the same packages
source /etc/os-release
if [[ "${NAME}" == "Ubuntu" ]]; then
    #Add the "universe" repo don't update
    echo "you have installed $NAME"
    # Set package names depending on Version
    JPEGTURBO="libjpeg-turbo8-dev"
    if [[ "${NAME}" == "22.04" ]]
    then
        LIBPNG="libpng-dev"
    fi
elif [[ "${NAME}" == "Raspbian GNU/Linux" ]];then
    JPEGTURBO="libjpeg62-turbo-dev"
    fi
else
    echo "Ubuntu or Raspbian Only"
    exit 1
fi

# Install Server Features
apt-get -y install build-essential libcairo2-dev ${JPEGTURBO} ${LIBPNG} libavcodec-dev libavformat-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev \
libtelnet-dev libvncserver-dev libwebsockets-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev

# if apt fails to run completly the rest of this isn't going to work!
if [ $? !=0 ]; then
    echo "apt get failed to install all required dependencies."
    exit 1
fi


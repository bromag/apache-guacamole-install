#!/bin/bash
# This Guacamole Server installation is only for Ubuntu 22.04 and Respbian OS!

# check logs by error's 
# tail -f /log/messages 
# tail -f /var/log/syslog 
# tail -f /var/log/tomcat*/*.out 
# tail -f /var/log/mysql/*.log

# Colors for output
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Colo

# Version number of Guacamole to install
# Homepage ~ https://guacamole.apache.org/releases/
GUACVERSION="1.5.0"

# Log Location
LOG="/tmp/guacamole_${GUACVERSION}_build.log"

# Ip address from host
ip=$(hostname -I)
my_ip=${ip%% *}

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

echo "Installing tomcat9 and mariadb-server"
sleep 2
apt-get install -y make tomcat9 mariadb-server
sleep 2
echo can check if Apache Tomcat is installed correctly: http://$my_ip:8080
sleep 3

# Set preferred download server from the Apache CDN
SERVER="http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUACVERSION}"
echo -e "${BLUE}Downloading files...${NC}"

# Download Guacamole Server
wget -q --show-progress -O guacamole-server-${GUACVERSION}.tar.gz ${SERVER}/source/guacamole-server-${GUACVERSION}.tar.gz
if [ $? -ne 0 ];then
    echo -e "${RED}Failes to download guacamole-server-${GUACVERSION}.tar.gz" 1>&2
    echo -e "${SERVER}/source/guacamole-server-${GUACVERSION}.tar.gz${NC}"
    exit 1
else
    # Extract Guacmaole Files
    tar -xzf guacamole-server-${GUACVERSION}.tar.gz
fi
echo -e "${GREEN}Downloaded guacamole-server-${GUACVERSION}.tar.gz${NC}"

# Download Guacamole Client
if [$? -ne 0 ];then
    echo -e "${RED}Failes to download guacamole-${GUACVERSION}.war" 1>&2
    echo -e "${SERVER}/binary/guacamole-${GUACVERSION}.war${NC}"
    exit 1
fi
echo -e "${GREEN}Downloaded guacamole-${GUACVERSION}.war${NC}"
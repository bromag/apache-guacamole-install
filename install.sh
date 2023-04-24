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

# Mysql-connector-java
MCJVER="8.0.32"

# Log Location
LOG="/tmp/guacamole_${GUACVERSION}_build.log"

# Ip address from host
ip=$(hostname -I)
my_ip=${ip%% *}

# MySQL Port
mysqlPort="3306"

# guacd Port
guacdPort="4822"

# MySQL User
guacUser="guacamole"

# MySQL DB
guacDb="guacamole"

# Generate Passwort for guacamole Database
dbpw=$(openssl rand -hex 8)

# Store dbpw Passwort
touch /usr/src/dbpw.txt
echo "$dbpw" > /usr/src/dbpw.txt

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
if [ $? !=0 ]; then
    echo "apt get failed to install Tomcat9 and Mariadb-server."
    exit 1
fi
echo "${Yellow}You can check if Apache Tomcat is installed correctly: http://$my_ip:8080${NC}"
sleep 3

# Set preferred download server from the Apache CDN
SERVER="http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUACVERSION}"
echo -e "${BLUE}Downloading files...${NC}"

# Download Guacamole Server
wget -q --show-progress -O guacamole-server-${GUACVERSION}.tar.gz ${SERVER}/source/guacamole-server-${GUACVERSION}.tar.gz
if [ $? -ne 0 ]; then
    echo -e "${RED}Failes to download guacamole-server-${GUACVERSION}.tar.gz" 1>&2
    echo -e "${SERVER}/source/guacamole-server-${GUACVERSION}.tar.gz${NC}"
    exit 1
else
    # Extract Guacmaole Files
    tar -xzf guacamole-server-${GUACVERSION}.tar.gz
fi
echo -e "${GREEN}Downloaded guacamole-server-${GUACVERSION}.tar.gz${NC}"

# Download Guacamole Client
if [$? -ne 0 ]; then
    echo -e "${RED}Failes to download guacamole-${GUACVERSION}.war" 1>&2
    echo -e "${SERVER}/binary/guacamole-${GUACVERSION}.war${NC}"
    exit 1
fi
echo -e "${GREEN}Downloaded guacamole-${GUACVERSION}.war${NC}"

# Download Guacamole authentication extensions (Database)
wget -q --show-progress -O guacamole-auth-jdbc-${GUACVERSION}.tar.gz ${SERVER}/binary/guacamole-auth-jdbc-${GUACVERSION}.tar.gz
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download guacamole-auth-jdbc-${GUACVERSION}.tar.gz" 1>&2
    echo -e "${SERVER}/binary/guacamole-auth-jdbc-${GUACVERSION}.tar.gz"
    exit 1
else
    tar -xzf guacamole-auth-jdbc-${GUACVERSION}.tar.gz
fi
echo -e "${GREEN}Downloaded guacamole-auth-jdbc-${GUACVERSION}.tar.gz${NC}"

wget -q --show-progress -O mysql-connector-java-${MCJVER}.tar.gz https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MCJVER}.tar.gz
if [ $! -ne 0 ]; then
    echo -e "${RED}Failed to Dowload mysql-connector-java-${MCJVER}" 1>&2
    echo -e "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MCJVER}.tar.gz${NC}"
    exit 1
else
    tar -xzf mysql-connector-java-${MCJVER}.tar.gz
fi
echo -e "${GREEN}Dowloaded mysql-connector-java-${MCJVER}.tar.gz${NC}"

# Make directories
rm -rf /etc/guacamole/lib/
rm -rf /etc/guacamole/extensions/
mkdir -p /etc/guacamole/lib/
mkdir -p /etc/guacamole/extensions/
echo GUACAMOLE_HOME=\"/etc/guacamole\" >> /etc/environment
cp /usr/src/guacamole-$GUACVERSION.war /var/lib/tomcat9/webapps/guacamole.war
systemctl enable guacd.service
systemctl start guacd.service

systemctl restart tomcat9.service
if [ !$ -ne 0 ]; then
    echo -e "${RED} tomcat failed to start${NC}" 1>&2
    exit 1
else
    echo -e "${GREEN}OK${NC}"
fi
# Start at boot
systemctl enable tomcat9.service
echo

# Fix RDP Connection error
adduser guacd --disabled-password --disabled-login --gecos ""
sed -i -e 24c"\#User=daemon" /etc/systemd/system/guacd.service
sed -i -e 25i"User=guacd" /etc/systemd/system/guacd.service
systemctl daemon-reload
systemctl restart guacd.service

# Fix freerdp
mkdir -p /usr/sbin/.config/freerdp
chown daemon:daemon /usr/sbin/.config/freerdp

# install guacd (Guacamole-server)
cd guacamole-server-${GUACVERSION}/

echo -e "${BLUE}Configuring Guacamole-Server. This might take a minute...${NC}"
./configure --with-systemd-dir=/etc/systemd/system  &>> ${LOG}
if [ $? -ne 0 ]; then
    echo "Failed to configure guacamole-server"
    echo "Trying agaun with --enable-allow-freerdp-snapshots"
    ./configure --with-systemd-dir=/etc/systemd/system --enable-allow-freerdp-snapshots
    if [$? -ne 0 ]; then
        echo "Failed to configure guacamole-server - again"
        exit
    fi
else
    echo -e "${GREEN}OK${NC}" 
fi

echo -e "${BLUE}Running make on Guacamole-server. This might take a frew minutes...${NC}"
make $>> ${LOG}
if [ $? -ne 0 ]; then
    echo -e "${RED}Failes. See ${LOG}${NC}" 1>&2
    exit 1
else
    echo -e "${GREEN}OK${NC}"
fi

echo -e "${BLUE}Running make install on Guacamole-Server...${NC}"
make install $>> ${LOG}
if [ $? -ne 0 ]; then
    echo -e "${RED}Failes. See ${LOG}${NC}" 1>&2
    exit 1
else
    echo -e "${GREEN}OK${NC}"
fi
ldconfig
echo

# Move files to correct locations (guacamole-client & Guacamole authentication extensions)
cd ..
mv -f guacamole-${GUACVERSION}.war /etc/guacamole/guacamole.war
mv -f guacamole-auth-jdbc-${GUACVERSION}/mysql/guacamole-auth-jdbc-mysql-${GUACVERSION}.jar /etc/guacamole/extensions/
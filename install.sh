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

# Ip address from host
ip=$(hostname -I)
my_ip=${ip%% *}
if [ $? -eq 0 ]; then
    echo -e "${CYAN}IP Adress found${NC}"
else
    echo -e "${RED}No ip address found${NC}"
fi

# Check ethernet connection
wget -q --tries=10 --timeout=40 --spider http://google.com
if [ $? -eq 0 ]; then
    echo -e "${GREEN}You have ethernet connection"
else
    echo -e "${RED}You have no ethernet connection${NC}"
    exit 1
fi

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

# check if user is root or sudo  
if ! [ $( id -u ) = 0 ]; then
    echo "Please run this Script as sudo or root" 1>&2
    exit 1
fi

# check if system is updated
echo -e "${GREEN}Checking for updates and upgrades..."
sleep 3
sudo apt update > /dev/null 2>&1
updates=$(sudo apt list --upgradable | wc -l)
if ((updates == 0)); then
    echo -e "No updates are available"
else
    echo -e "${GREEN}Updates are available${NC}"
    echo -e "${YELLOW}Performing system update...${NC}"
    sudo apt upgrade -y > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}System update completed successfully${NC}"
        echo -e "${YELLOW}Performing system upgrade...${NC}"
        sudo apt dist-upgrade -y > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}System upgrade completed successfully"
        else
            echo -e "${RED}System upgrade failed. Exiting...${NC}"
            exit 1
        fi
    else
        echo -e "${RED}System update failed. Exiting...${NC}"
        exit 1
    fi
fi

# check if user has rebootet machine after update and upgrade
while true; do
read -p "If the Script has found update and upgrade please make sure to reboot your system, or the installation will not complete correctly! Do you want to proceed? (y/n) " yn
case $yn in 
	[yY] ) echo ok, we will proceed;
		break;;
	[nN] ) echo exiting...;
		exit;;
	* ) echo invalid response;;
esac
done
sleep 2


# Store dbpw Passwort
touch /usr/src/dbpw.txt
echo "$dbpw" > /usr/src/dbpw.txt

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
else
    echo "Ubuntu or Raspbian Only"
    exit 1
fi

echo -e "${CYAN}Features are getting installed${NC}"

# Install Server Features
apt install -y libcairo2-dev
apt install -y ${JPEGTURBO}
apt install -y ${LIBPNG} libtool-bin uuid-dev
apt install -y libavcodec-dev libavformat-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libwebsockets-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev

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
echo can check if Apache Tomcat is installed correctly: http://$my_ip:8080
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

# Downloading Guacamole authentication extension DUO
wget -q --show-progress -O guacamole-auth-duo-${GUACVERSION}.tar.gz ${SERVER}/binary/guacamole-auth-duo-${GUACVERSION}.tar.gz
if [ $! -ne 0 ]; then
    echo -e "${RED}Fauled to Download guacamole-auth-duo-${GUACVERSION}.tar.gz" 1>&2
    echo -e "${SERVER}/binary/guacamole-auth-duo-${GUACVERSION}.tar.gz"
    exit 1
else
    tar -xzf guacamole-auth-duo-${GUACVERSION}.tar.gz
fi
echo -e "${GREEN}Downloaded guacamole-auth-duo-${GUACVERSION}.tar.gz${NC}"

# Move Duo Files
if dpkg -s libguac-client-duo0 >/dev/null 2>&1; then
    echo -e "${BLUE}Moving guacamole-auth-duo-${GUACVERSION}.jar (/etc/guacamole/extensions/)...${NC}"
    mv -f guacamole-auth-duo-${GUACVERSION}/guacamole-auth-duo-${GUACVERSION}.jar /etc/guacamole/extensions/
    echo
else
  echo "Apache Guacamole Duo package is not installed"
fi

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


# Create User, Database, and the needed Right's 
mysql -u root -p -e "CREATE USER 'guacamole'@'localhost' IDENTIFIED BY '$dbpw';"
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS guacamole DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -u root -p -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE ON guacamole.* TO 'guacamole'@'localhost' IDENTIFIED BY '$dbpw' WITH GRANT OPTION;"
mysql -u root -p -e "FLUSH PRIVILEGES;"

# Import Guacamole Schema
mysql -uguacamole -p$dbpw guacamole < /usr/src/guacamole-auth-jdbc-$guacver/mysql/schema/001-create-schema.sql
mysql -uguacamole -p$dbpw guacamole < /usr/src/guacamole-auth-jdbc-$guacver/mysql/schema/002-create-admin-user.sql

# Configure guacamole.properties
echo "Configuring guacamole properties, maybe you have to change the hostname in the File!"
sleep 3

rm -f /etc/guacamole/guacamole.properties
touch /etc/guacamole/guacamole.properties

echo "#" >> /etc/guacamole/guacamole.properties
echo "# Hostname and Guacamole server Port" >> /etc/guacamole/guacamole.properties
echo "#" >> /etc/guacamole/guacamole.properties
echo "guacd-hostname: ${my_ip}" >> /etc/guacamole/guacamole.properties
echo "guacd-port: ${guacdPort}" >> /etc/guacamole/guacamole.properties
echo "# MySQL properties" >> /etc/guacamole/guacamole.properties
echo "#" >> /etc/guacamole/guacamole.properties
echo "#" >> /etc/guacamole/guacamole.properties
echo "mysql-hostname: ${my_ip}" >> /etc/guacamole/guacamole.properties
echo "mysql-port: ${mysqlPort}" >> /etc/guacamole/guacamole.properties
echo "mysql-database: ${guacDb}" >> /etc/guacamole/guacamole.properties
echo "mysql-username: ${guacUser}" >> /etc/guacamole/guacamole.properties
echo "mysql-password: ${dbpw}" >> /etc/guacamole/guacamole.properties

# DUO Configuration Settings but comment them out
echo "#" >> /etc/guacamole/guacamole.properties
echo "# DUO Config " >> /etc/guacamole/guacamole.properties
echo "#" >> /etc/guacamole/guacamole.properties
echo "# duo-api-hostname: " >> /etc/guacamole/guacamole.properties
echo "# duo-integration-key: " >> /etc/guacamole/guacamole.properties
echo "# duo-application-key: " >> /etc/guacamole/guacamole.properties
echo -e "${Yellow}Duo is installed, it will need to be configured via guacamole.properties${NC}"

# Handling error: The server time zone value ‚CEST‘ is unrecognized or represents more than one time zone
# Make a backup of the original 50-server.cnf file
cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.original

# Run the mysql_tzinfo_to_sql command and pipe the output to the mysql command to configure the timezone
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql

# Add the timezone configuration to the 50-server.cnf file
sed -i '30 i\# Timezone' /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i '31 i\default_time_zone=Europe/Berlin' /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i '32 i\ ' /etc/mysql/mariadb.conf.d/50-server.cnf

# Restart the MariaDB service
systemctl restart mariadb.service
if [ $! -ne 0 ]; then
    echo -e "${RED}Failed to restart mariadb.service${NC}"
else
    echo -e "${GREEN}OK${NC}"
fi

#Done
echo -e "{BLUE}Installation Complete\n Visit: http://${my_ip}:8080/guacamole/\n- Default login (username/password): guacadmin/guacadmin\n***Be sure to change the password***.${NC}"
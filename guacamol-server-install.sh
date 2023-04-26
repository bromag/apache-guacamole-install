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
GUACVER="1.5.0"
echo -e "${GUACVER}"

# Mysql-connector-java
MCJVER="8.0.32"


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
read -p "This Script works only with Ubuntu Server 22.04 Do you want to proceed? (y/n) " yn
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


apt install -y libcairo2-dev
apt install -y libjpeg-turbo8-dev
apt install -y libpng-dev libtool-bin uuid-dev
apt install -y libavcodec-dev libavformat-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libwebsockets-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev

# if apt fails to run completly the rest of this isn't going to work!
if [ $? !=0 ]; then
    echo "apt get failed to install all required dependencies."
    exit 1
else
    echo "All required dependencies are installed."
fi

apt install -y make tomcat9 mariadb-server
if [ $? !=0 ]; then
    echo "apt get failed to install Tomcat9 and Mariadb-server."
    exit 1
else
    echo "Tomcat and mariadb-server are installed"
fi

wget -q --show-progress --trust-server-names "https://apache.org/dyn/closer.cgi?action=download&filename=guacamole/$GUACVER/source/guacamole-server-$GUACVER.tar.gz" -O /usr/src/guacamole-server-$GUACVER.tar.gz
if [ $? -ne 0 ]; then
    echo -e "${RED}Failes to download guacamole-server-${GUACVER}.tar.gz"
    exit 1
else
    # Extract Guacmaole Files
    tar -xvzf guacamole-server-${GUACVER}.tar.gz -C /usr/src/
fi
echo -e "${GREEN}Downloaded guacamole-server-${GUACVERSION}.tar.gz${NC}"


wget -q --show-progress --trust-server-names "https://apache.org/dyn/closer.cgi?action=download&filename=guacamole/$GUACVER/binary/guacamole-$GUACVER.war" -O /usr/src/guacamole-$GUACVER.war
if [ $! -ne 0 ]; then
    echo -e "${RED}Failes to download guacamole-$GUACVER.war${NC}"
    exit 1
else
    echo -e "${GREEN}Downloaded guacamole-$GUACVER.war${NC}"
fi

cd /usr/src/guacamole-server-$GUACVER
./configure --with-systemd-dir=/etc/systemd/system
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to configure guacamole-server${NC}"
else
    echo -e "${GREEN}OK${NC}"
fi

echo -e "${CYAN}Running make on Guacamole-Server...${NC}"
make
if [ $? -ne 0 ]; then
    echo "${RED}Failed${NC}"
else
    echo "${GREEN}OK${NC}"
fi

echo -e "${CYAN}Running make install on Guacamole-Server...${NC}"
make install
if [ $? -ne 0 ]; then
    echo "${RED}Failed${NC}"
else
    echo "${GREEN}OK${NC}"
fi
ldconfig

mkdir /etc/guacamole
mkdir /etc/guacamole/extensions
mkdir /etc/guacamole/lib
echo GUACAMOLE_HOME=\"/etc/guacamole\" >> /etc/environment

cp /usr/src/guacamole-$GUACVER.war /var/lib/tomcat9/webapps/guacamole.war

systemctl enable guacd.service
systemctl start guacd.service
systemctl status guacd.service

systemctl restart tomcat9.service

adduser guacd --disabled-password --disabled-login --gecos ""
sed -i -e 24c"\#User=daemon" /etc/systemd/system/guacd.service
sed -i -e 25i"User=guacd" /etc/systemd/system/guacd.service
systemctl daemon-reload
systemctl restart guacd.service

wget -q --show-progress --trust-server-names "https://apache.org/dyn/closer.cgi?action=download&filename=guacamole/$GUACVER/binary/guacamole-auth-jdbc-$GUACVER.tar.gz" -O /usr/src/guacamole-auth-jdbc-$GUACVER.tar.gz
if [ $! -ne 0 ]; then
    echo -e "${RED}Failes to download guacamole-auth-jdbc-$GUACVER.tar.gz${NC}"
    exit 1
else
    echo -e "${GREEN}guacamole-auth-jdbc-$GUACVER.tar.gz${NC}"
    tar xvzf /usr/src/guacamole-auth-jdbc-$GUACVER.tar.gz -C /usr/src/
fi

wget -q --show-progress "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-MCJVER.tar.gz" -O /usr/src/mysql-connector-java-$MCJVER.tar.gz
if [ $! -ne 0 ]; then
    echo -e "${RED}Failes to download mysql-connector-java-$MCJVER.tar.gz${NC}"
    exit 1
else
    echo -e "${GREEN}mysql-connector-java-$MCJVER.tar.gz${NC}"
    tar xvzf /usr/src/guacamole-auth-jdbc-$GUACVER.tar.gz -C /usr/src/
fi

cp /usr/src/guacamole-auth-jdbc-$GUACVER/mysql/guacamole-auth-jdbc-mysql-$GUACVER.jar /etc/guacamole/extensions/
cp /usr/src/mysql-connector-j-$MCJVER/mysql-connector-j-$MCJVER.jar /etc/guacamole/lib/


mysql -u root -p -e "CREATE USER 'guacamole'@'localhost' IDENTIFIED BY '$dbpw';"
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS guacamole DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -u root -p -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE ON guacamole.* TO 'guacamole'@'localhost' IDENTIFIED BY '$dbpw' WITH GRANT OPTION;"
mysql -u root -p -e "FLUSH PRIVILEGES;"

mysql -uguacamole -p$dbpw guacamole < /usr/src/guacamole-auth-jdbc-$GUACVER/mysql/schema/001-create-schema.sql
mysql -uguacamole -p$dbpw guacamole < /usr/src/guacamole-auth-jdbc-$GUACVER/mysql/schema/002-create-admin-user.sql

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

cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.orginal

mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql
sed -i '30 i\# Timezone' /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i '31 i\default_time_zone=Europe/Berlin' /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i '32 i\ ' /etc/mysql/mariadb.conf.d/50-server.cnf

systemctl restart mariadb.service
if [ $! -ne 0 ]; then
    echo -e "${RED}Failed to restart mariadb.service${NC}"
else
    echo -e "${GREEN}OK${NC}"
fi

systemctl restart tomcat9.service
if [ $! -ne 0 ]; then
    echo -e "${RED}Failed to restart mariadb.service${NC}"
else
    echo -e "${GREEN}OK${NC}"
fi

#Done
echo -e "{BLUE}Installation Complete\n Visit: http://${my_ip}:8080/guacamole/\n- Default login (username/password): guacadmin/guacadmin\n***Be sure to change the password***.${NC}"
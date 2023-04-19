#!/bash/sh
# check logs by error's 
# tail -f //log/messages 
# tail -f /var/log/syslog 
# tail -f /var/log/tomcat*/*.out 
# tail -f /var/log/mysql/*.log

# check if user is root or sudo  
if ! [ $( id -u ) = 0 ]; then
    echo "Please run this Script as sudo or root" 1>&2
    exit1
fi
#!/bin/bash


GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'

tput init


saydone() {
	echo -e "${GREEN}DONE"
	tput init
}

check_program_installed() {
	PROG=$1
	if [ $(dpkg -l | grep $PROG |wc -l) -eq 0 ]; then
		echo -e "${RED}"$PROG" is not installed. Installing now..."
		apt install $PROG -y > /dev/null
		saydone
	else
		echo -e "${GREEN}"$PROG" is installed..."
	fi
	tput init
}


######################
### GENERAL FIELDS ###
######################
read -p "Enter cloud URL. eg: cloud.example.com: " SITEURL

if [ -z "$SITEURL" ];
	then	echo -e "${RED}No site url given. Exiting";
		tput init
		exit
fi
##########################
### GENERAL FIELDS END ###
##########################

#######################
### DATABASE FIELDS ###
#######################

read -p "Enter database name. default: nextcloud: " DBNAME
## check for DATABASE NAME ##

if [ -z "$DBNAME" ];
	then	echo -e "${YELLOW}No database name given, using default...";
		tput init
		DBNAME="nextcloud"
		
fi

read -p "Enter database user. default nextcloud_user: " DBUSER
## check for DATABASE USER ##
if [ -z "$DBUSER" ];
	then	echo -e "${YELLOW}No database user given, using default...";
		tput init
		DBUSER="nextcloud_user"
fi

read -p "Enter database password. eg: not12345: " DBPASS
## check for DATABASE PASSWORD ##
if [ -z "$DBPASS" ];
	then	echo "${YELLOW}No database password given, auto generating one...";
		tput init
		DBPASS=$(tr -dc 'A-Za-z0-9!#$()/@' </dev/urandom | head -c 30; echo);
fi

echo -e "\n"
echo -e "${BLUE}*** Databse info ***\n${YELLOW}Database Name: ${WHITE}"$DBNAME"\n${YELLOW}Database User: ${WHITE}"$DBUSER"\n${YELLOW}Database password: ${WHITE}"$DBPASS
echo -e "\n"
tput init

###########################
### DATABASE FIELDS END ###
###########################

check_program_installed "mariadb-server"


#########################
### DATABASE CREATION ###
#########################
echo "Creating Database..."
mysql -u root -e "CREATE DATABASE "$DBNAME
echo "Creating User..."
mysql -e "create user '"$DBUSER"'@'%' identified by '"$DBPASS"';"
echo "Granting privileges..."
mysql -e "grant all privileges on "$DBNAME".* to '"$DBUSER"'@'%' identified by '"$DBPASS"';"
saydone

echo "Installing PHP modules"
apt install php-{ctype,curl,dom,fileinfo,gd,json,mbstring,posix,simplexml,xmlreader,xmlwriter,zip,fpm,mysql} -y > /dev/null
saydone

#############################
### DATABASE CREATION END ###
#############################



### Modify nginx configuration ###
echo "Creating nginx configuration..."
cp nginx_config_http_only nextcloud.conf
sed -i 's/cloud.example.com/'$SITEURL'/g' nextcloud.conf
mv nextcloud.conf /etc/nginx/sites-enabled
saydone

### Download Latest Nextcloud version ###
echo "Downloading latest nextcloud ..."
wget https://download.nextcloud.com/server/releases/latest.zip
echo "Installing to /var/www/nextcloud"
unzip latest.zip > /dev/null
cp -r nextcloud /var/www
chown -R www-data:www-data /var/www/nextcloud
saydone

echo "Cleaning files"
rm -rf ./nextcloud
rm latest.zip
saydone

echo "Restarting WEB Server"
systemctl restart nginx
saydone

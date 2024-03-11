#!/bin/bash


source ./utils.sh

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'



check_root


######################
### GENERAL FIELDS ###
######################
read -p "Enter cloud URL. eg: cloud.example.com: " SITEURL

if [ -z "$SITEURL" ]; then
	#echo -e "${RED}No site url given. Exiting";
	error "No site url given. Exiting";
	exit
fi
##########################
### GENERAL FIELDS END ###
##########################

#######################
### DATABASE FIELDS ###
#######################

#check_program_installed "mariadb-server"
check_package mariadb-server

read -p "Enter database name. default: nextcloud: " DBNAME
## check for DATABASE NAME ##

if [ -z "$DBNAME" ]; then
	info "No database name given, using default...";
	DBNAME="nextcloud"
		
fi

read -p "Enter database user. default nextcloud_user: " DBUSER
## check for DATABASE USER ##
if [ -z "$DBUSER" ]; then
	info "No database user given, using default...";
	DBUSER="nextcloud_user"
fi

read -p "Enter database password. eg: not12345: " DBPASS
## check for DATABASE PASSWORD ##
if [ -z "$DBPASS" ]; then
	info "No database password given, auto generating one...";
	DBPASS=$(tr -dc 'A-Za-z0-9!#$()/@' </dev/urandom | head -c 30; echo);
fi


echo -e "\n"
info "*** Databse info ***\n${YELLOW}Database Name: ${NC}"$DBNAME"\n${YELLOW}Database User: ${NC}"$DBUSER"\n${YELLOW}Database password: ${NC}"$DBPASS
echo -e "\n"

###########################
### DATABASE FIELDS END ###
###########################



#########################
### DATABASE CREATION ###
#########################
echo "Creating Database..."
mysql -u root -e "CREATE DATABASE "$DBNAME
echo "Creating User..."
mysql -e "create user '"$DBUSER"'@'%' identified by '"$DBPASS"';"
echo "Granting privileges..."
mysql -e "grant all privileges on "$DBNAME".* to '"$DBUSER"'@'%' identified by '"$DBPASS"';"
ok "Done setting up mysql"

echo "Installing PHP modules"
apt-get install php-{ctype,curl,dom,fileinfo,gd,json,mbstring,posix,simplexml,xmlreader,xmlwriter,zip,fpm,mysql} -y > /dev/null
ok "Installed PHP modules"

#############################
### DATABASE CREATION END ###
#############################



### Modify nginx configuration ###
echo "Creating nginx configuration..."
cp nginx_config_http_only nextcloud.conf
sed -i 's/cloud.example.com/'$SITEURL'/g' nextcloud.conf
mv nextcloud.conf /etc/nginx/sites-enabled
ok "Done"

### Download Latest Nextcloud version ###
echo "Downloading latest nextcloud ..."
wget https://download.nextcloud.com/server/releases/latest.zip &> /dev/null
echo "Installing to /var/www/nextcloud"
unzip latest.zip > /dev/null &> /dev/null
mkdir /var/www/nextcloud &> /dev/null
cp -r nextcloud /var/www
chown -R www-data:www-data /var/www/nextcloud
ok "Done"

echo "Cleaning files"
rm -rf ./nextcloud
rm latest.zip
ok "Done"

echo "Restarting WEB Server"
systemctl restart nginx
ok "Done"

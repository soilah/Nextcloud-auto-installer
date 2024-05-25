#!/bin/bash


source ./utils.sh

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'


WEB_SERVER_PORT=80
WEB_SERVER_ROOT_PATH="/var/www/nextcloud"
CLOUD_URL=""


print_help() {
	echo ./$(basename $0) [OPTIONS]
	echo -e "\n\tOPTIONS:\n\t-h\t\t\t\t\tshow this help message"
	echo -e "\t-p|--port port\t\t\t\tspecify a custom port for the web server (default 80)"
	echo -e "\t-d|--install-dir directory\t\tspecify a custom installation directory. The 'nextcloud' directory will be appended to that path. For example if '/home/user' is given as path, nextcloud will be installed at /home/user/nextcloud. (default /var/www)"
	echo -e "\t-u|--site-url\t\t\t\tspecify your cloud domain name. Example: cloud.example.com (If not set, user will be asked via prompt)"
}

check_args() {
	# read the options
	options=$(getopt -o hp:d:u: --long help,port:,install-dir:,site-url: -- "$@")
	eval set -- "$options"

	# extract options and their arguments into variables.
	while true ; do
		case "$1" in
		-h|--help)
			print_help ; exit
			;;
		-p|--port)
			if ((1<=$2 && $2<=65535)) then WEB_SERVER_PORT=$2;
			else echo "Invalid port"; exit;
			fi
			shift 2
			;;
		-d|--install-dir)
			if [ "${2: -1}" == "/" ]; then WEB_SERVER_ROOT_PATH="$2nextcloud"; else WEB_SERVER_ROOT_PATH="$2/nextcloud"; fi
			shift 2
			;;
			#if [ -d "$2/ ] then echo "Directory already exists..." 
		-u|--site-url)
			validate="^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.)+[a-zA-Z]{2,}$"
			if [[ "$2" =~ $validate ]]; then CLOUD_URL=$2;
			else echo "Invalid cloud url"; exit;
			fi
			shift 2
			;;
		--) shift; break
			;;
		*) echo "Internal error!" ; exit 1 ;;
		esac
	done
}



check_create() {
	FILENAME=$1
	if [ -f ./$FILENAME ]; then
		error "$FILENAME file exits. Maybe nextcloud needs to be uninstalled?"
		exit
	else
		info "Creating $FILENAME file..."
		touch ./$FILENAME
	fi
}




check_args "$@"
echo INSTALL PATH: $WEB_SERVER_ROOT_PATH
echo WEB PORT: $WEB_SERVER_PORT

check_root
check_create ncvars.env


check_open_port $WEB_SERVER_PORT

check_package nginx
check_package mariadb-server


######################
### GENERAL FIELDS ###
######################
echo $CLOUD_URL
if [ -z "$CLOUD_URL" ]; then
	read -p "Enter cloud URL. eg: cloud.example.com: " CLOUD_URL

	if [ -z "$CLOUD_URL" ]; then
		#echo -e "${RED}No site url given. Exiting";
		error "No site url given. Exiting";
		exit
	fi
else
	echo "Cloud url: $CLOUD_URL"
fi

WEB_SERVER_ROOT_PATH_SED=$(echo $WEB_SERVER_ROOT_PATH | sed -r 's/\//\\\//g')

##########################
### GENERAL FIELDS END ###
##########################

#######################
### DATABASE FIELDS ###
#######################

#check_program_installed "mariadb-server"


read -p "Enter database name. default: nextcloud: " DBNAME
## check for DATABASE NAME ##

if [ -z "$DBNAME" ]; then
	info "No database name given, using default...";
	DBNAME="nextcloud"
	echo "export NC_DBNAME=$DBNAME" >> ./ncvars.env
		
fi

read -p "Enter database user. default nextcloud_user: " DBUSER
## check for DATABASE USER ##
if [ -z "$DBUSER" ]; then
	info "No database user given, using default...";
	DBUSER="nextcloud_user"
	echo "export NC_DBUSER=$DBUSER" >> ./ncvars.env
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
apt-get install php-{ctype,curl,dom,fileinfo,gd,json,mbstring,posix,simplexml,xmlreader,xmlwriter,zip,fpm,mysql} -y &> /dev/null
ok "Installed PHP modules"

#############################
### DATABASE CREATION END ###
#############################



### Modify nginx configuration ###
echo "Creating nginx configuration..."
cp nginx_config_http_only nextcloud.conf
sed -i 's/__CLOUD_URL__/'$CLOUD_URL'/g' nextcloud.conf
sed -i 's/__PORT__/'$WEB_SERVER_PORT'/g' nextcloud.conf
sed -i 's/__WEB_ROOT__/'$WEB_SERVER_ROOT_PATH_SED'/g' nextcloud.conf
mv nextcloud.conf /etc/nginx/sites-enabled
ok "Done"

### Download Latest Nextcloud version ###
echo "Downloading latest nextcloud ..."
wget https://download.nextcloud.com/server/releases/latest.zip &> /dev/null
echo "Installing to $WEB_SERVER_ROOT_PATH"
unzip latest.zip > /dev/null &> /dev/null
mkdir -p $WEB_SERVER_ROOT_PATH &> /dev/null
cp -r nextcloud/* $WEB_SERVER_ROOT_PATH
chown -R www-data:www-data $WEB_SERVER_ROOT_PATH
echo "export NC_INSTALLATION_DIRECTORY=$WEB_SERVER_ROOT_PATH" >> ./ncvars.env
ok "Done"

echo "Cleaning files"
rm -rf ./nextcloud
rm latest.zip
ok "Done"

echo "Restarting WEB Server"
systemctl restart nginx
ok "Done"

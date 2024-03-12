#!/bin/bash

source ./utils.sh
source ./ncvars.env

check_root

info "Removing database $NC_DBNAME"
mysql -u root -e "DROP DATABASE $NC_DBNAME"
info "Removing user $NC_DBUSER"
mysql -u root -e "DROP USER $NC_DBUSER"
ok "Done"

info "Removing directories and files..."
rm -r $NC_INSTALLATION_DIRECTORY
rm ./ncvars.env
ok "Done"

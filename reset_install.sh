mysql --execute="DROP DATABASE nextcloud;"
mysql --execute="DROP USER nextcloud_user;"

rm latest.zip*
rm -rf /var/www/nextcloud

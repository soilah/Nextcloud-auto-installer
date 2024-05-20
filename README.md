# Nextcloud auto installer

## This is a bash script that automates the installation of nextcloud

## Assumptions/Requirements
<p>This script works with the <b>Nginx</b> Web Server only. Apache is not supported. The script will install nginx if not already installed. A copy of an nginx configuration for nextcloud exists in the root directory and is used by the script in order to change the virtual host name and copy it at /etc/nginx/sites-enabled.</p>

## Notes
<p>This script installs nextcloud as HTTP only, in order to be placed behind a proxy server (e.g. HaProxy). HTTPS needs to be configured respectively at the proxy with the corresponding domain. </p>

## Usage
### Installation
<p>Install nextcloud by running the nextcloud_auto.sh script. During the installation procedure you will be asked for the domain name of the nextcloud instance. This needs to be the same as the one that has been configured at the proxy server (with a valid ssl certificate). The installer will also ask you to enter the database name, user and password. Leave them blank to use the defaults. The database name, user and password will be printed after being created so you have to make sure to remember them, because you will need to enter them the first time you access the website. It is best to copy them immediately!</p>

### Uninstall
<p>Run the script uninstall_nextcloud.sh. It will delete ** <b>EVERYTHING</b> **, meaning that the database and user will be dropped, as well as the nextcloud folder <b>WITH THE DATA</b>.</p>

### TO DO LIST
- Add suppor to install nextloud with https (without proxy with domain name)
- Add option to install the data to different directory than the default.
- Add options to keep database data?, or data folder after unistall.
- Add function to check if previous parts from previous installation exists (data folder,...)

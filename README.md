# nextcloud_auto_installer

## Assumptions/Requirements
<p>This script works with the <b>Nginx</b> Web Server only. Apache is not supported. The script will install nginx if not already installed. A copy of an nginx configuration for nextcloud exists in the root directory and is used by the script in order to change the virtual host name and copy it at /etc/nginx/sites-enabled.</p>

## Notes
<p>This script installs nextcloud as HTTP only, in order to be placed behind a proxy server (e.g. HaProxy). HTTPS needs to be configured respectively at the proxy with the corresponding domain. </p>

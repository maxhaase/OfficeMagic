#!/bin/bash
#######################################
# provision_server.sh
# Script to provision the mail server
# Author: maxhaase@gmail.com
#######################################

# Source environment variables
set -o allexport; source /tmp/vars.env; set +o allexport

# Check if required environment variables are set
if [[ -z "${MYSQL_ROOT_PASSWORD}" || -z "${MYSQL_USER}" || -z "${MYSQL_PASSWORD}" || -z "${WORDPRESS_DB_USER}" || -z "${WORDPRESS_DB_PASSWORD}" || -z "${POSTFIXADMIN_SETUP_PASSWORD}" || -z "${ROUNDCUBEMAIL_DB_USER}" || -z "${ROUNDCUBEMAIL_DB_PASSWORD}" || -z "${DOMAIN1}" || -z "${MAIL_DOMAIN}" || -z "${ADMIN_DOMAIN}" || -z "${WEBMAIL_DOMAIN}" ]]; then
  echo "Error: Required environment variables are not set."
  exit 1
fi

# Set up MariaDB
echo "Setting up MariaDB..."
service mariadb start
mysqladmin -u root password "$MYSQL_ROOT_PASSWORD"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE $MYSQL_DATABASE;"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'localhost';"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# Set up PostfixAdmin
echo "Setting up PostfixAdmin..."
cd /var/www/
wget https://github.com/postfixadmin/postfixadmin/archive/postfixadmin-3.3.10.tar.gz
tar xzf postfixadmin-3.3.10.tar.gz
mv postfixadmin-postfixadmin-3.3.10 /var/www/postfixadmin
chown -R www-data:www-data /var/www/postfixadmin
cd /var/www/postfixadmin
cp config.inc.php config.local.php

sed -i "s/^\(\$CONF\['configured'\] = \).*/\1true;/" config.local.php
sed -i "s/^\(\$CONF\['database_type'\] = \).*/\1'mysqli';/" config.local.php
sed -i "s/^\(\$CONF\['database_host'\] = \).*/\1'localhost';/" config.local.php
sed -i "s/^\(\$CONF\['database_user'\] = \).*/\1'$MYSQL_USER';/" config.local.php
sed -i "s/^\(\$CONF\['database_password'\] = \).*/\1'$MYSQL_PASSWORD';/" config.local.php
sed -i "s/^\(\$CONF\['database_name'\] = \).*/\1'$MYSQL_DATABASE';/" config.local.php

# Set up Roundcube
echo "Setting up Roundcube..."
cd /var/www/
wget https://github.com/roundcube/roundcubemail/releases/download/1.5.0/roundcubemail-1.5.0-complete.tar.gz
tar xzf roundcubemail-1.5.0-complete.tar.gz
mv roundcubemail-1.5.0 /var/www/roundcube
chown -R www-data:www-data /var/www/roundcube
cd /var/www/roundcube
cp config/config.inc.php.sample config/config.inc.php

sed -i "s/^\(\$config\['db_dsnw'\] = \).*/\1'mysql:\/\/$ROUNDCUBEMAIL_DB_USER:$ROUNDCUBEMAIL_DB_PASSWORD@localhost\/$MYSQL_DATABASE';/" config/config.inc.php
sed -i "s/^\(\$config\['default_host'\] = \).*/\1'localhost';/" config/config.inc.php
sed -i "s/^\(\$config\['smtp_server'\] = \).*/\1'localhost';/" config/config.inc.php

# Set up Apache virtual hosts
echo "Setting up Apache virtual hosts..."
cat <<EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    Alias /roundcube /var/www/roundcube
    Alias /postfixadmin /var/www/postfixadmin

    <Directory /var/www/roundcube>
        Options +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    <Directory /var/www/postfixadmin>
        Options +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

a2enmod rewrite
a2ensite 000-default
service apache2 reload

# Obtain SSL certificates
echo "Obtaining SSL certificates..."
certbot --apache -d $DOMAIN1 -d $MAIL_DOMAIN -d $ADMIN_DOMAIN -d $WEBMAIL_DOMAIN --agree-tos --non-interactive -m $EMAIL

# Start services
service postfix start
service dovecot start

# Finalize setup
echo "Provisioning completed successfully!"
echo "Access PostfixAdmin at http://$DOMAIN1/postfixadmin"
echo "Access Roundcube at http://$DOMAIN1/roundcube"

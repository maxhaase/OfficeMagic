# secrets, you should store these elsewhere, not in the repo!
MYSQL_ROOT_PASSWORD=ChangeMe000!
MYSQL_USER=admin
MYSQL_PASSWORD=ChangeMe000!
MYSQL_DATABASE=mailserver_db
WORDPRESS_DB_USER=admin
WORDPRESS_DB_PASSWORD=ChangeMe000!
POSTFIXADMIN_SETUP_PASSWORD=ChangeMe000!
ROUNDCUBEMAIL_DB_USER=admin
ROUNDCUBEMAIL_DB_PASSWORD=ChangeMe000!
# These ain't secrets:
DOMAIN1=example1.com
DOMAIN2=example2.com
MAIL_DOMAIN=mail.example1.com
ADMIN_DOMAIN=admin.example1.com
WEBMAIL_DOMAIN=webmail.example1.com
# Versions and URLs
POSTFIXADMIN_VERSION=postfixadmin-3.3.10
POSTFIXADMIN_URL=https://github.com/postfixadmin/postfixadmin/archive/${POSTFIXADMIN_VERSION}.tar.gz
ROUNDCUBE_VERSION=1.5.0
ROUNDCUBE_URL=https://github.com/roundcube/roundcubemail/releases/download/${ROUNDCUBE_VERSION}/roundcubemail-${ROUNDCUBE_VERSION}-complete.tar.gz

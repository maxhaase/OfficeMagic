#!/bin/bash

# Load variables from vars.env
source vars.env

# Update and install necessary packages
sudo apt-get update
sudo apt-get install -y docker.io docker-compose nginx certbot python3-certbot-nginx

# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Function to set up Let's Encrypt for a domain
setup_letsencrypt() {
  local DOMAIN=$1
  echo "Setting up Let's Encrypt for $DOMAIN"
  sudo certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN
}

# Function to configure Nginx for SSL
setup_nginx_ssl() {
  local DOMAIN=$1
  cat > /etc/nginx/sites-available/$DOMAIN <<EOL
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    if (\$host = www.$DOMAIN) {
        return 301 https://$DOMAIN\$request_uri;
    } # managed by Certbot

    if (\$host = $DOMAIN) {
        return 301 https://$DOMAIN\$request_uri;
    } # managed by Certbot

    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 404; # managed by Certbot
}
EOL

  ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
  sudo systemctl reload nginx
}

# Function to set up WordPress with Let's Encrypt
setup_wordpress() {
  local DOMAIN=$1
  echo "Setting up WordPress for $DOMAIN"

  # Create docker-compose file
  cat > docker-compose-$DOMAIN.yml <<EOL
version: '3.7'

services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress_$DOMAIN
    environment:
      WORDPRESS_DB_HOST: db_$DOMAIN
      WORDPRESS_DB_USER: $WORDPRESS_DB_USER
      WORDPRESS_DB_PASSWORD: $WORDPRESS_DB_PASSWORD
      WORDPRESS_DB_NAME: wordpress_$DOMAIN
    volumes:
      - ./wordpress_$DOMAIN:/var/www/html
    ports:
      - "8000:80"
    networks:
      - wpnet_$DOMAIN

  db:
    image: mysql:5.7
    container_name: db_$DOMAIN
    environment:
      MYSQL_DATABASE: wordpress_$DOMAIN
      MYSQL_USER: $WORDPRESS_DB_USER
      MYSQL_PASSWORD: $WORDPRESS_DB_PASSWORD
      MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD
    volumes:
      - db_data_$DOMAIN:/var/lib/mysql
    networks:
      - wpnet_$DOMAIN

networks:
  wpnet_$DOMAIN:
volumes:
  db_data_$DOMAIN:
EOL

  # Start the containers
  docker-compose -f docker-compose-$DOMAIN.yml up -d

  # Set up Let's Encrypt
  setup_letsencrypt $DOMAIN

  # Set up Nginx for SSL
  setup_nginx_ssl $DOMAIN
}

# Provision the server for DOMAIN1
setup_wordpress $DOMAIN1

# Provision the server for DOMAIN2 if defined
if [ -n "$DOMAIN2" ]; then
  setup_wordpress $DOMAIN2
fi

# Display access information
echo "WordPress setup completed. Access your services at:"
echo "https://$DOMAIN1 for DOMAIN1"
if [ -n "$DOMAIN2" ]; then
  echo "https://$DOMAIN2 for DOMAIN2"
fi

#!/bin/bash

# Load variables from vars.env
source vars.env

# Function to set up Let's Encrypt for a domain
setup_letsencrypt() {
  local domain=$1
  echo "Setting up Let's Encrypt for $domain"
  sudo certbot certonly --standalone -d $domain --non-interactive --agree-tos --email admin@$domain
}

# Function to set up WordPress with Let's Encrypt
setup_wordpress() {
  local domain=$1
  echo "Setting up WordPress for $domain"

  # Assuming Docker and docker-compose are used
  cat > docker-compose-$domain.yml <<EOL
version: '3.7'

services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress_$domain
    environment:
      WORDPRESS_DB_HOST: db_$domain
      WORDPRESS_DB_USER: $WORDPRESS_DB_USER
      WORDPRESS_DB_PASSWORD: $WORDPRESS_DB_PASSWORD
      WORDPRESS_DB_NAME: wordpress_$domain
    volumes:
      - ./wordpress_$domain:/var/www/html
    ports:
      - "80:80"
    networks:
      - wpnet_$domain

  db:
    image: mysql:5.7
    container_name: db_$domain
    environment:
      MYSQL_DATABASE: wordpress_$domain
      MYSQL_USER: $WORDPRESS_DB_USER
      MYSQL_PASSWORD: $WORDPRESS_DB_PASSWORD
      MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD
    volumes:
      - db_data_$domain:/var/lib/mysql
    networks:
      - wpnet_$domain

networks:
  wpnet_$domain:
volumes:
  db_data_$domain:
EOL

  # Start the containers
  docker-compose -f docker-compose-$domain.yml up -d

  # Set up Let's Encrypt
  setup_letsencrypt $domain
}

# Provision the server for DOMAIN1
setup_wordpress $DOMAIN1

# Provision the server for DOMAIN2 if defined
if [ -n "$DOMAIN2" ]; then
  setup_wordpress $DOMAIN2
fi

# Display access information
echo "WordPress setup completed. Access your services at:"
echo "http://$DOMAIN1 for DOMAIN1"
if [ -n "$DOMAIN2" ]; then
  echo "http://$DOMAIN2 for DOMAIN2"
fi

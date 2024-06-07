#!/bin/bash
#######################################
# install.sh
# Script to install Docker and Docker Compose, build Docker image, and run container
# Author: maxhaase@gmail.com
#######################################

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found, installing..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
else
    echo "Docker is already installed."
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose not found, installing..."
    curl -L "https://github.com/docker/compose/releases/download/v2.27.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose is already installed."
fi

# Verify Docker installation
docker --version
docker-compose --version

# Prompt for Docker image name
read -p "Enter the Docker image name you want to build (e.g., my_image_name): " IMAGE_NAME

# Build the Docker image with increased verbosity
docker build --progress=plain --no-cache -t $IMAGE_NAME .

# Run the Docker container with environment variables sourced from the vars.env file
docker run -d --name $IMAGE_NAME -p 80:80 -p 443:443 --env-file vars.env $IMAGE_NAME

echo "Installation and setup completed successfully."

#!/bin/bash
#######################################
# install.sh
# This script installs Docker, Docker Compose, builds the Docker image, and runs the container.
# Author: maxhaase@gmail.com
#######################################

set -e

# Function to install Docker
install_docker() {
  if ! command -v docker &> /dev/null; then
    echo "Docker not found, installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl enable docker
    sudo systemctl start docker
  else
    echo "Docker is already installed."
  fi
}

# Function to install Docker Compose
install_docker_compose() {
  if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose not found, installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.27.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
  else
    echo "Docker Compose is already installed."
  fi
}

# Function to verify Docker installation
verify_docker() {
  echo "Verifying Docker installation..."
  sudo docker --version
  sudo docker-compose --version
}

# Main script
install_docker
install_docker_compose
verify_docker

# Prompt for the Docker image name
read -p "Enter the Docker image name you want to build (e.g., my_image_name): " IMAGE_NAME

# Build the Docker image
echo "Building Docker image with name: $IMAGE_NAME"
sudo docker build -t $IMAGE_NAME .

# Run the Docker container
echo "Running Docker container with name: $IMAGE_NAME"
sudo docker run -d --name ${IMAGE_NAME}_container -e DOMAIN1=xsol.es -e USER=user -e EMAIL=admin@example.com $IMAGE_NAME

echo "Installation and setup completed successfully."

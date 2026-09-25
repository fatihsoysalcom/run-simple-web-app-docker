#!/bin/bash

# --- Docker Containerization Example ---
# This script demonstrates how to build and run a simple Python Flask web application
# inside a Docker container. It creates necessary files (app.py, requirements.txt, Dockerfile),
# builds a Docker image, runs the container, and then cleans up.

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed. Please install Docker to run this example."
    echo "Refer to the article 'Debian Üzerine Docker Kurulumu' for installation instructions."
    exit 1
fi

echo "--- Starting Docker Container Example ---"

# Define variables
IMAGE_NAME="my-flask-app"
CONTAINER_NAME="my-flask-container"
APP_PORT="5000"
HOST_PORT="8080" # Port on the host machine to access the app

# --- 1. Create application files ---
echo "1. Creating application files (app.py, requirements.txt)..."

# Create app.py
cat <<EOF > app.py
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return "Merhaba Docker! Bu uygulama bir konteyner içinde çalışıyor."

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=${APP_PORT})
EOF

# Create requirements.txt
cat <<EOF > requirements.txt
Flask
EOF

# --- 2. Create Dockerfile ---
echo "2. Creating Dockerfile..."

# Create Dockerfile
cat <<EOF > Dockerfile
# Use an official Python runtime as a parent image
FROM python:3.9-slim-buster

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container at /app
COPY requirements.txt .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code into the container at /app
COPY app.py .

# Make port ${APP_PORT} available to the world outside this container
EXPOSE ${APP_PORT}

# Run app.py when the container launches
CMD ["python", "app.py"]
EOF

# --- 3. Build the Docker image ---
echo "3. Building Docker image '${IMAGE_NAME}'..."
# The 'docker build' command reads the Dockerfile and creates a Docker image.
# The '-t' flag tags the image with a name.
docker build -t ${IMAGE_NAME} .

if [ $? -ne 0 ]; then
    echo "Docker image build failed. Exiting."
    exit 1
fi

# --- 4. Run the Docker container ---
echo "4. Running Docker container '${CONTAINER_NAME}' on port ${HOST_PORT}..."
# The 'docker run' command starts a new container from an image.
# '-d' runs the container in detached mode (in the background).
# '-p' maps a host port to a container port (HOST_PORT:CONTAINER_PORT).
# '--name' assigns a name to the container.
docker run -d -p ${HOST_PORT}:${APP_PORT} --name ${CONTAINER_NAME} ${IMAGE_NAME}

if [ $? -ne 0 ]; then
    echo "Docker container failed to run. Exiting."
    # Attempt to clean up partially created resources
    docker rm -f ${CONTAINER_NAME} &> /dev/null
    exit 1
fi

echo "--- Docker container is running! ---"
echo "You can access the application at: http://localhost:${HOST_PORT}"
echo "Press Ctrl+C to stop this script and clean up."

# Keep the script running until interrupted, allowing the user to test the app
trap cleanup EXIT # Ensure cleanup runs on script exit (e.g., Ctrl+C)
while true; do sleep 1; done

# --- Cleanup function ---
cleanup() {
    echo -e "\n--- Cleaning up Docker resources ---"

    # Stop and remove the container
    if docker ps -a --format "{{.Names}}" | grep -q "${CONTAINER_NAME}"; then
        echo "Stopping and removing container '${CONTAINER_NAME}'..."
        docker stop ${CONTAINER_NAME}
        docker rm ${CONTAINER_NAME}
    else
        echo "Container '${CONTAINER_NAME}' not found or already removed."
    fi

    # Remove the Docker image
    if docker images --format "{{.Repository}}" | grep -q "${IMAGE_NAME}"; then
        echo "Removing Docker image '${IMAGE_NAME}'..."
        docker rmi ${IMAGE_NAME}
    else
        echo "Image '${IMAGE_NAME}' not found or already removed."
    fi

    # Remove created files
    echo "Removing created files (app.py, requirements.txt, Dockerfile)..."
    rm -f app.py requirements.txt Dockerfile

    echo "--- Cleanup complete. Exiting. ---"
}

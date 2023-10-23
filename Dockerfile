# Use an official Python image from Docker Hub as a base image
FROM docker.io/library/python:3.12-slim

# Set the working directory in the container
WORKDIR /app

# Copy the application code into the container
COPY . .

# Install the Python dependencies
RUN python -m pip install --upgrade pip
RUN python -m pip install --no-cache-dir -r requirements.txt

# Create a group and user for the app
RUN groupadd -r secureafgrp && useradd -r -g secureafgrp -m secureafusr

# Switch to the new user for subsequent operations and running the app
USER secureafusr

# Expose the port that Uvicorn will run on
EXPOSE 8000

# Define the default command to run the app using Uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
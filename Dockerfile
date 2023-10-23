# Use an official Python image from Docker Hub as a base image
FROM docker.io/library/python:3.12-slim

# Set the working directory in the container
WORKDIR /app

# Copy the rapplication code into the container
COPY . .

# Install the Python dependencies
RUN python -m pip install --upgrade pip
RUN python -m pip install --no-cache-dir -r requirements.txt

# Expose the port that Uvicorn will run on
EXPOSE 8000

# Define the default command to run the app using Uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
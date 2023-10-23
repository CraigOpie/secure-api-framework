# Secure API Framework

This project is an implementation of the HL7 FHIR API using FAST API. It is designed to be deployed in a Podman container for enhanced security and portability. For enhanced security, the Secure API Framework runs inside its container as a non-root user. This ensures that the application has limited privileges, reducing the potential impact of container vulnerabilities.

## Prerequisites

- [Podman](https://podman.io/)

## Setup and Running

### Building the Container

1. Clone this repository:
   ```
   git clone [URL of your repository]
   cd secure-api-framework
   ```

2. Build the container:
   ```bash
   podman build -t secureaf:latest .
   ```

### Running the Application

3. To run the containerized application:
   ```bash
   podman run -d --name secureaf -p 8000:8000 --restart=always secureaf:latest
   ```

Visit `http://localhost:8000/` to access the API.

### Stopping and Removing the Container

4. To stop the container:
   ```bash
   podman stop secureaf
   ```

5. To remove the container instance:
   ```bash
   podman rm secureaf
   ```

## Development Outside of Container

If you wish to develop and test changes outside of the container:

1. Set up a virtual environment:
   ```bash
   python -m venv env
   ```

2. Activate the virtual environment:
   ```bash
   source env/bin/activate
   ```

3. Install required packages:
   ```bash
   python -m pip install -r requirements.txt
   ```

4. Run the app:
   ```bash
   uvicorn app.main:app --reload
   ```

Visit `http://localhost:8000/` to access the API.

## License

[Secure API Framework](https://github.com/CraigOpie/secure-api-framework) by [Craig Opie](https://craigopie.github.io/) is licensed under [CC BY-SA 4.0 <img src="https://mirrors.creativecommons.org/presskit/icons/cc.svg?ref=chooser-v1" style="height:22px;margin-left:3px;vertical-align:text-bottom;"> <img src="https://mirrors.creativecommons.org/presskit/icons/by.svg?ref=chooser-v1" style="height:22px;margin-left:3px;vertical-align:text-bottom;"> <img src="https://mirrors.creativecommons.org/presskit/icons/sa.svg?ref=chooser-v1" style="height:22px;margin-left:3px;vertical-align:text-bottom;">](http://creativecommons.org/licenses/by-sa/4.0/?ref=chooser-v1)

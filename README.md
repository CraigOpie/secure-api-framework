# Secure API Framework

This project is an implementation of the HL7 FHIR API using FAST API. It is designed to be deployed in a Podman container for enhanced security and portability. The Secure API Framework ensures enhanced security by employing user namespaces, a feature of Linux containers that isolates the container's user ID (UID) and group ID (GID) from the host. This not only provides the container with its own distinct set of UIDs and GIDs but also ensures that even if a user gets escalated privileges inside the container, it would map to a non-privileged user on the host.

## Advantages of User Namespaces

1. **Enhanced Security**: If an attacker manages to exploit a vulnerability within the application running inside the container and tries to escalate privileges, the UIDs within the container would map to a non-privileged UID on the host system, thus preventing potential harm.
2. **Isolation**: With user namespaces, each container can have its own range of UIDs and GIDs, ensuring isolation from both the host and other containers.
3. **Reduced Privileges**: Running containers with non-root privileges minimizes the potential risks of container vulnerabilities, ensuring that the application inside has limited permissions.

## Prerequisites

- [Podman](https://podman.io/)

## Setup and Running

### Using the Script (Recommended)

1. Clone this repository:
   ```bash
   git clone [URL of your repository]
   cd secure-api-framework
   ```

2. Grant execution permissions to the script:
   ```bash
   chmod +x secureaf.sh
   ```

3. Install and configure user namespaces:
   ```bash
   sudo ./secureaf.sh install
   ```

4. To start the containerized application:
   ```bash
   ./secureaf.sh start
   ```

5. To stop the container:
   ```bash
   ./secureaf.sh stop
   ```

6. To view the container's logs:
   ```bash
   ./secureaf.sh logs
   ```

7. To restart the container:
   ```bash
   ./secureaf.sh restart
   ```

Visit `http://localhost:8000/` to access the API.

### Manual Deployment (For Advanced Users)

[Refer to the previous content you had for manual deployment]

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
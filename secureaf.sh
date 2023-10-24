#!/bin/bash

set -e

trap 'handle_error $LINENO' ERR

handle_error() {
    echo "Error occurred on line $1. Exiting..."
    exit 1
}

# Secure API Framework Control Script

VERSION="1.0.0"
IMAGE_NAME="secureaf:latest"
SUBUID="/etc/subuid"
SUBGID="/etc/subgid"
RANGE_SIZE="65536"
CURRENT_USER=$(logname)
PG_PASSWORD="postgres"
PG_DB="postgres"
PG_USER="postgres"

usage() {
    echo "Usage: $0 <command>"
    echo "Commands:"
    echo "  install         - Configure user namespaces and install necessary components"
    echo "  start           - Build and start the container"
    echo "  stop            - Stop the container"
    echo "  status          - Show the container's status"
    echo "  logs            - Show the container's logs"
    echo "  restart         - Restart the container"
    echo "  --version, -v   - Display script version"
    echo "  --help,    -h   - Display this help message"
    exit 1
}

get_next_available_ids() {
    local file=$1
    local range_size=$2
    local max_id=6000000
    local start_id=100000
    
    while [[ $start_id -lt $max_id ]]; do
        if ! grep -qE "^.*:${start_id}:[0-9]+" $file; then
            echo $start_id
            return
        fi
        start_id=$((start_id+range_size))
    done

    echo "0"
}

configure_sub_ids() {
    local file=$1
    local id_type=$2
    local start_id=$3
    local range_size=$4

    # Check if the desired range is already in the file
    if grep -q "^${CURRENT_USER}:${start_id}:${range_size}" $file; then
        echo "${id_type} range ${start_id}:${range_size} already configured for $CURRENT_USER."
    else
        echo "Configuring ${id_type} range ${start_id}:${range_size} for $CURRENT_USER..."
        echo "${CURRENT_USER}:${start_id}:${range_size}" >> $file
        echo "${id_type} range ${start_id}:${range_size} configured for $CURRENT_USER."
    fi
}

case $1 in
    install)
        if [ "$(id -u)" -ne 0 ]; then
            echo "Please run 'install' as root."
            exit 1
        fi
        
        uid_start=$(get_next_available_ids $SUBUID $RANGE_SIZE)
        gid_start=$(get_next_available_ids $SUBGID $RANGE_SIZE)

        if [[ $uid_start -eq 0 || $gid_start -eq 0 ]]; then
            echo "Could not find an available UID/GID range."
            exit 1
        fi

        configure_sub_ids $SUBUID "UID" $uid_start $RANGE_SIZE
        configure_sub_ids $SUBGID "GID" $gid_start $RANGE_SIZE

        usermod --add-subuids ${uid_start}-$((uid_start+RANGE_SIZE-1)) --add-subgids ${gid_start}-$((gid_start+RANGE_SIZE-1)) $CURRENT_USER

        if podman ps -a --format '{{.Names}}' | grep -q '^secureaf$'; then
            if podman ps --format '{{.Names}}' | grep -q '^secureaf$'; then
                echo "The container 'secureaf' is already running."
                exit 1
            else
                echo "Removing stopped container 'secureaf'..."
                podman rm secureaf
            fi
        fi

        if ! podman network ls --format "{{.Name}}" | grep -q "^secureaf-net$"; then
            echo "Creating the network..."
            podman network create secureaf-net
        else
            echo "Network 'secureaf-net' already exists."
        fi

        echo "Building the container..."
        podman build -t $IMAGE_NAME .

        echo "Starting the container with user namespace..."
        podman run --uidmap=0:${uid_start}:${RANGE_SIZE} --gidmap=0:${gid_start}:${RANGE_SIZE} -d --name secureaf -p 8000:8000 --network=secureaf-net --hostname=secureaf-api $IMAGE_NAME
        
        echo "Building the PostgreSQL Database..."
        if [[ ! -d "/var/psql/data" ]]; then
            mkdir -p /var/psql/data
        fi

        if [[ ! -f "/var/psql/pg_hba.conf" ]]; then
            echo "host  postgres    postgres    secureaf-api    md5" > /var/psql/pg_hba.conf
        else
            sed -i '/host  postgres    postgres    secureaf-api    md5/!b;$a\host  postgres    postgres    secureaf-api    md5' /var/psql/pg_hba.conf
        fi

        if [[ ! -f "/var/psql/postgresql.conf" ]]; then
            echo "listen_addresses = '*'" > /var/psql/postgresql.conf
        else
            sed -i '/listen_addresses = '\''\*'\''/!b;$a\listen_addresses = '\''*'\''' /var/psql/postgresql.conf
        fi

        if [[ $(stat -c '%u:%g' /var/psql) != "999:999" ]]; then
            chown 999:999 /var/psql
        fi
        if [[ $(stat -c '%a' /var/psql) != "700" ]]; then
            chmod -R 0700 /var/psql
        fi

        chcon -Rt svirt_sandbox_file_t /var/psql

        podman pull docker.io/library/postgres:latest
        podman run --name secureaf-postgres --network=secureaf-net --hostname=secureaf-postgres -e POSTGRES_PASSWORD=$PG_PASSWORD -e POSTGRES_DB=$PG_DB -e POSTGRES_USER=$PG_USER -v /var/psql/data:/var/lib/postgresql/data:Z -v /var/psql/pg_hba.conf:/etc/postgresql/pg_hba.conf:Z -v /var/psql/postgresql.conf:/etc/postgresql/postgresql.conf:Z -d postgres:latest
        ;;
    start)
        if podman ps -a --format '{{.Names}}' | grep -q '^secureaf$'; then
            if podman ps --format '{{.Names}}' | grep -q '^secureaf$'; then
                echo "The container 'secureaf' is already running."
                exit 1
            else
                echo "Removing stopped container 'secureaf'..."
                podman rm secureaf
            fi
        fi
        echo "Building the container..."
        podman build -t $IMAGE_NAME .
        echo "Starting the container with user namespace..."
        podman run --uidmap=0:${uid_start}:${RANGE_SIZE} --gidmap=0:${gid_start}:${RANGE_SIZE} -d --name secureaf -p 8000:8000 --network=secureaf-net --hostname=secureaf-api $IMAGE_NAME
        ;;
    stop)
        echo "Stopping the container..."
        podman stop secureaf || true
        ;;
    status)
        echo "Container status:"
        podman ps -a | grep NAMES || true
        podman ps -a | grep secureaf || true
        ;;
    logs)
        echo "Container logs:"
        podman logs secureaf || true
        ;;
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    -v|--version)
        echo "Secure API Framework Control Script Version $VERSION"
        ;;
    -h|--help)
        usage
        ;;
    *)
        echo "Invalid command. Use --help for usage information."
        exit 1
        ;;
esac
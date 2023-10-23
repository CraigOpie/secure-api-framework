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

        configure_sub_ids $SUBUID "UID" 600000 ${RANGE_SIZE}
        configure_sub_ids $SUBGID "GID" 600000 ${RANGE_SIZE}

        usermod --add-subuids 600000-$((600000+RANGE_SIZE-1)) --add-subgids 600000-$((600000+RANGE_SIZE-1)) $CURRENT_USER
        
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
        podman run --uidmap=0:600000:${RANGE_SIZE} --gidmap=0:600000:${RANGE_SIZE} -d --name secureaf -p 8000:8000 $IMAGE_NAME
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
        podman run --uidmap=0:600000:${RANGE_SIZE} --gidmap=0:600000:${RANGE_SIZE} -d --name secureaf -p 8000:8000 $IMAGE_NAME
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
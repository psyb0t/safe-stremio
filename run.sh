#!/bin/bash

set -euo pipefail

# Constants
VPN_CONFIG_FILE="/vpn-config.ovpn"
VPN_AUTH_FILE="/vpn-auth.txt"
TUN_FILE="/dev/net/tun"
AUTH_CONF_FILE="/etc/nginx/conf.d/auth.conf"
HTPASSWD_FILE="/etc/nginx/.htpasswd"
IP_REPORTER_URL="https://api.ipify.org"

# Function to log messages
log() {
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    echo "$timestamp $message"
}

# Function to cleanly stop processes
cleanup() {
    log "Caught signal or error, stopping processes..."

    if [[ -n "${nginx_pid-}" ]]; then
        kill -SIGTERM "$nginx_pid" 2>/dev/null || true
        wait "$nginx_pid" 2>/dev/null || true
    fi

    if [[ -n "${openvpn_pid-}" ]]; then
        kill -SIGTERM "$openvpn_pid" 2>/dev/null || true
        wait "$openvpn_pid" 2>/dev/null || true
    fi

    if [[ -n "${stremio_pid-}" ]]; then
        kill -SIGTERM "$stremio_pid" 2>/dev/null || true
        wait "$stremio_pid" 2>/dev/null || true
    fi

    log "All processes have been stopped. Exiting."
    exit 1
}

# Function to get the public IP address
get_public_ip() {
    curl -s "$IP_REPORTER_URL"
}

REAL_IP=$(get_public_ip)
CURRENT_IP="$REAL_IP"
OPENVPN_STARTED=0

# Function to monitor the public IP continuously
monitor_ip() {
    while true; do
        CURRENT_IP=$(get_public_ip)
        log "Public IP: $CURRENT_IP"

        if [[ "$CURRENT_IP" == "$REAL_IP" && $OPENVPN_STARTED -eq 1 ]]; then
            log "REAL IP EXPOSED!!! CURRENT IP: $CURRENT_IP == REAL IP: $REAL_IP"
            cleanup
        fi

        sleep 10
    done
}

# Function to check the status of a process
check_process() {
    local pid=$1
    local name=$2
    if ! kill -0 "$pid" 2>/dev/null; then
        log "$name has terminated unexpectedly."
        cleanup
    fi
}

# Trap termination signals and errors
trap cleanup SIGINT SIGTERM ERR

if [[ "${WITH_OPENVPN-}" == "true" ]]; then
    # Start the IP monitor in the background
    monitor_ip &
    monitor_ip_pid=$!
fi

echo "" >$AUTH_CONF_FILE

# Setup authentication if environment variables are set
if [[ -n "${USERNAME-}" && -n "${PASSWORD-}" ]]; then
    log "Setting up HTTP basic authentication..."
    htpasswd -bc "$HTPASSWD_FILE" "$USERNAME" "$PASSWORD"
    echo 'auth_basic "Restricted Content";' >$AUTH_CONF_FILE
    echo 'auth_basic_user_file '"$HTPASSWD_FILE"';' >>$AUTH_CONF_FILE
else
    log "No HTTP basic authentication will be used."
fi

log "Starting Nginx..."
nginx -g 'daemon off;' &
nginx_pid=$!
if ! kill -0 $nginx_pid 2>/dev/null; then
    log "Failed to start Nginx."
    cleanup
fi

# Start OpenVPN if WITH_OPENVPN is set to "true"
if [[ "${WITH_OPENVPN-}" == "true" ]]; then
    echo "Ensuring the TUN device is available..."

    mkdir -p /dev/net
    if [ ! -c "$TUN_FILE" ]; then
        mknod $TUN_FILE c 10 200
        chmod 600 $TUN_FILE
    fi

    if [ ! -f "$VPN_CONFIG_FILE" ]; then
        echo "OpenVPN configuration file not found: $VPN_CONFIG_FILE"
        cleanup
    fi

    echo "Starting OpenVPN..."
    openvpn_cmd="openvpn --config $VPN_CONFIG_FILE"

    if [ -f "$VPN_AUTH_FILE" ]; then
        openvpn_cmd="$openvpn_cmd --auth-user-pass $VPN_AUTH_FILE"
    fi

    $openvpn_cmd &
    openvpn_pid=$!
    if ! kill -0 $openvpn_pid 2>/dev/null; then
        echo "Failed to start OpenVPN."
        cleanup
    fi

    # Wait for the VPN to establish a connection
    sleep 10

    OPENVPN_STARTED=1
else
    echo "OpenVPN will not be started."
fi

log "Starting Stremio Server"
node /stremio/server.js &
stremio_pid=$!
if ! kill -0 $stremio_pid 2>/dev/null; then
    log "Failed to start Stremio Server."
    cleanup
fi

# Background loop to monitor the processes
while true; do
    check_process $nginx_pid "Nginx"
    check_process $stremio_pid "Stremio Server"

    if [[ -n "${openvpn_pid-}" ]]; then
        check_process "$openvpn_pid" "OpenVPN"
    fi

    sleep 1
done &

# Wait for all processes to finish
wait $nginx_pid
nginx_status=$?

wait $stremio_pid
stremio_status=$?

if [[ -n "${openvpn_pid-}" ]]; then
    wait "$openvpn_pid"
    openvpn_status=$?

    kill "$monitor_ip_pid" 2>/dev/null
else
    openvpn_status=0
fi

# Check the exit statuses
if [[ $nginx_status -ne 0 || $stremio_status -ne 0 || $openvpn_status -ne 0 ]]; then
    cleanup
else
    log "All processes completed successfully. Exiting."
    exit 0
fi

#!/bin/bash

# Function to show progress
show_progress() {
    local -r msg="$1"
    local -r pid="$2"
    local -r delay='0.1'
    local -r width=50
    local completed=0
    while ps -p $pid > /dev/null 2>&1; do
        sleep "$delay"
        completed=$(( (completed + 1) % (width + 1) ))
        printf "\r\033[1;33m$msg:\033[0m \033[1;34m[%-${width}s]\033[0m" $(printf "#%.0s" $(seq 1 $completed))
    done
    printf "\r\033[1;33m$msg:\033[0m \033[1;34m[%-${width}s] \033[0;32mDONE!\033[0m\n" $(printf "#%.0s" $(seq 1 $width))
}

# Function to handle errors
error_exit() {
    echo "Error during $1. Exiting."
    echo "$2"
    exit 1
}

# Function to clean up temporary files
cleanup() {
    rm -f /tmp/Nessus-10.7.3-raspberrypios_armhf.deb
}

# Function to get IP address
get_ip_address() {
    hostname -I | awk '{print $1}'
}

# Function to link Nessus to Tenable.io
link_nessus() {
    local linking_key="$1"
    /opt/nessus/sbin/nessuscli managed link --key=$linking_key
    if [[ $? -ne 0 ]]; then
        error_exit "linking Nessus to Tenable.io" "Failed to link Nessus"
    fi
}

# Print ASCII art
print_ascii_art() {
    echo -e "\033[0;31m"
    cat << "EOF"
/$$   /$$ /$$    /$$$$$$$$ /$$$$$$ /$$      /$$  /$$$$$$ 
| $$  | $$| $$   |__  $$__/|_  $$_/| $$$    /$$$ /$$__  $$
| $$  | $$| $$      | $$     | $$  | $$$$  /$$$$| $$  \ $$
| $$  | $$| $$      | $$     | $$  | $$ $$/$$ $$| $$$$$$$$
| $$  | $$| $$      | $$     | $$  | $$  $$$| $$| $$__  $$
| $$  | $$| $$      | $$     | $$  | $$\  $ | $$| $$  | $$
|  $$$$$$/| $$$$$$$$| $$    /$$$$$$| $$ \/  | $$| $$  | $$
 \______/ |________/|__/   |______/|__/     |__/|__/  |__/
EOF
    echo -e "\033[0m"
}

# Main script execution
print_ascii_art

# Prompt the user for the linking key
read -p "Please enter your Tenable.io linking key: " LINKING_KEY

# Update package lists
update_output=$(sudo apt-get update -y 2>&1)
if [[ $? -ne 0 ]]; then
    error_exit "updating package lists" "$update_output"
fi

# Upgrade installed packages
sudo apt-get upgrade -y >/dev/null 2>&1 &
show_progress "Upgrading installed packages" $!
wait $! || error_exit "upgrading installed packages"

# Download Nessus
NESSUS_URL="https://www.tenable.com/downloads/api/v2/pages/nessus/files/Nessus-10.7.3-raspberrypios_armhf.deb"
wget -q $NESSUS_URL -O /tmp/Nessus-10.7.3-raspberrypios_armhf.deb >/dev/null 2>&1 &
show_progress "Downloading Nessus" $!
wait $! || error_exit "downloading Nessus"

# Install Nessus
sudo dpkg -i /tmp/Nessus-10.7.3-raspberrypios_armhf.deb >/dev/null 2>&1 &
show_progress "Installing Nessus" $!
wait $! || error_exit "installing Nessus"

# Fix dependencies
sudo apt-get install -f -y >/dev/null 2>&1 &
show_progress "Fixing dependencies" $!
wait $! || error_exit "fixing dependencies"

# Start Nessus service
sudo systemctl start nessusd >/dev/null 2>&1 &
show_progress "Starting Nessus service" $!
wait $! || error_exit "starting Nessus service"

# Enable Nessus service
sudo systemctl enable nessusd >/dev/null 2>&1 &
show_progress "Enabling Nessus service" $!
wait $! || error_exit "enabling Nessus service"

# Link Nessus to Tenable.io
link_nessus $LINKING_KEY

IP_ADDRESS=$(get_ip_address)
PORT=8834

cleanup

echo -e "\033[0;32mINSTALLATION COMPLETE!\033[0m"
echo "Please go here to continue configuration: http://$IP_ADDRESS:$PORT"

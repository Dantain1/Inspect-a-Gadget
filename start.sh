#!/bin/bash

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

show_progress() {
    local -r msg="$1"
    local -r pid="$2"
    local -r delay='0.1'
    local -r width=50
    local completed=0
    while ps -p $pid > /dev/null 2>&1; do
        sleep "$delay"
        completed=$(( (completed + 1) % (width + 1) ))
        printf "\r$msg: [%-${width}s]" $(printf "#%.0s" $(seq 1 $completed))
    done
    printf "\r$msg: [%-${width}s] done\n" $(printf "#%.0s" $(seq 1 $width))
}

error_exit() {
    echo "Error during $1. Exiting."
    exit 1
}

print_ascii_art

sudo apt-get update -y >/dev/null 2>&1 &
show_progress "Updating package lists" $!
wait $! || error_exit "updating package lists"

sudo apt-get upgrade -y >/dev/null 2>&1 &
show_progress "Upgrading installed packages" $!
wait $! || error_exit "upgrading installed packages"

NESSUS_URL="https://www.tenable.com/downloads/api/v2/pages/nessus/files/Nessus-10.7.3-raspberrypios_armhf.deb"
wget $NESSUS_URL -O /tmp/Nessus-10.7.3-raspberrypios_armhf.deb >/dev/null 2>&1 &
show_progress "Downloading Nessus" $!
wait $! || error_exit "downloading Nessus"

sudo dpkg -i /tmp/Nessus-10.7.3-raspberrypios_armhf.deb >/dev/null 2>&1 &
show_progress "Installing Nessus" $!
wait $! || error_exit "installing Nessus"

sudo apt-get install -f -y >/dev/null 2>&1 &
show_progress "Fixing dependencies" $!
wait $! || error_exit "fixing dependencies"

sudo systemctl start nessusd >/dev/null 2>&1 &
show_progress "Starting Nessus service" $!
wait $! || error_exit "starting Nessus service"

sudo systemctl enable nessusd >/dev/null 2>&1 &
show_progress "Enabling Nessus service" $!
wait $! || error_exit "enabling Nessus service"

sudo systemctl status nessusd | head -n 10

echo "Nessus installation and setup complete."

#!/bin/sh

# Check if the script is running as root, if not, re-run it as root
if [ "$(id -u)" -ne 0 ]; then
   sudo "$0"
   exit
fi

# Create the gpio-users group
groupadd gpio-users || echo "Group gpio-users already exists."

# Obtain the current username who invoked sudo
CURRENT_USER=${SUDO_USER:-$(whoami)}

# Add the current user to the gpio-users group
usermod -aG gpio-users "$CURRENT_USER"

# Write the udev rule
echo 'KERNEL=="gpiochip0", OWNER="10001", GROUP="gpio-users", MODE="0660"' > /etc/udev/rules.d/99-gpiochip.rules

# Reload the udev rules
udevadm control --reload-rules
udevadm trigger

echo "Script execution completed. User $CURRENT_USER added to gpio-users and udev rule set."

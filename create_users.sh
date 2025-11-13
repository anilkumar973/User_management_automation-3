#!/bin/bash
# ==========================================================
# Script Name: create_users.sh
# Purpose: Automate creation of users and groups from file.
# Author: SysOps Team
# ==========================================================

# Files and directories
INPUT_FILE="$1"
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

# Ensure log and password directories exist
sudo mkdir -p /var/secure
sudo touch "$LOG_FILE" "$PASSWORD_FILE"
sudo chmod 755 "$LOG_FILE"
sudo chmod 600 "$PASSWORD_FILE"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE" > /dev/null
}

# Check if input file provided
if [[ -z "$INPUT_FILE" ]]; then
    echo "Usage: sudo ./create_users.sh <input_file>"
    exit 1
fi

# Check if input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
    log_message "ERROR: Input file $INPUT_FILE not found."
    exit 1
fi

log_message "===== Starting User Creation Process ====="

# Read the file line by line
while IFS=';' read -r username groups; do
    # Skip empty lines or comments
    [[ -z "$username" || "$username" =~ ^# ]] && continue

    # Remove spaces
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs | tr -d ' ')

    # If user already exists, skip
    if id "$username" &>/dev/null; then
        log_message "INFO: User '$username' already exists. Skipping."
        continue
    fi

    # Create user and their primary group
    log_message "INFO: Creating user '$username'..."
    sudo useradd -m -s /bin/bash "$username"
    if [[ $? -ne 0 ]]; then
        log_message "ERROR: Failed to create user '$username'."
        continue
    fi

    # Add additional groups
    if [[ -n "$groups" ]]; then
        for grp in $(echo "$groups" | tr ',' ' '); do
            # Create group if it doesn’t exist
            if ! getent group "$grp" >/dev/null; then
                sudo groupadd "$grp"
                log_message "INFO: Group '$grp' created."
            fi
            sudo usermod -aG "$grp" "$username"
        done
    fi

    # Set permissions for home directory
    sudo chown -R "$username":"$username" "/home/$username"
    sudo chmod 700 "/home/$username"

    # Generate random 12-character password
    password=$(openssl rand -base64 12)

    # Set user password
    echo "$username:$password" | sudo chpasswd

    # Save credentials securely
    echo "$username : $password" | sudo tee -a "$PASSWORD_FILE" > /dev/null

    log_message "SUCCESS: User '$username' created successfully."

done < "$INPUT_FILE"

log_message "===== User Creation Completed ====="
echo "All actions logged in: $LOG_FILE"
echo "Passwords saved in: $PASSWORD_FILE"

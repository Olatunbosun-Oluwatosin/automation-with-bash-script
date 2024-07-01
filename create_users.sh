#!/bin/bash

# Script to create users and groups, set up home directories, generate passwords,
# and log actions.

# Log file path
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

# Function to log messages
log_message() {
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> $LOG_FILE
}

# Function to generate a random password
generate_password() {
    local password_length=12
    tr -dc A-Za-z0-9 </dev/urandom | head -c $password_length
}

# Ensure the secure directory exists
if [ ! -d /var/secure ]; then
    mkdir -p /var/secure
    chmod 700 /var/secure
    log_message "Created /var/secure directory with 700 permissions."
fi

# Ensure the log file exists
touch $LOG_FILE
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <user_file>"
    exit 1
fi

USER_FILE="$1"

# Check if the user file exists
if [ ! -f "$USER_FILE" ]; then
    echo "User file not found: $USER_FILE"
    exit 1
fi

# Read the user file line by line
while IFS=';' read -r username groups; do
    # Skip empty lines or lines without proper format
    if [ -z "$username" ] || [ -z "$groups" ]; then
        log_message "Skipped invalid line: username='$username', groups='$groups'"
        continue
    fi

    # Check if the user already exists
    if id -u "$username" >/dev/null 2>&1; then
        log_message "User $username already exists."
        continue
    fi

    # Create groups if they don't exist
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        if ! getent group "$group" >/dev/null 2>&1; then
            groupadd "$group"
            log_message "Created group $group."
        fi
    done

    # Create the user with the specified groups
    useradd -m -G "$groups" "$username" -s /bin/bash
    if [ $? -eq 0 ]; then
        log_message "Created user $username with groups $groups."
    else
        log_message "Failed to create user $username."
        continue
    fi

    # Set up home directory permissions
    chmod 700 /home/"$username"
    chown "$username":"$username" /home/"$username"
    log_message "Set permissions for home directory of $username."

    # Generate a random password
    password=$(generate_password)
    echo "$username:$password" | chpasswd
    log_message "Set password for user $username."

    # Store the password securely
    echo "$username:$password" >> $PASSWORD_FILE
done < "$USER_FILE"

log_message "User creation script completed."

echo "Script execution completed. Check $LOG_FILE for details."


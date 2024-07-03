#!/bin/bash

# Script to create users and groups, set up home directories, generate passwords,
# and log actions.

# Log file path
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"
ENCRYPTION_KEY="/var/secure/encryption_key.txt"

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

# Ensure the log file and encryption key exist
touch $LOG_FILE
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Generate encryption key if it doesn't exist
if [ ! -f "$ENCRYPTION_KEY" ]; then
    openssl rand -base64 32 > $ENCRYPTION_KEY
    chmod 600 $ENCRYPTION_KEY
    log_message "Generated encryption key."
fi

# Function to encrypt password
encrypt_password() {
    local password=$1
    local encrypted_password=$(echo -n "$password" | openssl enc -aes-256-cbc -base64 -pass file:$ENCRYPTION_KEY)
    echo $encrypted_password
}

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

    # Create user-specific group if it doesn't exist
    if ! getent group "$username" >/dev/null 2>&1; then
        groupadd "$username"
        log_message "Created group $username."
    fi

    # Create the user with the user-specific group
    useradd -m -g "$username" -s /bin/bash "$username"
    if [ $? -eq 0 ]; then
        log_message "Created user $username with personal group $username."
    else
        log_message "Failed to create user $username."
        continue
    fi

    # Add user to the specified groups
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        if ! getent group "$group" >/dev/null 2>&1; then
            groupadd "$group"
            log_message "Created group $group."
        fi
        usermod -aG "$group" "$username"
        log_message "Added user $username to group $group."
    done

    # Set up home directory permissions
    chmod 700 /home/"$username"
    chown "$username":"$username" /home/"$username"
    log_message "Set permissions for home directory of $username."

    # Generate a random password
    password=$(generate_password)
    echo "$username:$password" | chpasswd
    log_message "Set password for user $username."

    # Encrypt and store the password securely
    encrypted_password=$(encrypt_password "$password")
    echo "$username:$encrypted_password" >> $PASSWORD_FILE
done < "$USER_FILE"

log_message "User creation script completed."

echo "Script execution completed. Check $LOG_FILE for details."





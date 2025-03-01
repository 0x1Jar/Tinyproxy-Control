#!/bin/bash

# Author: 0x1Jar
# Function to display ASCII art with "TinySetup" text
ascii_art() {
  echo " | _______________ |     TinySetup"
  echo " | |XXXXXXXXXXXXX| |"
  echo " | |XXXXXXXXXXXXX| |"
  echo " | |XXXXXXXXXXXXX| |"
  echo " | |XXXXXXXXXXXXX| |"
  echo " | |XXXXXXXXXXXXX| |"
  echo " |_________________|"
  echo "     _[_______]_"
  echo " ___[___________]___"
  echo "|         [_____] []|__"
  echo "|         [_____] []|  \\__"
  echo "L___________________J     \\ \\___\/"
  echo " ___________________      /\ "
  echo " |     0x1Jar      |    (__)"
  echo "/###################\\    (__)"
}

# Function to enable authentication
enable_auth() {
  echo "================================="
  sudo sed -i '/^#BasicAuth/s/^#//' /etc/tinyproxy/tinyproxy.conf
  sudo systemctl restart tinyproxy.service
  echo "Authentication enabled."
  # Extract and display username and password
  auth_line=$(sudo grep '^BasicAuth' /etc/tinyproxy/tinyproxy.conf)
  if [[ -n "$auth_line" ]]; then
    username=$(echo "$auth_line" | awk '{print $2}')
    password=$(echo "$auth_line" | awk '{print $3}')
    echo "Username: $username"
    echo "Password: $password"
  else
    echo "Error: Could not retrieve username and password."
  fi
  echo "================================="
}

# Function to disable authentication
disable_auth() {
  echo "================================="
  sudo sed -i '/^BasicAuth/s/^/#/' /etc/tinyproxy/tinyproxy.conf
  sudo systemctl restart tinyproxy.service
  echo "Authentication disabled."
  echo "================================="
}

# Function to restart tinyproxy
restart_tinyproxy() {
  echo "================================="
  sudo systemctl restart tinyproxy.service
  echo "Tinyproxy restarted."
  echo "================================="
}

# Function to check tinyproxy status
check_tinyproxy_status() {
  echo "================================="
  if systemctl is-active --quiet tinyproxy.service; then
    echo "Tinyproxy is running."
  else
    echo "Tinyproxy is NOT running."
  fi
  echo "================================="
}

# Function to stop tinyproxy service
stop_tinyproxy() {
  echo "================================="
  sudo systemctl stop tinyproxy.service
  echo "Tinyproxy stopped."
  echo "================================="
}

# Function to start tinyproxy service
start_tinyproxy() {
  echo "================================="
  sudo systemctl start tinyproxy.service
  echo "Tinyproxy started."
  echo "================================="
}

# Function to change tinyproxy port
change_tinyproxy_port() {
  read -p "Enter the new port number: " new_port
  if [[ -n "$new_port" && "$new_port" =~ ^[0-9]+$ && "$new_port" -ge 1 && "$new_port" -le 65535 ]]; then # Check if it is a number and within valid range.
      echo "================================="
      if sudo sed -i "s/^Port .*/Port $new_port/" /etc/tinyproxy/tinyproxy.conf; then
          sudo systemctl restart tinyproxy.service
          echo "Tinyproxy port changed to $new_port."
          # Update the default port variable
          DEFAULT_PORT=$new_port
          echo "Scanning port $new_port..."
          # Automatically check new port
          public_ip=$(curl -s ifconfig.me)
          if nmap -p "$new_port" -Pn "$public_ip" | grep -q "$new_port/tcp open"; then
              echo "Tinyproxy port $new_port is open on $public_ip."
          else
              echo "Tinyproxy port $new_port is NOT open on $public_ip. Check Tinyproxy configuration."
          fi
          echo "Remember to update your VPS inbound network security rules to allow traffic on port $new_port."
      else
          echo "Error: Failed to change Tinyproxy port."
      fi
      echo "================================="
  else
      echo "Invalid port number. Please enter a number between 1 and 65535."
  fi
}

# Initial setup (run only once)
if [ ! -f /etc/tinyproxy/tinyproxy.conf ]; then
  sudo apt update -y
  sudo apt install tinyproxy -y
  if ! sudo grep -q "Allow 0.0.0.0/0" /etc/tinyproxy/tinyproxy.conf; then
      echo "Allow 0.0.0.0/0" | sudo tee -a /etc/tinyproxy/tinyproxy.conf
  fi
  if ! sudo grep -q "#BasicAuth user123 pass123" /etc/tinyproxy/tinyproxy.conf; then
      echo "#BasicAuth user123 pass123" | sudo tee -a /etc/tinyproxy/tinyproxy.conf # Default: auth disabled
  fi
  sudo systemctl restart tinyproxy.service
  echo "Tinyproxy initial setup complete (authentication disabled by default)."
else
    echo "Tinyproxy already installed, skipping setup."
fi

# Check if nmap is installed, and install if not
if ! command -v nmap &> /dev/null; then
  sudo apt update -y
  sudo apt install nmap -y
  echo "nmap installed."
fi

# Set default port variable
DEFAULT_PORT=$(grep ^Port /etc/tinyproxy/tinyproxy.conf | awk '{print $2}')

# Main menu
while true; do
  ascii_art
  echo "================================"
  echo "Tinyproxy Control Menu"
  echo "1. Check Tinyproxy Status"
  echo "2. Enable Authentication"
  echo "3. Disable Authentication"
  echo "4. Restart Tinyproxy"
  echo "5. Check Tinyproxy Service Status"
  echo "6. Stop Tinyproxy Service"
  echo "7. Start Tinyproxy Service"
  echo "8. Change Tinyproxy Port"
  echo "9. Exit"
  read -p "Enter your choice: " choice

  case "$choice" in
    1)
      echo "================================="
      # Automatically get public IP from ifconfig.me
      public_ip=$(curl -s ifconfig.me)

      # Check if ifconfig.me returned an IP address
      if [[ -z "$public_ip" ]]; then
        echo "Error: Could not retrieve public IP from ifconfig.me."
        continue # Restart the loop
      fi

      # Check if tinyproxy is running
      if ! systemctl is-active --quiet tinyproxy.service; then
        echo "Tinyproxy is NOT running. Restarting..."
        sudo systemctl restart tinyproxy.service
      fi

      # Check if the port is open using nmap
      if nmap -p "$DEFAULT_PORT" -Pn "$public_ip" | grep -q "$DEFAULT_PORT/tcp open"; then
        echo "Tinyproxy port $DEFAULT_PORT is open on $public_ip."
        echo "Public IP: $public_ip"
        echo "Port: $DEFAULT_PORT"
      else
        echo "Tinyproxy port $DEFAULT_PORT is NOT open on $public_ip. Check Tinyproxy configuration."
      fi
      echo "================================="
      ;;
    2)
      enable_auth
      ;;
    3)
      disable_auth
      ;;
    4)
      restart_tinyproxy
      ;;
    5)
      check_tinyproxy_status
      ;;
    6)
      stop_tinyproxy
      ;;
    7)
      start_tinyproxy
      ;;
    8)
      change_tinyproxy_port
      ;;
    9)
      echo "Exiting."
      exit 0
      ;;
    *)
      echo "Invalid choice. Please try again."
      ;;
  esac
done

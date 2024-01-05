#!/bin/bash

# check NTP synchronization
check_ntp_sync() {
    if timedatectl status | grep -q 'synchronized: yes'; then
        return 0
    else
        return 1
    fi
}

# check web service availability
check_web_service() {
    # Extract the password from the Docker command output
    password=$(docker exec ladiesfirst /doorctrl --access | grep 'Current code: ' | awk '{print $3}' | tr -d '\r')

    if curl -s -o /dev/null -w "%{http_code}" -u admin:$password http://localhost:3000/api/ladiesfirst/door | grep -q '200'; then
        return 0
    else
        return 1
    fi
}

trap 'echo "Error occurred. Continuing..."; continue' ERR

# loop until available
while true; do
    if check_ntp_sync && check_web_service; then
        echo "NTP synchronized and web service is available. Proceeding with script."
        break
    else
        echo "Waiting for NTP sync and web service availability..."
        sleep 5
    fi
done

# get the current time in hours and minutes
get_current_time() {
    date +%H:%M
}

# door open times
current_time=$(get_current_time)
start_time="09:50"
end_time="20:50"

# Extract the password from the Docker command output
password=$(docker exec ladiesfirst /doorctrl --access | grep 'Current code: ' | awk '{print $3}' | tr -d '\r')

if [[ "$current_time" > "$start_time" && "$current_time" < "$end_time" ]]; then
    echo "Time is within range. Sending sensor signal."
    curl -X POST -u admin:$password http://localhost:3000/api/ladiesfirst/door/sensor
else
    echo "Time is out of range. Closing the door."
    curl -X POST -u admin:$password http://localhost:3000/api/ladiesfirst/door/close
fi

# NOTE:: execute pi_juice_poweron_config.py here

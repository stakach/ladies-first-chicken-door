#!/bin/bash

echo "Setting door to sensor mode"

# Extract the password from the Docker command output
password=$(docker exec ladiesfirst /doorctrl --access | grep 'Current code: ' | awk '{print $3}' | tr -d '\r')

curl -v -X POST -u admin:$password http://localhost:3000/api/ladiesfirst/door/sensor

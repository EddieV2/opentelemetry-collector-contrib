#!/bin/bash

# Path to your Python script
PYTHON_SCRIPT_PATH="./userlookup.py"

# Execute the Python script and capture the output
eval "$($PYTHON_SCRIPT_PATH)"

# Verify the environment variables are set
echo "Team is set to: $SPLUNK_TEAM"
echo "Position is set to: $SPLUNK_POSITION"

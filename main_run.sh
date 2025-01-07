#!/bin/bash

# Fetch environment variables dynamically
echo "Fetching environment variables..."
eval "$(python3 userlookup.py)"

# Verify fetched variables
echo "Team is set to: $SPLUNK_TEAM"
echo "Position is set to: $SPLUNK_POSITION"

# Update agent_config.yaml with hardcoded values
echo "Updating agent_config.yaml with hardcoded values..."
sed -i.bak "s|\${SPLUNK_TEAM}|$SPLUNK_TEAM|g" /path/to/agent_config.yaml
sed -i.bak "s|\${SPLUNK_POSITION}|$SPLUNK_POSITION|g" /path/to/agent_config.yaml

# Start the OpenTelemetry Collector
echo "Starting OpenTelemetry Collector..."
/usr/local/splunk/otelcol --config /path/to/agent_config.yaml

#!/bin/bash

# Simple script to generate test logs for Loki
echo "Generating test logs for Loki..."

for i in {1..10}; do
  echo "Test log entry $i: $(date)"
  logger "Test log entry $i from monitoring test script: $(date)"
  sleep 1
done

echo "Log generation complete!"

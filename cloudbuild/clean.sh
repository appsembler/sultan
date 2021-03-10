#!/bin/bash

echo "Build script exited with status $PREVIOUS_EXIT"

echo "CLEANING UP:"
./sultan instance delete

exit "$PREVIOUS_EXIT"

#!/bin/bash

# Check if all arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <Build Zip Location> <Local Copy Base>"
    exit 1
fi

echo
echo "Installing Builds From Local"

# Variables
BUILD_ZIP="$1"
COPY_BASE_PATH="$2"

if [ ! -d "$COPY_BASE_PATH" ]; then
    echo "Local copy base does not exit: $COPY_BASE_PATH"
    exit 1
fi

echo "Unzipping Builds at $BUILD_ZIP..."

# Unzip
unzip -q $BUILD_ZIP -d $COPY_BASE_PATH

echo "Finished Installing Builds"

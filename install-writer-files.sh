#!/bin/bash

# Check if all arguments are provided
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <GitHub Path> <Branch> <GitHub Username> <GitHub PAT> <Local Copy Base>"
    exit 1
fi

echo
echo "Downloading Writer-Files from GitHub"

# Variables
GITHUB_PATH="$1"
BRANCH="$2"
USERNAME="$3"
PAT="$4"
COPY_BASE_PATH="$5"

# Create temp dir
TEMP_DIR=$(mktemp -d)

# Clone the repository using credentials
CLONE_URL=$(echo "https://github.com/$GITHUB_PATH" | sed "s|://|://${USERNAME}:${PAT}@|")
git clone -b "$BRANCH" "$CLONE_URL" "$TEMP_DIR/writer" --depth 1 --quiet || { echo "Failed to clone repository"; exit 1; }

echo "Processing writer files (unzipping, copying files, etc)"

# Run the Python script with the base paths
python3 process-writer-files.py "$TEMP_DIR/writer" "$COPY_BASE_PATH" || { echo "Python script execution failed"; exit 1; }

# Remove the repository directory
rm -rf "$TEMP_DIR"

echo "Finished Downloading Writer-Files"

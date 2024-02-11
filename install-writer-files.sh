#!/bin/bash

# Check if all arguments are provided
if [ "$#" -ne 8 ]; then
    echo "Usage: $0 <GitHub Path> <Branch> <GitHub Username> <GitHub PAT> <Local Copy Base> <Config GitHub Path> <Config GitHub Branch> <Config GitHub Filepath>"
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
CONFIG_GITHUB_PATH="$6"
CONFIG_GITHUB_BRANCH="$7"
CONFIG_GITHUB_FILEPATH="$8"

# Create temp dir
TEMP_DIR=$(mktemp -d)

# Clone the repository using credentials
CLONE_URL=$(echo "https://github.com/$GITHUB_PATH" | sed "s|://|://${USERNAME}:${PAT}@|")
git clone -b "$BRANCH" "$CLONE_URL" "$TEMP_DIR/writer" --depth 1 --quiet || { echo "Failed to clone repository"; exit 1; }

echo "Processing writer files (unzipping, copying files, etc)"

# Download the file mappings from the config
CONFIG_TARGET="$TEMP_DIR/writer/${CONFIG_GITHUB_FILEPATH}"
CONFIG_URL="https://raw.githubusercontent.com/${CONFIG_GITHUB_PATH}/${CONFIG_GITHUB_BRANCH}/${CONFIG_GITHUB_FILEPATH}"
echo "Downloading file mappings from $CONFIG_URL to local $CONFIG_TARGET"
curl -sL -H "Authorization: token ${PAT}" "$CONFIG_URL" --output "$CONFIG_TARGET"

# Run the Python script with the base paths
echo "Processing writer files (unzipping, copying files, etc)"
python3 process-writer-files.py "$TEMP_DIR/writer" "$COPY_BASE_PATH" "$CONFIG_GITHUB_FILEPATH" || { echo "Python script execution failed"; exit 1; }

# Remove the repository directory
rm -rf "$TEMP_DIR"

echo "Finished Downloading Writer-Files"

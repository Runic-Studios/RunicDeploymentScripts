#!/bin/bash

# Check if all arguments are provided
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 <GitHub Username> <GitHub PAT> <Local Copy Base> <Config GitHub Path> <Config GitHub Branch> <Config GitHub Filepath>"
    exit 1
fi

echo
echo "Downloading Writer-Files from GitHub"

# Variables
USERNAME="$1"
PAT="$2"
COPY_BASE_PATH="$3"
CONFIG_GITHUB_PATH="$4"
CONFIG_GITHUB_BRANCH="$5"
CONFIG_GITHUB_FILEPATH="$6"

# Create temp dir
TEMP_DIR=$(mktemp -d)

# Download the file mappings from the config
CONFIG_TARGET="$TEMP_DIR/${CONFIG_GITHUB_FILEPATH}"
CONFIG_URL="https://raw.githubusercontent.com/${CONFIG_GITHUB_PATH}/${CONFIG_GITHUB_BRANCH}/${CONFIG_GITHUB_FILEPATH}"
echo "Downloading file mappings $CONFIG_GITHUB_FILEPATH from $CONFIG_GITHUB_PATH:$CONFIG_GITHUB_BRANCH to local"
curl -sL -H "Authorization: token ${PAT}" "$CONFIG_URL" --output "$CONFIG_TARGET"

# Parse file mappings for writer-files target
GITHUB_PATH=$(yq e '.repo.path' "$CONFIG_TARGET")
GITHUB_BRANCH=$(yq e '.repo.branch' "$CONFIG_TARGET")
echo "Found writer-files targets at $GITHUB_PATH:$GITHUB_BRANCH"

# Clone writer-files
echo "Cloning writer-files locally"
CLONE_URL=$(echo "https://github.com/$GITHUB_PATH" | sed "s|://|://${USERNAME}:${PAT}@|")
git clone -b "$GITHUB_BRANCH" "$CLONE_URL" "$TEMP_DIR/writer" --depth 1 --quiet || { echo "Failed to clone repository"; exit 1; }

# Move mappings into github dir
mv "$CONFIG_TARGET" "$TEMP_DIR/writer"

# Run the Python script with the base paths
echo "Processing writer files (unzipping, copying files, etc)"
python3 process-writer-files.py "$TEMP_DIR/writer" "$COPY_BASE_PATH" "$CONFIG_GITHUB_FILEPATH" || { echo "Python script execution failed"; exit 1; }

# Remove the repository directory
rm -rf "$TEMP_DIR"

echo "Finished Downloading Writer-Files"

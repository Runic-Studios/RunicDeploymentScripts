#!/bin/bash

# Check if all arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <Github Path> <GitHub PAT> <GitHub Artifact ID> <Local Folder>"
    exit 1
fi

echo
echo "Downloading Plugins from GitHub Artifacts"

# Assign arguments to variables
GITHUB_PATH=$1
GITHUB_PAT=$2
GITHUB_ARTIFACT=$3
LOCAL_FOLDER=$4

# Create a temporary directory
TEMP_DIR=$(mktemp -d)

# Change to the temporary directory
cd $TEMP_DIR

# Download the artifact
echo "Downloading artifact to $TEMP_DIR..."

# Json filter for getting just the archive download URL from the github API
PARSER=".artifacts[] | select(.id == $GITHUB_ARTIFACT) | .archive_download_url"
ASSET=`curl -sL -H "Authorization: token $GITHUB_PAT" -H "Accept: application/vnd.github.v3.raw" https://api.github.com/repos/$GITHUB_PATH/actions/artifacts | jq -r "$PARSER"`
if [ "$ASSET" = "null" ]; then
    echo "ERROR: could not find latest artifact"
    exit 1
else
    echo "Downloading artifact $ASSET"
fi

# Curl the actual latest artifact url with auth
curl -sL -H "Authorization: token $GITHUB_PAT" "$ASSET" --output artifact.zip

# Check if the download was successful
if [ ! -f artifact.zip ]; then
    echo "Failed to download the artifact."
    exit 1
fi

# Unzip the artifact
echo "Unzipping artifact..."
unzip -q artifact.zip

# Check if the unzip was successful
if [ $? -ne 0 ]; then
    echo "Failed to unzip the artifact."
    exit 1
fi

# Delete artifact zip
rm artifact.zip

# Go back to the original directory
cd -

# Copy the contents of temp dir to the local folder
echo "Copying files to $LOCAL_FOLDER..."
cp -rf $TEMP_DIR/* "$LOCAL_FOLDER"

# Clean up the temporary directory
rm -rf $TEMP_DIR

echo "Finished Installing Plugins"

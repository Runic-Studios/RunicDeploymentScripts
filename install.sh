#!/bin/bash

# Check if all arguments are provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <Server Dir>"
    exit 1
fi

SERVER_DIR="$1"

### CD INTO SCRIPT DIR
echo "Entering Script Directory ${0%/*}"

cd "${0%/*}"

echo

### LOAD CONFIGURATION

# Key value pairs that we use for conf-parse.py
KVP=""

# Function to load key-value pairs from a file
load_config() {
    local config_file="$1"

    # Check if the configuration file exists
    if [ ! -f "$config_file" ]; then
        echo "Configuration file not found: $config_file"
        return 1
    fi

    # Read each line from the configuration file
    while IFS='=' read -r key value; do
        # Skip empty lines and lines starting with #
        if [[ -z "$key" || $key == \#* ]]; then
            continue
        fi

        # Export the key-value pair as a variable
        export "$key=$value"
        KVP+="$key=$value,"
        if [ $# -eq 1 ]; then
            echo "Loaded $key=$value"
        else
            echo "Loaded $key=SECRET"
        fi
    done < "$config_file"
}

# Load variables from install.conf
echo "Loading install.conf"
load_config "install.conf"

echo

# Load variables from secrets.conf
echo "Loading secrets.conf"
load_config "secrets.conf" 1

echo

### INSTALL
# These have their own prints

./install-plugins.sh $PLUGINS_GITHUB_PATH $PLUGINS_GITHUB_ARTIFACT_PAT $PLUGINS_GITHUB_ARTIFACT_ID "$SERVER_DIR/plugins"

./install-writer-files.sh $CONFIG_GITHUB_USERNAME $CONFIG_GITHUB_PAT $SERVER_DIR $CONFIG_GITHUB_PATH $CONFIG_GITHUB_BRANCH $CONFIG_GITHUB_FILEPATH

./install-build.sh "$BUILD_ARTIFACT_DIR/$BUILD_ARTIFACT_TARGET.zip" $SERVER_DIR

echo

### MODIFY SERVER VALUES
echo "Loading config values from $INSTANCE_CONF"

python3 conf-parse.py $INSTANCE_CONF $SERVER_DIR $KVP
echo


echo "Done!"

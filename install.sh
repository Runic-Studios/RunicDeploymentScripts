#!/bin/bash

### CD INTO SCRIPT DIR
echo "Entering Script Directory ${0%/*}"

cd "${0%/*}"

echo

### LOAD CONFIGURATION

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

./install-plugins.sh $PLUGINS_GITHUB_PATH $PLUGINS_GITHUB_ARTIFACT_PAT $PLUGINS_GITHUB_ARTIFACT_ID $PLUGINS_LOCAL_FOLDER

./install-writer-files.sh $WRITER_GITHUB_PATH $WRITER_GITHUB_BRANCH $WRITER_GITHUB_USERNAME $WRITER_GITHUB_PAT $WRITER_BASE_PATH

./install-build.sh "$BUILD_ARTIFACT_DIR/$BUILD_ARTIFACT_TARGET.zip" $BUILD_BASE_PATH

echo

### MODIFY SERVER VALUES
echo "Loading config values from $INSTANCE_CONF"

python3 conf-parse.py $INSTANCE_CONF ..
echo



echo "Done!"

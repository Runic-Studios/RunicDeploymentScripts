

# RunicDeploymentScripts

## Overview
This repository contains a set of scripts used for deploying a Runic Realms game instance from a "base image" that only contains non-RR files and static configuration files (that do not change between releases and server types).

 These scripts will attempt to perform four actions:

-  Download a zip file of all of our RR plugins from the GitHub API. 
	- These are built automatically with a GitHub workflow located in the base directory of the superproject.
- Download writer files from the RunicRealmsGithub/writer-files repository
- Unzip a copy of the build files from a certain location locally on the server installing this
	- The build server has a plugin named RunicBuildServer which has an `/export` command allowing you to create artifacts of the build server files automatically. These are stored in `/home/mch/multicraft/build-artifacts`.
- Modify a decently large set of configuration files throughout the server directory using an <b>instance template</b>, which is a YML file containing various configuration information.
	- This file could indicate for example, that we need to modify the `RunicDatabase/config.yml`  database key to point to the `live` Mongo Database for live servers. A different instance template for writer servers would contain different information.

## Prerequisites
-  `sudo apt-get update`
-  Install jq `sudo apt-get install jq`
-  Install yq `sudo add-apt-repository ppa:rmescandon/yq` then `sudo apt install yq -y`
-  Install python3 `sudo apt-get install python3`
-  Install pip `sudo apt-get install pip`
-  Bash interpreter at `/bin/bash`
- `pip install ruamel.yaml`

## Scripts

### Configuration:
- `install.conf`: The most important file. Here you modify a variety of different configuration files necessary for the install.sh script:
	- `CONFIG_GITHUB_PATH`: This should be unchanging and set to `RunicRealmsGithub/writer-files-config`, just indicates which GitHub repository to look for file mappings configurations (these are instructions about how to download writer files)
	- `CONFIG_GITHUB_BRANCH`: The branch of `CONFIG_GITHUB_PATH` to target, should be unchanging and set to `main`.
  	- `CONFIG_GITHUB_FILEPATH`: You may need to change this, it specifies which file to look for in the `CONFIG_GITHUB_PATH` repository's file mappings. The difference between files should include a different `repo.branch` key, this is the branch of the `writer-files` repo that will be downloaded.
	- `PLUGINS_GITHUB_PATH`: This should be an unchanging `Runic-Studios/RunicRealms`, which is the superproject from which we download the artifacts of our plugins
	- `PLUGINS_GITHUB_ARTIFACT_ID`: This is obtained by going to `Runic-Studios/RunicRealms`, clicking on `Actions`, selecting the workflow with the correct plugin version on it, going to the most recent workflow run (or whichever one we want to download plugins from), right clicking the `plugins-zip` artifact at the bottom of the page, hitting "Copy Link Address", and the from that address, copying only the last number at the end (the Artifact ID)
	- `BUILD_ARTIFACT_DIR`: This should be an unchanging `/home/mch/multicraft/build-artifacts` as that is the target of the `RunicBuildServer` plugin's `/export` command.
	- `BUILD_ARTIFACT_TARGET`: This should be the name of the build artifact that we want to target. When you create an export on the build server with `/export`, you will also have given it a "tag" (aka a name). This tag is what you use here.
	- `INSTANCE_CONF`: Set this to the instance template we want to load. For example, the live instance template might be `instance-conf/live-instance.yml`.

- `secrets.conf`: This file is not uploaded to GitHub to keep our API tokens a secret. But it contains two keys:
	- `CONFIG_GITHUB_PAT`: The personal access token belonging to @RunicRealmsGithub for accessing its own `writer-files-config` repository. This is the same one as that which is used for File Pull. <b>This must also have access to the subsequent `writer-files` repository mentioned in the `file-mappings-VERSION.yml` of `writer-files-config`</b>.
	- `CONFIG_GITHUB_USERNAME`: The name of the user that is going to be <i>accessing</i> this repository through GitHub's API. The secret token in secrets.conf must correspond to this user. <b>This must also have access to the subsequent `writer-files` repository mentioned in the `file-mappings-VERSION.yml` of `writer-files-config`</b>.
	- `PLUGINS_GITHUB_ARTIFACT_PAT`: This is also owned by @RunicRealmsGithub but contains access only for reading artifacts in the `Runic-Studios/RunicRealms` superproject.
		- Because this uses the newer GitHub PAT system, this will expire in December 2024 and need to be regenerated.

### Executables:
- `install.sh`: Runs everything one after the other
- `install-plugins.sh`: Downloads artifacts from GitHub with provided credentials and artifact ID, unzips them into the plugins folder
- `install-writer-files.sh`: Downloads the writer-files-config from GitHub with provided credentials
- `process-writer-files.py`: Reads a special file within the downloaded writer-files-config called `file-mappings-VERSION.yml`, which indicates how the writer-files should be downloaded and spread throughout the image.
	- This file mappings configuration can contain information like needing to unzip the MythicMobs spawners file, and where each GitHub folder belongs locally (GitHub's `loot` directory needs to go to `plugins/RunicCore/loot`)
		- This mapping is static, but some files such as the spawner zip, NPCs and more are uploaded with the `/filepush` command on writer that syncs all locally modified files (basically files that writers do not modify through GitHub but through commands), with the GitHub remote.
- `install-build.sh`: Unzips the locally specified build artifact into the server directory
- `conf-parse.py`: Parses a YML template under `instance-conf` and performs all copying of YML configuration values, basic key-value delimiter configuration, and replacement/copying of existing files

## Instance Templates
Instance templates are our way of setting custom configuration values depending on the server type (live/writer/dev). These include things like:
- The MOTD
- Max players
- Server port
- Whitelist enabled
- Mongo Database to use
- RunicRestart timer
- FileSync enabled
- Whitelist file
- Ops file
- Server slots
- LuckPerms `server` context

The format of this YML template file is fairly self explanatory, but here is a rundown:
```yml
configurations: # List of all of the files we are going to change
  server-properties: # Arbitrary key
    file: server.properties # File in relation to server directory that we will modify
    actions:
    - type: edit # Edit this file
      format:
        type: base # Basic key-value system
        delimiter: "=" # The character that distinguishes the keys and the values in this file
      set: # Keys to set
        whitelist: false
        # etc
  runic-database:
    file: plugins/RunicDatabase/config.yml
    actions:
    - type: edit
      format:
        type: yml # Edit as a YML file
      set:
        database: play # Change YML value
  ops:
    file: ops.json
    actions:
    - type: replace # Replace this file with a local one inside instance-conf/
      target: ./ops-live.json # Replacement file, will be copied and renamed
  # ETC
```

One important note is that the replacements in these instance templates can always reference any variable that exists in `secrets.conf` or `install.conf` with a dollar sign in front.
You can also define new variables in either of these files just for use in templates.

When replacing/copying files, the `target` path of those replacements stems from the `instance-conf` configurations directory.

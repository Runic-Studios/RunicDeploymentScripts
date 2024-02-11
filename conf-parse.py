import argparse
from ruamel.yaml import YAML
import os
import shutil

yaml = YAML()
yaml.preserve_quotes = True

def replace_kvp(source, kvp_dict) -> str:
    if isinstance(source, str):
        for key, value in kvp_dict.items():
            source = source.replace(f"${key}", value)
    return source

def load_yaml(file_path):
    with open(file_path, 'r') as file:
        return yaml.load(file)

def save_yaml(data, file_path):
    with open(file_path, 'w') as file:
        yaml.dump(data, file)

def edit_yaml(file_path, changes, kvp_dict):
    data = load_yaml(file_path)
    for key, value in changes.items():
        data[key] = value
        print("Set " + key + ": " + str(value))
    save_yaml(data, file_path)
    with open(file_path, 'r') as file:
        lines = file.readlines()
    modified_lines = []
    for line in lines:
        modified_lines.append(replace_kvp(line, kvp_dict))
    with open(file_path, 'w') as file:
        file.writelines(modified_lines)

def edit_basic(file_path, changes, delimiter, kvp_dict):
    with open(file_path, 'r') as file:
        lines = file.readlines()
    new_lines = []
    for line in lines:
        if delimiter in line:
            key, value = line.strip().split(delimiter, 1)
            if key in changes:
                replacement = replace_kvp(changes[key], kvp_dict)
                line = f"{key}{delimiter}{replacement}\n"
                print("Set " + key + delimiter + str(changes[key]))
        new_lines.append(line)
    with open(file_path, 'w') as file:
        file.writelines(new_lines)

def replace_file(source, target, kvp_dict):
    with open(source, 'r') as input_file:
        lines = input_file.readlines()
    modified_lines = []
    for line in lines:
        modified_lines.append(replace_kvp(line, kvp_dict))
    with open(target, 'w') as output_file:
        output_file.writelines(modified_lines)
    print("Replaced " + str(target) + " with " + str(source))

def process_configurations(config_file, base_dir, kvp_str):
    kvp_list = kvp_str.split(',')
    kvp_dict = {pair.split('=')[0]: pair.split('=')[1] for pair in kvp_list if len(pair.split('=')) == 2}

    configurations = load_yaml(config_file)
    config_file_parent = os.path.dirname(config_file)
    for key, config in configurations['configurations'].items():
        file_path = os.path.join(base_dir, config['file'])
        print("Configuring " + config['file'])
        for action in config['actions']:
            if action['type'] == 'edit':
                format_type = action['format']['type']
                changes = action.get('set', {})
                if format_type == 'yml':
                    edit_yaml(file_path, changes, kvp_dict)
                elif format_type == 'basic':
                    delimiter = action['format']['delimiter']
                    edit_basic(file_path, changes, delimiter, kvp_dict)
            elif action['type'] == 'replace':
                target = os.path.join(config_file_parent, action['target'])
                replace_file(target, file_path, kvp_dict)

def main():
    parser = argparse.ArgumentParser(description="Modify configuration files based on a YAML configuration.")
    parser.add_argument("config_file", help="The YAML configuration file.")
    parser.add_argument("base_dir", help="The base directory for configuration files.")
    parser.add_argument("kvp", help="A string with vars separated like KEY1=VAR1,KEY2=VAR2,...")

    args = parser.parse_args()

    process_configurations(args.config_file, args.base_dir, args.kvp)

if __name__ == "__main__":
    main()

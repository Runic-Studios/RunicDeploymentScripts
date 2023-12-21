import argparse
from ruamel.yaml import YAML
import os
import shutil

yaml = YAML()
yaml.preserve_quotes = True

def load_yaml(file_path):
    with open(file_path, 'r') as file:
        return yaml.load(file)

def save_yaml(data, file_path):
    with open(file_path, 'w') as file:
        yaml.dump(data, file)

def edit_yaml(file_path, changes):
    data = load_yaml(file_path)
    for key, value in changes.items():
        data[key] = value
        print("Set " + key + ": " + str(value))
    save_yaml(data, file_path)

def edit_basic(file_path, changes, delimiter):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    new_lines = []
    for line in lines:
        if delimiter in line:
            key, value = line.strip().split(delimiter, 1)
            if key in changes:
                line = f"{key}{delimiter}{changes[key]}\n"
                print("Set " + key + delimiter + str(changes[key]))
        new_lines.append(line)

    with open(file_path, 'w') as file:
        file.writelines(new_lines)

def replace_file(source, target):
    shutil.copy(source, target)
    print("Replaced " + str(target) + " with " + str(source))

def process_configurations(config_file, base_dir):
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
                    edit_yaml(file_path, changes)
                elif format_type == 'basic':
                    delimiter = action['format']['delimiter']
                    edit_basic(file_path, changes, delimiter)
            elif action['type'] == 'replace':
                target = os.path.join(config_file_parent, action['target'])
                replace_file(target, file_path)

def main():
    parser = argparse.ArgumentParser(description="Modify configuration files based on a YAML configuration.")
    parser.add_argument("config_file", help="The YAML configuration file.")
    parser.add_argument("base_dir", help="The base directory for configuration files.")

    args = parser.parse_args()

    process_configurations(args.config_file, args.base_dir)

if __name__ == "__main__":
    main()

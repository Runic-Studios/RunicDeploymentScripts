import os
import shutil
import sys
import yaml
import zipfile

def main(repo_base_path, copy_base_path, mappings_file_location):
    try:
        mappings_file = os.path.join(repo_base_path, mappings_file_location)
        with open(mappings_file, 'r') as file:
            mappings = yaml.safe_load(file)

        for key, paths in mappings.get('targets', {}).items():
            type = paths['type']
            if type == 'folder':
                github_path = os.path.join(repo_base_path, paths['github'])
                local_path = os.path.join(copy_base_path, paths['local'])
                process_folder(github_path, local_path)
            elif type == 'file':
                github_path = os.path.join(repo_base_path, paths['github'])
                local_path = os.path.join(copy_base_path, paths['local'])
                process_single_file(github_path, local_path)
            elif type == 'zip':
                github_path = os.path.join(repo_base_path, paths['github'])
                local_path = os.path.join(copy_base_path, paths['local'])
                process_zipped_file(github_path, local_path)

    except Exception as e:
        print(f"Error: {e}")
        exit(1)

def process_single_file(github_path, local_path):
    if os.path.exists(local_path):
        os.remove(local_path)
    os.makedirs(os.path.dirname(local_path), exist_ok=True)
    shutil.copy(github_path, local_path)

def process_zipped_file(github_path, local_path):
    with zipfile.ZipFile(github_path, 'r') as zip_ref:
        zip_ref.extractall(local_path)

def process_folder(github_path, local_path):
    os.makedirs(local_path, exist_ok=True)
    for filename in os.listdir(github_path):
        shutil.copy(os.path.join(github_path, filename), local_path)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 install-writer-files.py <repo_base_path> <copy_base_path> <mappings_file_location>")
        exit(1)

    repo_base_path = sys.argv[1]
    copy_base_path = sys.argv[2]
    mappings_file_location = sys.argv[3]
    main(repo_base_path, copy_base_path, mappings_file_location)

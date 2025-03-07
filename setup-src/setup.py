import os
import shutil
import sys
import platform

def extract_files_from_executable(source_dir, target_dir):
    if not getattr(sys, 'frozen', False):
        raise RuntimeError("This function can only be used in a bundled executable.")
    base_path = sys._MEIPASS
    source_path = os.path.join(base_path, source_dir)

    if not os.path.exists(source_path):
        raise FileNotFoundError(f"The source directory {source_path} does not exist.")

    if not os.path.exists(target_dir):
        os.makedirs(target_dir)

    for item in os.listdir(source_path):
        s = os.path.join(source_path, item)
        d = os.path.join(target_dir, item)
        if os.path.isdir(s):
            shutil.copytree(s, d, dirs_exist_ok=True)
        else:
            shutil.copy2(s, d)


    # Example usage:
    # extract_files_from_executable('source_folder', '~/ToasterOS/target_folder')
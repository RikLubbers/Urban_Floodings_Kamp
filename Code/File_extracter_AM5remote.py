import os
import shutil
from datetime import datetime

##########################################################################################
# This script is designed to rename and extract all .img files in the subdirectories of a base directory
# to a destination directory. This is useful for extracting all .img files in the subdirectories
# of a base directory to a destination directory, which is useful for further processing.
##########################################################################################


# Function to validate the timestamp format
def validate_timestamp(timestamp):
    try:
        datetime.strptime(timestamp, "%Y-%m-%d-%H-%M-%S")
        return True
    except ValueError:
        return False

# Ask for the timestamp
timestamp = input("Please enter the timestamp to process (format YYYY-MM-DD-HH-MM-SS): ")

if not validate_timestamp(timestamp):
    print("Timestamp format is incorrect. Please use the format YYYY-MM-DD-HH-MM-SS.")
else:
    base_directory = f'D:/AM5_flood_project/out/{timestamp}'
    destination_directory = os.path.join(base_directory, 'All')

    if not os.path.exists(destination_directory):
        os.makedirs(destination_directory)

    renamed_files_count = 0
    copied_files_count = 0

    for dirpath, dirnames, filenames in os.walk(base_directory):
        if 'raster_travel_time_MLC_config_all' in dirpath:
            parts = dirpath.split(os.sep)
            if len(parts) > len(base_directory.split(os.sep)) + 1:
                grandparent_folder_name = parts[-3]
                
                for file in filenames:
                    if file.lower().endswith('.img'):
                        old_file_path = os.path.join(dirpath, file)
                        new_file_name = f"{grandparent_folder_name}.img"
                        new_file_path = os.path.join(dirpath, new_file_name)
                        
                        if not os.path.exists(new_file_path):
                            os.rename(old_file_path, new_file_path)
                            renamed_files_count += 1

    for dirpath, dirnames, filenames in os.walk(base_directory):
        if dirpath != destination_directory:
            for filename in filenames:
                if filename.lower().endswith('.img'):
                    old_file_path = os.path.join(dirpath, filename)
                    new_file_path = os.path.join(destination_directory, filename)
                    
                    if not os.path.exists(new_file_path):
                        shutil.copy2(old_file_path, new_file_path)
                        copied_files_count += 1

    print(f"Renaming complete. {renamed_files_count} files were renamed.")
    print(f"Copying complete. {copied_files_count} files were copied.")

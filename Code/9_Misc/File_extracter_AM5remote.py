import os
import shutil
from datetime import datetime

# Function to validate the timestamp format
def validate_timestamp(timestamp):
    try:
        datetime.strptime(timestamp, "%Y-%m-%d-%H-%M-%S")
        return True
    except ValueError:
        return False

# Ask for the timestamp
timestamp = input("Please enter the timestamp to process (format YYYY-MM-DD-HH-MM-SS): ")

# Validate the timestamp
if not validate_timestamp(timestamp):
    print("Timestamp format is incorrect. Please use the format YYYY-MM-DD-HH-MM-SS.")
else:
    # Define the base directory including the timestamp
    base_directory = f'D:/Onedrive/PhD_Undernutrition_Uganda_Physical_Accessbility/2_Study_2_Flooding_Analysis/AM5_flood_project/out/{timestamp}'
    destination_directory = os.path.join(base_directory, 'All')

    # Create the destination directory if it does not exist
    if not os.path.exists(destination_directory):
        os.makedirs(destination_directory)
    else:
        print("Destination directory already exists.")
    
    # Create the zonalStat directory within the destination directory if it does not exist
    zonalstat_directory = os.path.join(destination_directory, 'zonalStat')
    if not os.path.exists(zonalstat_directory):
        os.makedirs(zonalstat_directory)
    else:
        print("ZonalStat directory already exists.")

# Initialize counters
    renamed_img_files_count = 0
    copied_img_files_count = 0
    copied_zonalstat_count = 0

    # Walk through the directory for renaming and copying
    for dirpath, dirnames, filenames in os.walk(base_directory):
        if 'raster_travel_time_MLC_config_all' in dirpath:
            parts = dirpath.split(os.sep)
            if len(parts) > len(base_directory.split(os.sep)) + 1:
                grandparent_folder_name = parts[-3]  # This should be the grandparent folder
                
                for file in filenames:
                    if file.lower().endswith('.img'):
                        old_file_path = os.path.join(dirpath, file)
                        new_file_name = f"{grandparent_folder_name}.img"
                        new_file_path = os.path.join(dirpath, new_file_name)
                        
                        # Rename the file if the new file name doesn't exist
                        if not os.path.exists(new_file_path):
                            os.rename(old_file_path, new_file_path)
                            renamed_img_files_count += 1
                        
                        # Prepare the path for copying to avoid duplication
                        copy_path = os.path.join(destination_directory, new_file_name)
                        
                        # Check if the file already exists in the destination directory
                        if os.path.exists(os.path.join(destination_directory, file)):
                            print(f"File {file} already exists in the destination directory. Skipping...")
                            continue
                        
                        # Copy the file if it doesn't already exist in the destination directory
                        if not os.path.exists(copy_path):
                            shutil.copy2(new_file_path, copy_path)
                            copied_img_files_count += 1

    # Walk through the directory for copying zonalstat files
    for dirpath, dirnames, filenames in os.walk(base_directory):
        if 'zonalStat' in dirpath:
            parts = dirpath.split(os.sep)
            if len(parts) > len(base_directory.split(os.sep)) + 1:
                grandparent_folder_name = parts[-3]
                
                for file in filenames:
                    if file.lower().endswith('.csv'):
                        old_file_path = os.path.join(dirpath, file)
                        
                        # Prepare the path for copying to the zonalstat subdirectory
                        zonalstat_directory = os.path.join(destination_directory, 'zonalStat')
                        copy_path = os.path.join(zonalstat_directory, file)
                        
                        # Check if the file already exists in the zonalstat subdirectory
                        if os.path.exists(copy_path):
                            print(f"File {file} already exists in the zonalstat directory. Skipping...")
                            continue
                        
                        # Check if the source file exists before copying
                        if os.path.exists(old_file_path):
                            shutil.copy(old_file_path, copy_path)
                            copied_zonalstat_count += 1

    # Print summary
    print(f"Renaming complete. {renamed_img_files_count} .img files were renamed.")
    print(f"Copying complete. {copied_img_files_count} .img files were copied.")
    print(f"ZonalStat copying complete. {copied_zonalstat_count} files were copied.")

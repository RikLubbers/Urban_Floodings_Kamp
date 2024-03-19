import os
import shutil

##########################################################################################
# This script is designed to extract all .img files from the subdirectories of a base directory
# and copy them to a destination directory. This is useful for extracting all .img files from
# the subdirectories of a base directory and copying them to a single directory for further
# processing.

# IT IS ADVISED TO FIRST RUN File_renamer_AM5remote.py TO RENAME THE FILES IN THE SUBDIRECTORIES
##########################################################################################

# Define your base directory and the destination 'All' directory
base_directory = 'D:/AM5_flood_project/out/2024-03-19-16-03-54'
destination_directory = os.path.join(base_directory, 'All')

# Create the destination directory if it does not exist
if not os.path.exists(destination_directory):
    os.makedirs(destination_directory)

# Walk through the directory
for dirpath, dirnames, filenames in os.walk(base_directory):
    for filename in filenames:
        # Check if the file has the '.img' extension
        if filename.lower().endswith('.img'):
            # Construct the old file path
            old_file_path = os.path.join(dirpath, filename)
            
            # Construct the new file path
            new_file_path = os.path.join(destination_directory, filename)

            # Copy the file if it doesn't already exist in the destination directory
            if not os.path.exists(new_file_path):
                shutil.copy2(old_file_path, new_file_path)
                print(f"Copied {old_file_path} to {new_file_path}")
            else:
                print(f"File {new_file_path} already exists, not copied.")

print("Copying complete.")

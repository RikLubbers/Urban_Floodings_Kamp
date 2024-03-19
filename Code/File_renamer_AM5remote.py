import os

# Define your base directory
base_directory = 'D:/AM5_flood_project/out/2024-03-19-10-49-29'

# Walk through the directory
for dirpath, dirnames, filenames in os.walk(base_directory):
    # We want to get the grandparent folder's name for the files we're targeting
    parts = dirpath.split(os.sep)
    if len(parts) > len(base_directory.split(os.sep)) + 1:
        # Get the grandparent folder name
        grandparent_folder_name = parts[-3]  # This should be the grandparent folder, such as 'MLC_flood_20_3600'
        
        for file in filenames:
            # Check if the file has the '.img' extension
            if file.lower().endswith('.img'):
                # Construct the old file path
                old_file_path = os.path.join(dirpath, file)
                
                # Construct the new file name using the grandparent folder name
                new_file_name = f"{grandparent_folder_name}.img"
                
                # Construct the new file path
                new_file_path = os.path.join(dirpath, new_file_name)
                
                # Rename the file if the new file name doesn't exist
                if not os.path.exists(new_file_path):
                    os.rename(old_file_path, new_file_path)
                    print(f"Renamed {old_file_path} to {new_file_path}")
                else:
                    print(f"File {new_file_path} already exists, not renamed.")

print("Renaming complete.")

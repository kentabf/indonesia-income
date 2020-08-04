import os
import pandas as pd



CONVERT_CSV = True



data_dir = "/Users/kenta/desktop/thesis/data_processing/data"

def convert_dta_to_csv(dta_full_path, csv_full_path, print_option = True):
	print_option = True
	df = pd.read_stata(dta_full_path)
	df.to_csv(csv_full_path)
	
	if print_option:
		dta_dir_components = dta_full_path.split("/")
		csv_dir_components = csv_full_path.split("/")
		print("converted " + dta_dir_components[-1] + " to CSV under " + csv_dir_components[-1])


if CONVERT_CSV:
	
	dataset_folders = os.listdir(data_dir)

	for dataset_folder in dataset_folders:
		subset_files_dir = data_dir + "/" + dataset_folder
		if not os.path.isdir(subset_files_dir):
			continue
		subset_files = os.listdir(subset_files_dir)

		for subset_file in subset_files:
			dta_files_dir = subset_files_dir + "/" + subset_file
			if not os.path.isdir(dta_files_dir):
				continue
			files = os.listdir(dta_files_dir)
			dta_files = [file for file in files if file.endswith(".dta")]
			for dta_file in dta_files:

				dta_file_dir = dta_files_dir + "/" + dta_file
				csv_file_dir = dta_file_dir.replace(".dta", ".csv")
				convert_dta_to_csv(dta_file_dir, csv_file_dir)


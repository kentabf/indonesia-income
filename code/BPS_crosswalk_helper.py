import pandas as pd
import csv

data_dir = "data/province_bps_crosswalk/"
rows = [["province_code", "province"]]
with open(data_dir+"pasted.txt", "r") as file:
	lines = file.readlines()
line_num = 1
for line in lines:

	if line_num > 8: # roughly with eyes
		line = line.strip()
		if line.startswith("21"):
			num = 21
			name = "twenty one"
		elif line.startswith("76"):
			num = 76
			name = "West Sulawesi"
		else:
			if line.startswith("\\"):
				line = line[16:-20].strip() # roughly with eyes
			data = line.split(".", 1)
			if len(data) < 2:
				continue
			num = data[0]
			name = data[1].split("  ", 1)[0]
		rows.append([num, name])
	line_num+=1

with open(data_dir+"crosswalk.csv", "w+") as file:
	writer = csv.writer(file)
	writer.writerows(rows)
df = pd.read_csv(data_dir+"crosswalk.csv")
df.to_stata(data_dir+"crosswalk.dta")


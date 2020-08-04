import os
import csv
import pandas as pd


data_dir = "/Users/kenta/desktop/thesis/data_processing/output/intermediary/"
final_data_dir = "/Users/kenta/desktop/thesis/data_processing/output/"
types = ["log", "regular", "log_season", "regular_season"]
delimit = ";;DELIMIT;;"
wald_key = "Prob > F"
size = 4
size2 = 3
mydict = {
	"log": {
		"dir": data_dir + "log/",
		"results": [],
		"tabnum": 7,
		"round": 3
	},
	"regular": {
		"dir": data_dir + "regular/",
		"results": [],
		"tabnum": 6,
		"round": 1
	},
	"log_season": {
		"dir": data_dir + "log_season/",
		"results": [],
		"tabnum": 8,
		"round": 3
	},
	"regular_season": {
		"dir": data_dir + "regular_season/",
		"results": [],
		"tabnum": 9,
		"round": 1
	}

}

for _type in types:

	_dir = mydict[_type]["dir"]

	tabnum = mydict[_type]["tabnum"]

	_round = mydict[_type]["round"]

	subset_files = os.listdir(_dir)
	diff_files = [file for file in subset_files if file.startswith("diff") and file.endswith(".txt")]
	wald_files = [file for file in subset_files if file.startswith("wald") and file.endswith(".txt")]

	temp_results = []
	for diff_file in diff_files:
		wald_file = diff_file.replace("diff", "wald")
		assert wald_file in wald_files
		diff_text_lines = open(_dir + diff_file, "r").readlines()
		wald_text_lines = open(_dir + wald_file, "r").readlines()

		inner_diffs = []
		for line in diff_text_lines:
			if delimit in line:
				_diffs = [round(float(x), _round) for x in line.split(delimit) if len(x)>0]
				# assert len(_diffs)==size2
				inner_diffs = _diffs
				break
			raise Exception("this shouldn't have run")

		inner_walds = []
		first = True
		top = None
		for line_num in range(0, len(wald_text_lines)):
			if wald_key in wald_text_lines[line_num]:
				F_line = wald_text_lines[line_num-1]
				Prob_line = wald_text_lines[line_num]

				upper_start = F_line.find("F(")
				upper_end = F_line.find("}\\line")
				upper = F_line[upper_start:upper_end].replace("  ", " ")
				upper_start2 = upper.find(".")-1

				if first:
					top = upper[0:upper.find(")")+1]
					first = False

				upper = upper[upper_start2:]

				lower_pre = Prob_line.find("Prob > F")
				lower_start = Prob_line.find(".")-1
				assert lower_pre < lower_start
				lower_end = Prob_line.find("}\\line")
				lower = Prob_line[lower_start:lower_end].replace("  ", " ")
				lower = round(float(lower), 2)

				inner_walds.append([upper, lower])

		# import pdb
		# pdb.set_trace()
		try: 
			assert len(inner_diffs) == len(inner_walds)
		except:
			print("this!")
			# import pdb
			# pdb.set_trace()
		assert top != None
		temp_results.append([top, inner_diffs, inner_walds])

	# import pdb
	# pdb.set_trace()

	if not _type.endswith("season"):
		proper_results = []

		first_row = [""]
		top_row = ["School level"]
		i = 1
		for temp_result in temp_results:
			top_row.append("Coefficient difference")
			top_row.append(temp_result[0])
			top_row.append("Prob > F")
			first_row.append("("+str(i)+")")
			first_row.append("("+str(i)+")")
			first_row.append("("+str(i)+")")
			i+=1
		proper_results.append(first_row)
		proper_results.append(top_row)

		curr_row = ["Elementary school"]
		for temp_result in temp_results:
			curr_row.append(temp_result[1][0])
			curr_row.append(temp_result[2][0][0])
			curr_row.append(temp_result[2][0][1])
		proper_results.append(curr_row)

		curr_row = ["Middle school"]
		for temp_result in temp_results:
			curr_row.append(temp_result[1][1])
			curr_row.append(temp_result[2][1][0])
			curr_row.append(temp_result[2][1][1])
		proper_results.append(curr_row)

		curr_row = ["High school"]
		for temp_result in temp_results:
			curr_row.append(temp_result[1][2])
			curr_row.append(temp_result[2][2][0])
			curr_row.append(temp_result[2][2][1])
		proper_results.append(curr_row)

		proper_results.append(["Note: numbers at top correspond to the original regression numbers."])
		proper_results.append(["Note: coefficient difference calculated as subtracting coefficient of girls from that of boys."])


		mydict[_type]["results"] = proper_results

		with open(final_data_dir+"tb"+str(tabnum)+"_coefficient_difference_"+_type+".csv", "w+") as csvfile:
			mywriter = csv.writer(csvfile)
			mywriter.writerows(proper_results)
	else:
		proper_results = []

		first_row = [""]
		top_row = [""]
		i = 1
		for temp_result in temp_results:
			top_row.append("Coefficient difference")
			top_row.append(temp_result[0])
			top_row.append("Prob > F")
			first_row.append("("+str(i)+")")
			first_row.append("("+str(i)+")")
			first_row.append("("+str(i)+")")
			i+=1
		proper_results.append(first_row)
		proper_results.append(top_row)

		curr_row = [""]
		for temp_result in temp_results:
			curr_row.append(temp_result[1][0])
			curr_row.append(temp_result[2][0][0])
			curr_row.append(temp_result[2][0][1])
		proper_results.append(curr_row)


		proper_results.append(["Note: numbers at top in parenthesis correspond to the original regression numbers."])
		proper_results.append(["Note: coefficient difference calculated as subtracting coefficient of rainy season from that of dry season."])


		mydict[_type]["results"] = proper_results

		with open(final_data_dir+"tb"+str(tabnum)+"_coefficient_difference_"+_type+".csv", "w+") as csvfile:
			mywriter = csv.writer(csvfile)
			mywriter.writerows(proper_results)

rows = []
with open(final_data_dir+"tb1_summary_stats.csv", "r") as csvfile:
	myreader = csv.reader(csvfile, delimiter="=")
	i = 0
	for row in myreader:
		new_row = []
		for col in row[1:]:
			new_col = col
			if col.startswith("="):
				new_col = col.replace("=", "", 1)
			if new_col.startswith(","):
				new_col = new_col[1:]
			if new_col.endswith(","):
				new_col = new_col[:-1]
			if new_col.startswith("\"") and new_col.endswith("\""):
				new_col = new_col[1:-1]
			new_row.append(new_col)

		if new_row[0].startswith("Total household"):
			new_row[1] = round(float(new_row[1]), 1)
			new_row[2] = round(float(new_row[2]), 1)

		round2 = ["Number of ", "Primary source ", "Whether", "Total number of "]
		if any([new_row[0].startswith(_str) for _str in round2]):
			new_row[1] = round(float(new_row[1]), 2)
			new_row[2] = round(float(new_row[2]), 2)

		if new_row[0].startswith("Total trip"):
			new_row[1] = round(float(new_row[1]))
			new_row[2] = round(float(new_row[2]))
		
		# if i == 3:
			# import pdb
			# pdb.set_trace()

		rows.append(new_row)

		i+=1
rows = rows[2:]
with open(final_data_dir+"tb1_summary_stats.csv", "w") as csvfile:
	mywriter = csv.writer(csvfile)
	mywriter.writerows(rows)




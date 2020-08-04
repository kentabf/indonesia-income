import requests
import pdb
import json
import csv

# pair1 = (-6.973, 110.375)
# pair2 = (-1.417, 120.658)
data_dir = "data/geocoder/"
input_fname = "latlon_list.csv"
output_fname = "latlon_province_crosswalk.csv"


key = None
resource_url = "http://www.mapquestapi.com/geocoding/v1/reverse"

# lat = pair2[0]
# lon = pair2[1]
# request_string = resource_url + "?key=" + key + "&location=" + str(lat) + "," + str(lon) + "&includeRoadMetadata=true&includeNearestIntersection=true"
# r = requests.get(request_string)
# print(r.status_code)
# res = json.loads(r.text)
# pdb.set_trace()
# a=1


# res = json.loads(r.text)
# res["results"][0]["locations"][0]["adminArea3"]

raw_csv_rows = []
with open (data_dir+input_fname) as f:
	csv_reader = csv.reader(f)
	for row in csv_reader:
		raw_csv_rows.append(row)
final_csv_rows = [raw_csv_rows[0] + ["province"]]
count = 1
for raw_row in raw_csv_rows[1:]:
	lat = raw_row[0]
	lon = raw_row[1]
	request_string = resource_url + "?key=" + key + "&location=" + str(lat) + "," + str(lon) + "&includeRoadMetadata=true&includeNearestIntersection=true"
	r = requests.get(request_string)
	res = json.loads(r.text)
	print("request number: "+str(count)+" with REST status: "+str(r.status_code)+" and API status: "+str(res["info"]["statuscode"]))
	count+=1
	province = res["results"][0]["locations"][0]["adminArea3"]

	if (not province or len(province)==0):

		exceptions_dict = {
			(4.25, 96.117): {
				'lat': 4.25,
				'lon': 96.117,
				'province': 'Aceh'
			},
			(1.767, 109.3): {
				'lat': 1.767,
				'lon': 109.3,
				'province': 'West Kalimantan'
			},
			(-2.883, 132.25): {
				'lat': -2.883,
				'lon': 132.25,
				'province': 'West Papua'
			}
		}

		province = exceptions_dict[(float(lat), float(lon))]['province']



	locations = json.dumps(res["results"][0]["locations"][0])


	raw_row.append(province)
	final_csv_rows.append(raw_row)
with open(data_dir+output_fname, "w+") as f:
	csv_writer = csv.writer(f)
	csv_writer.writerows(final_csv_rows)

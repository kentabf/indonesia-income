cd "/Users/kenta/Desktop/thesis/data_processing/"
local rainfall_dir "data/rainfall_data"
local geocoder_dir "data/geocoder"
local province_bps_crosswalk_dir = "data/province_bps_crosswalk"
set more off

// NOTE TO USERS: SET THE MODE
local mode = 2
/*

mode options:
1 - prepare for geocoding *
2 - construct drought_index **

notes:
*  - after this, you must run "02_geocoder.py" as well as "03_BPS_crosswalk_helper.py"
	 (both python 3) in the "data_processing" directory
** - you must have run the geocoder or this will not work

*/



//////////////
/// MODE 1 ///
//////////////

if `mode' == 1 {

	use "`rainfall_dir'/1955-2007.dta", clear
	
	drop if latitude == . | longitude == .
	egen latlon_tag = tag(latitude longitude)

	keep if latlon_tag == 1	
	
	keep latitude longitude 
	
	outsheet using "`geocoder_dir'/latlon_list.csv", comma

}



//////////////
/// MODE 2 ///
//////////////

if `mode' == 2 {

	// keep track of which years through these
	local years 2005 2006 2007
	local min_year 2005
	local max_year 2007
	
	// NOTE: if you touch these, make relevant changes to "SPECIAL ADJUSTMENT" below
	local rainy_start_month 11
	local rainy_end_month 3
	
	insheet using "`geocoder_dir'/latlon_province_crosswalk.csv", clear
	save "`geocoder_dir'/latlon_province_crosswalk.dta", replace
	use "`rainfall_dir'/1955-2007.dta", clear
	merge m:1 latitude longitude using "`geocoder_dir'/latlon_province_crosswalk.dta"
	drop _merge
	
	// some province name corrections so that merging can work later
	replace province = "Bangka Belitung" if province == "Bangka-Belitung Islands"
	replace province = "N. Aceh Darussalam" if province == "Aceh"
	replace province = "East Java" if province == "East Java Province"
	replace province = "Jakarta" if province == "Jakarta Special Capital Region"
	replace province = "North Sumatera" if province == "North Sumatra"
	replace province = "North Sumatera" if province == "North Sumatra Province"
	replace province = "Riau" if province == "Riau Islands"
	replace province = "Riau" if province == "Riau Islands Province"
	replace province = "South Sumatera" if province == "South Sumatra"
	replace province = "West Sumatera" if province == "West Sumatra"
	
	merge m:1 province using "`province_bps_crosswalk_dir'/crosswalk.dta"
	keep if _merge == 3
	
	
	// doesn't really make a difference since any mean/max/sum functions ignore missing vals
	drop if prcp == .
	
	
	// convert to date format
	gen my_whole_date = date(date, "YMD")
	
	// extract month and year
	gen mymonth = month(my_whole_date)
	gen myyear = year(my_whole_date) 
	
	// SPECIAL ADJUSTMENT: TODO explain
	replace myyear = myyear + 1 if mymonth == 11 | mymonth == 12
	
	// some useful variables
	// rainy season is November to March, inclusive
	gen rainy_season = 0
	replace rainy_season = 1 if mymonth >= `rainy_start_month' | mymonth <= `rainy_end_month'
	
	// pool together precipitation data across all days and years for each station-month combo
	// NOTE: this will be the baseline mean/historical average to compare total monthly data against
	bysort station mymonth: egen monthly_avg = mean(prcp)
	
	// pool together precipitation data across all days for each station-year-month combo
	bysort station mymonth myyear: egen annual_monthly_avg = mean(prcp)
	
	// compute the deviation from baseline mean/historical average
	gen annual_monthly_diff = . // bogus
	replace annual_monthly_diff = monthly_avg - annual_monthly_avg
	
	// to make things easier and faster
	drop if myyear < `min_year' | myyear > `max_year'
	
	// some useful tags
	egen station_year_month_tag = tag(station mymonth myyear)
	egen province_tag = tag(province)
	egen station_tag = tag(station)
		
	// let's make it one observation per each combination of station-month-year
	keep if station_year_month_tag == 1
	
	// this represents the average of differences of all months *for each* year for a given province
	// NOTE: province, as opposed to station, since in some cases multiple stations are in same provinces
	bysort province myyear: egen annual_diff_avg = mean(annual_monthly_diff)
	bysort province myyear rainy_season: egen annual_diff_avg_season = mean(annual_monthly_diff)
	bysort province myyear: egen annual_avg = mean(annual_monthly_avg)
	bysort province: egen historic_avg = mean(annual_monthly_avg)
		
	foreach _year in `years' {
		gen drought_`_year'_ = .
		replace drought_`_year'_ = annual_diff_avg if myyear == `_year'
		bysort province: egen drought_`_year' = max(drought_`_year'_)
		drop drought_`_year'_
		
		gen avg_`_year'_ = . 
		replace avg_`_year'_ = annual_avg if myyear == `_year'
		bysort province: egen avg_`_year' = max(avg_`_year'_)
		drop avg_`_year'_
		
		
		local seasons rainy dry
		local rainy_code 1
		local dry_code 0
		foreach season in `seasons' {
			gen drought_`_year'_`season'_ = .
			replace drought_`_year'_`season'_ = annual_diff_avg_season if myyear == `_year' & rainy_season == ``season'_code'
			bysort province: egen drought_`_year'_`season' = max(drought_`_year'_`season'_)
			drop drought_`_year'_`season'_
		}
		
	}
	
	keep if province_tag == 1
	
	save "`rainfall_dir'/drought_data", replace


}




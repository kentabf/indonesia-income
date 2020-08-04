clear
set more off
set trace off
cd "/Users/kenta/Desktop/thesis/data_processing"

// TODO: fix up the directory structure, it's pretty inconsistent, particularly with drought data
// TODO: fix up file naming conventions, very inconsistent
local ifls4_hh_raw_dir "data/IFLS4/hh07_all_dta"
local ifls4_cf_raw_dir "data/IFLS4/cf07_all_dta"
local ifls4_processed_dir "data/processed/IFLS4"
local drought_dir "data/rainfall_data"
local processed_dir "data/processed"

local sex_types boys girls
local boys_code 1
local girls_code 3

local school_types e_school m_school h_school
local min_age 5
local max_age 18
local min_age_e_school 6
local max_age_limit_e_school 12
local min_age_m_school 12
local max_age_limit_m_school 15
local min_age_h_school 15
local max_age_limit_h_school 19


////////////////////////////////////////
// get the data on kids together ///
////////////////////////////////////////

local kids_types child
local child_src_file_dir "`ifls4_hh_raw_dir'/b5_cov"
local adult_src_file_dir "`ifls4_hh_raw_dir'/b3b_cov"
local child_dst_file_dir "`ifls4_processed_dir'/child_basic.dta"
local adult_dst_file_dir "`ifls4_processed_dir'/adult_basic.dta"

local child_school_file "`ifls4_hh_raw_dir'/b5_dla1"
local adult_school_file "`ifls4_hh_raw_dir'/b3a_dl1"
local child_school_var dla07
local adult_school_var dl07a


foreach kid_type in `kids_types' {
	
	use "``kid_type'_src_file_dir'", clear
	
	keep if age >= `min_age' & age <= `max_age'
	drop if sex == .
	
	// generating num_boys and num_girls
	bysort hhid07 sex: egen num_kids_per_sex = count(hhid07)
	foreach sex_type in `sex_types' {
		gen num_`sex_type'_ = .
		replace num_`sex_type'_ = num_kids_per_sex if sex == ``sex_type'_code'
		bysort hhid07: egen num_`sex_type' = max(num_`sex_type'_)
		replace num_`sex_type' = 0 if num_`sex_type' == .
		drop num_`sex_type'_
	}
	
	// generating total_age_boys and total_age_girls
	bysort hhid07 sex: egen total_age_per_sex = sum(age)
	foreach sex_type in `sex_types' {
		gen total_age_`sex_type'_ = .
		replace total_age_`sex_type'_ = total_age_per_sex if sex == ``sex_type'_code'
		bysort hhid07: egen total_age_`sex_type' = max(total_age_`sex_type'_)
		replace total_age_`sex_type' = 0 if total_age_`sex_type'==.
		drop total_age_`sex_type'_
	}
	
	// deal with code errors/topcoding/etc and generate an age variable for age at July 15 2006
	// Note: July 15 was picked because it seems to be the most common date that separates school year (± few days)
	drop if dob_mth == 98 | dob_day == 98 | dob_yr == 9998
	replace dob_day = 30 if dob_day == 31 & (dob_mth == 11 | dob_mth == 6)
	replace dob_day = 28 if dob_day == 29 & (dob_mth == 2)
	gen bday = mdy(dob_mth, dob_day, dob_yr)
	assert bday != .
	gen age_at_july_15_2006 = mdy(7, 15, 2006) - bday
	replace age_at_july_15_2006 = age_at_july_15_2006 / 365
	drop if age - age_at_july_15_2006 > 2
	drop if age - age_at_july_15_2006 < 0

	// generate school type specific variables
	foreach school_type in `school_types' {
	
		// bin them
		gen `school_type'_age = 0
		replace `school_type'_age = 1 if age_at_july_15_2006 >= `min_age_`school_type'' ///
			& age_at_july_15_2006 < `max_age_limit_`school_type''
		bysort hhid07 sex: egen total_`school_type'_per_sex = sum(`school_type'_age)
	
		// calcaulate the num_<sex_type>_<school_type>
		foreach sex_type in `sex_types' {
			gen num_`sex_type'_`school_type'_ = 0
			replace num_`sex_type'_`school_type'_ = total_`school_type'_per_sex if sex == ``sex_type'_code'
			bysort hhid07: egen num_`sex_type'_`school_type' = max(num_`sex_type'_`school_type'_)
			replace num_`sex_type'_`school_type' = 0 if num_`sex_type'_`school_type' == .
			drop num_`sex_type'_`school_type'_
		}
	}
	
	save "``kid_type'_dst_file_dir'", replace
	
}


////////////////////////////////////////
// get parent education data together //
////////////////////////////////////////
use "`ifls4_hh_raw_dir'/b5_baa", clear

drop if baa06 == .
egen temptag = tag(hhid07)
keep if temptag == 1
drop temptag

save "`ifls4_processed_dir'/parent_educ_data.dta", replace


////////////////////////////////
// get location data together //
////////////////////////////////
use "`ifls4_hh_raw_dir'/htrack", clear

drop if sc010707 == .
egen temptag = tag(hhid07)
keep if temptag == 1
drop temptag

save "`ifls4_processed_dir'/household_location.dta", replace

////////////////////////////////
// get community data together //
////////////////////////////////

use "`ifls4_cf_raw_dir'/sar_cov", clear
local varlist_of_interest totfakes totfasek dkf4a dkf4b dkf5a dkf5b
foreach var_of_interest in `varlist_of_interest'{
	bysort commid07: egen _max = max(`var_of_interest')
	drop if `var_of_interest' == . & _max !=.
	drop _max
} 
egen _tag = tag(commid07)
keep if _tag == 1
drop _tag
gen num_e_school = dkf4a + dkf4b
gen num_m_h_school = dkf5a + dkf5b
gen num_e_m_h_school = num_e_school + num_m_h_school
save "`ifls4_processed_dir'/community_facility.dta", replace


use "`ifls4_cf_raw_dir'/bk2", clear
bysort commid07: egen _max = max(s40a)
drop if s40a == . & _max !=.
drop _max
egen _tag = tag(commid07)
keep if _tag == 1
drop _tag
save "`ifls4_processed_dir'/community_economy.dta", replace

use "`ifls4_processed_dir'/community_facility.dta", clear
merge 1:1 commid07 using "`ifls4_processed_dir'/community_economy.dta"
drop _merge

save "`ifls4_processed_dir'/community_data.dta", replace

//
// ///////////////////////////////
// // get drought data together //
// ///////////////////////////////
// use "`drought_dir'/drought_data", clear
//
// destring sc010707, replace
// drop if sc010707 == .
// tostring sc010707, replace
//
//
// save "`drought_dir'/drought_data2", replace


/////////////////////////
// merge them together //
/////////////////////////

local regression_vars num_boys num_girls total_age_boys total_age_girls ///
	num_boys_e_school num_girls_e_school num_boys_m_school num_girls_m_school ///
	num_boys_h_school num_girls_h_school //total_triptime HERE


//HERE
use "`ifls4_processed_dir'/child_basic.dta", clear
// merge 1:1 hhid07 pid07 using "`ifls4_processed_dir'/child_triptime", nogenerate
// keep hhid07 pid07 dla76j1 `regression_vars'
save "`ifls4_processed_dir'/child_temp.dta", replace


use "`ifls4_processed_dir'/adult_basic.dta", clear
//HERE merge 1:1 hhid07 pid07 using "`ifls4_processed_dir'/adult_triptime"
keep hhid07 pid07 `regression_vars' //HERE dl16j (note: put this before `regression_var'

foreach _var of varlist `regression_vars' {
	rename `_var' `_var'_2
}

save "`ifls4_processed_dir'/adult_temp.dta", replace

use "`ifls4_processed_dir'/child_temp.dta", clear


merge m:m hhid07 using "`ifls4_processed_dir'/adult_temp.dta"
keep if _merge == 3
drop _merge


foreach _var of varlist `regression_vars' {
	replace `_var' = 0 if `_var' == .
	replace `_var'_2 = 0 if `_var'_2 ==.
	replace `_var' = `_var' + `_var'_2
}

egen hhid_tag = tag(hhid07)
keep if hhid_tag == 1


merge m:1 hhid07 using "`ifls4_hh_raw_dir'/b1_ks0"
keep if _merge == 3
drop _merge
merge m:1 hhid07 using "`ifls4_processed_dir'/household_location"
keep if _merge == 3
drop _merge
merge m:1 hhid07 using "`ifls4_processed_dir'/parent_educ_data.dta"
drop if _merge == 2
drop _merge
merge m:1 hhid07 using "`ifls4_hh_raw_dir'/b2_kr"
drop if _merge == 2
drop _merge
merge m:1 commid07 using "`ifls4_processed_dir'/community_data.dta"
drop if _merge == 2
drop _merge
merge m:m hhid07 using "`ifls4_hh_raw_dir'/bk_ar0"
drop if _merge == 2
drop _merge

// merge drought index
rename sc010707 province_code
merge m:1 province_code using "`drought_dir'/drought_data", nogenerate

// clean up, organize, label, and generate any other new/relevant variables
rename ks10aa tuition
rename ks11aa supplies
rename ks12aa transportation

// interval-based drop, because there was some issue with boolean equality evaluation with floats(?)
drop if tuition < 99999999.5 & tuition > 99999998.5 //special code for missing
drop if tuition < 99999998.5 & tuition > 99999997.5 //special code for topcode

gen educ_exp_2007 = tuition + supplies + transportation
gen house_ownership = 0
replace house_ownership = 1 if kr03 == 1
gen agri_income = 0
replace agri_income = 1 if s40a == 1
gen boys = num_boys*total_age_boys
gen girls = num_girls*total_age_girls
gen rural_residence = 0
replace rural_residence = 1 if sc05_93 == 2

local rupiah_vars educ_exp_2007 tuition supplies transportation
foreach _var of varlist `rupiah_vars' {
	replace `_var' = `_var' / 1000
}

gen log_educ_exp_2007 = log(educ_exp_2007 + 1)

egen hhidtag = tag(hhid07)
keep if hhidtag == 1

label variable educ_exp_2007 "Total household education expenditure in 2007 (Rupiah, thousands)"
label variable log_educ_exp_2007 "Log total household education expenditure in 2007 (Rupiah, thousands)"
label variable drought_2006 "Drought index of 2006 (mm)"
label variable drought_2006_rainy "Drought index of 2006 for months only during rainy season (mm)"
label variable drought_2006_dry "Drought index of 2006 for months only during dry season (mm)"
label variable historic_avg "Historic mean of daily precipitation (mm)"
label variable avg_2006 "Mean daily precipitation of 2006 across all months (mm)"
label variable num_boys_e_school "Number of elementary school age boys in household"
label variable num_girls_e_school "Number of elementary school age girls in household"
label variable num_boys_m_school "Number of middle school age boys in household"
label variable num_girls_m_school "Number of middle school age girls in household"
label variable num_boys_h_school "Number of high school age boys in household"
label variable num_girls_h_school "Number of high school age girls in household"
label variable house_ownership "Whether or not current residence is owned by household (1=Yes)"
label variable totfakes "Total number of Health Facility in community"
label variable totfasek "Total number of School Facility in community"
label variable dkf4a "Number preprinted of Elementary School"
label variable dkf4b "Number supplement of Elementary School"
label variable dkf5a "Number preprinted of Secondary School"
label variable dkf5b "Number supplement of Secondary School"
label variable num_e_school "Number of elementary schools in community"
label variable num_m_h_school "Number of secondary (middle + high) schools in community"
label variable num_e_m_h_school "Number of schools (elementary, middle, and high) in community"
label variable agri_income "Primary source of income for community that household resides is agriculture (1=Yes)"
label variable num_boys "Total number of boys (of elementary, middle, and high school age) in household"
label variable num_girls "Total number of girls (of elementary, middle, and high school age) in household"
label variable hhsize "Size of household"

save "`processed_dir'/final.dta", replace


//////////////////
// analyze data //
//////////////////
clear
use "`processed_dir'/final.dta", clear

// for regression
local regression_indp_vars drought_2006 ///
	num_boys_e_school num_girls_e_school ///
	num_boys_m_school num_girls_m_school ///
	num_boys_h_school num_girls_h_school 
// for seasonal regression
local regression_indp_var2 drought_2006_rainy drought_2006_dry ///
	num_boys_e_school num_girls_e_school ///
	num_boys_m_school num_girls_m_school ///
	num_boys_h_school num_girls_h_school 
//for summary stats
local regression_indp_var3 drought_2006 drought_2006_rainy drought_2006_dry ///
	num_boys_e_school num_girls_e_school ///
	num_boys_m_school num_girls_m_school ///
	num_boys_h_school num_girls_h_school 
local regression_dep_vars educ_exp_2007 log_educ_exp_2007

local school_ctrls num_e_school num_m_h_school

local regression_ctrls agri_income house_ownership num_e_m_h_school

local other_vars hhsize
	
	
// summary statistics //

// table 1
local table1_vars educ_exp_2007 log_educ_exp_2007 `regression_indp_var3' num_boys num_girls `regression_ctrls' `other_vars'

eststo clear
eststo: estpost sum `table1_vars'
esttab using "output/tb1_summary_stats.csv", replace ///
	label ///
	cells( "mean(label(Mean) fmt(3)) sd(label(Standard Deviation) fmt(3))")
eststo clear




// regressions, wald tests, coefficient difference estimations //
local reg_fname_educ_exp_2007 "output/tb2_regression_regular.csv"
local reg_fname_log_educ_exp_2007 "output/tb3_regression_log.csv"
local educ_exp_2007_season "output/tb4_regression_regular_season.csv"
local log_educ_exp_2007_season "output/tb5_regression_log_season.csv"

local reg_title_educ_exp_2007 "Total household education expenditure in 2007 (Rupiah, thousands)"
local reg_title_log_educ_exp_2007 "Log total household education expenditure in 2007 (Rupiah, thousands)"

local fname_educ_exp_2007 "output/intermediary/regular/"
local fname_log_educ_exp_2007 "output/intermediary/log/"
local fname_educ_exp_2007_season "output/intermediary/regular_season/"
local fname_log_educ_exp_2007_season "output/intermediary/log_season/"


foreach regression_dep_var of varlist `regression_dep_vars' {
	eststo clear
	
	eststo: regress `regression_dep_var' `regression_indp_vars'
	
	local all_diff = ";;DELIMIT;;"
	local reg_num = 1
	local reg_num_str = string(`reg_num')
	
	// initiate wald asdoc
	asdoc sum `regression_dep_var', save(`fname_`regression_dep_var''wald_`reg_num_str'.txt) replace title(IGNORE)

	
	foreach school_type in `school_types' {
	
		// wald test
		asdoc test _b[num_boys_`school_type'] = _b[num_girls_`school_type'], ///
			save(`fname_`regression_dep_var''wald_`reg_num_str'.txt) append
			
		// coefficient difference
		
		local diff =  _b[num_boys_`school_type'] - _b[num_girls_`school_type']
		local diff_str = string(`diff')
		local all_diff = "`all_diff'" + "`diff_str'" + ";;DELIMIT;;"
	}
	file close _all
	file open myfile using `fname_`regression_dep_var''diff_`reg_num_str'.txt, write replace
	file write myfile "`all_diff'"
	file close myfile
	
	local ctrls_thus_far
	
	foreach regression_ctrl in `regression_ctrls' {
		local ctrls_thus_far `ctrls_thus_far' `regression_ctrl'
		eststo: regress `regression_dep_var' `regression_indp_vars' `ctrls_thus_far'
	
		local all_diff = ";;DELIMIT;;"
		local reg_num = `reg_num' + 1
		local reg_num_str = string(`reg_num')
		
		// initiate wald asdoc
		asdoc sum `regression_dep_var', save(`fname_`regression_dep_var''wald_`reg_num_str'.txt) replace title(IGNORE)
	
		foreach school_type in `school_types' {
	
			// wald test
			asdoc test _b[num_boys_`school_type'] = _b[num_girls_`school_type'], ///
				save(`fname_`regression_dep_var''wald_`reg_num_str'.txt) append
			
			// coefficient difference
			local diff =  _b[num_boys_`school_type'] - _b[num_girls_`school_type']
			local diff_str = string(`diff')
			local all_diff = "`all_diff'" + "`diff_str'" + ";;DELIMIT;;"
		}
		
		file close _all
		file open myfile using `fname_`regression_dep_var''diff_`reg_num_str'.txt, write replace
		file write myfile "`all_diff'"
		file close myfile
		
	}
	
	esttab using `reg_fname_`regression_dep_var'', replace ///
		se ///
		label ///
		star(* 0.10 ** 0.05 *** 0.01) ///
		r2 ///
		nomtitles ///
		title(`reg_title_`regression_dep_var'') ///
		no
	eststo clear
}

// For rainy and dry

foreach regression_dep_var of varlist `regression_dep_vars' {
	eststo clear
	
	local reg_num = 1
	local reg_num_str = string(`reg_num')
	
	eststo: regress `regression_dep_var' `regression_indp_var2'
	
	// wald
	asdoc test _b[drought_2006_rainy] = _b[drought_2006_dry], ///
				save(`fname_`regression_dep_var'_season'wald_`reg_num_str'.txt) replace
				
	// diff
	local diff = _b[drought_2006_rainy] - _b[drought_2006_dry]
	local diff_str = ";;DELIMIT;;" + string(`diff')
	file close _all
	file open myfile using `fname_`regression_dep_var'_season'diff_`reg_num_str'.txt, write replace
	file write myfile "`diff_str'"
	file close myfile
	

	
	local ctrls_thus_far
	
	foreach regression_ctrl of varlist `regression_ctrls' {
		
		local reg_num = `reg_num' + 1
		local reg_num_str = string(`reg_num')
	
		local ctrls_thus_far `ctrls_thus_far' `regression_ctrl'
		eststo: regress `regression_dep_var' `regression_indp_var2' `ctrls_thus_far'
		
		// wald
		asdoc test _b[drought_2006_rainy] = _b[drought_2006_dry], ///
				save(`fname_`regression_dep_var'_season'wald_`reg_num_str'.txt) replace
				
		// diff
		local diff = _b[drought_2006_rainy] - _b[drought_2006_dry]
		local diff_str = ";;DELIMIT;;" + string(`diff')
		file close _all
		file open myfile using `fname_`regression_dep_var'_season'diff_`reg_num_str'.txt, write replace
		file write myfile "`diff_str'"
		file close myfile
		
	}
	
	esttab using ``regression_dep_var'_season', replace ///
		se ///
		label ///
		star(* 0.10 ** 0.05 *** 0.01) ///
		r2 ///
		nomtitles ///
		title(`reg_title_`regression_dep_var'') ///
		no
	eststo clear
}

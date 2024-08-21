
*** This STATA processes TASK 1.
*** created on Aug 2024, 2024, by Vladimir Kolchin.

*** Data prepation

* A. Processing status data
* reading the data
import excel "C:\Users\wb313884\OneDrive - WBG\UNICEF\01_rawdata\On-track and off-track countries.xlsx", sheet("Sheet1") firstrow case(lower) clear

* creating on-track binary variable
gen ontrack = cond(statusu5mr == "Achieved" | statusu5mr == "On Track", 1, cond(statusu5mr == "Acceleration Needed",0,.)) 	

* labeling on-track variable
label define ontrack 1 "On-track" 0 "Off-track"
label values ontrack ontrack

* keeping relevant variables
keep ontrack iso3code

* saving as a temporary file
tempfile status
save `status'
**********************

* B. processing projections data
* reading the data
import excel "C:\Users\wb313884\OneDrive - WBG\UNICEF\01_rawdata\WPP2022_GEN_F01_DEMOGRAPHIC_INDICATORS_COMPACT_REV1.xlsx", sheet("Projections") cellrange(A17:BM22615) firstrow case(lower) clear

* renaming the variables of interest
rename 	iso3alphacode 				iso3code
rename 	regionsubregioncountryorar	country_name

* getting rid of missing obervationa and keeping data for year 2022
keep if iso3code != ""
keep if year == 2022

* converting variable on prijected births from string to numneric format & renaming it
replace birthsthousands = "" if birthsthousands == "..."
destring birthsthousands, replace 
rename birthsthousands birthsthousands_2022

* keeping relevant variables
keep iso3code country_name birthsthousands_2022

* saving as a temporary file
tempfile projection
save `projection'
***********************


* C. processing indicators data.
* reading the data
import excel "C:\Users\wb313884\OneDrive - WBG\UNICEF\01_rawdata\GLOBAL_DATAFLOW_2018-2022.xlsx", sheet("Unicef data") firstrow case(lower) clear

* renaming the variable of interest and getting rid of missing observations
rename geographicarea 	country_name
keep if country_name != ""

* renaming the variable of interest and converting it numeric format in case it is in string format
rename time_period 		year
cap destring year, replace


* renaming the variable of interest and converting it numeric format in case it is in string format
rename obs_value 		value
cap destring value, replace

* renaming indicators
replace indicator = "ANC4" if indicator =="Antenatal care 4+ visits - percentage of women (aged 15-49 years) attended at least four times during pregnancy by any provider"
replace indicator = "SAB" if indicator =="Skilled birth attendant - percentage of deliveries attended by skilled health personnel"

* keeping relevant variables
keep country_name year indicator value

* selecting data for the latest year 
bysort country_name indicator (year): egen latest_year = max(year) 
keep if year == latest_year

* getting rid of the non-unique observations
bysort country_name indicator (year): gen year_n = _n
keep if year_n == 1

* dropping redundant variables
drop latest_year year_n year  

* coverting the data into the wide format
reshape wide value, i(country_name) j(indicator) string // reshaping to wide format

* renaming indicator variables
rename valueANC4	ANC4 
rename valueSAB 	SAB

tempfile indicators
save `indicators'
****************************


* D. Merging data
use `indicators', clear

* merging birth projections
merge m:1 country_name using `projection'

drop if _merge == 1 	// dropping indicators for regions
drop if _merge == 2		// dropping birth data for countries with missing ANC4 & SAB
drop _merge

* merging status variable
merge m:1 iso3code using `status'

* observations that merged
keep if _merge == 3
*****************************


* E. Generating population-weighted indicators.
foreach var of varlist  ANC4  SAB {
	gen `var'_weighted = (`var' * birthsthousands_2022) 

	* Weighted coverage for all countries
	sum `var'_weighted
	local `var'_sum = r(sum)
	sum birthsthousands_2022
	local birth_sum = r(sum)
	gen `var'_weighted_cov_all = ``var'_sum' /`birth_sum'
	
	* Weighted coverage for on-track countries
	sum `var'_weighted if ontrack == 1
	local `var'_sum = r(sum)
	sum birthsthousands_2022 if ontrack == 1
	local birth_sum = r(sum)
	gen `var'_w_cov_on_track = ``var'_sum' /`birth_sum'
	
	* Weighted coverage for off-track countries
	sum `var'_weighted if ontrack == 0
	local `var'_sum = r(sum)
	sum birthsthousands_2022 if ontrack == 0
	local birth_sum = r(sum)
	gen `var'_w_cov_off_track = ``var'_sum' /`birth_sum'
}
******************************



* E. Generating figures.


* sorting data
sort iso3code
sort birth
egen country_n_code = group(iso3code)

#delim;

* indicating ISO country codes for a subset of countries which will be displayed in the figures.
generate ANC4_N = ANC4 if inlist(iso3code,"IND","NGA","PAK","CHN","ETH","COD","PHL","UGA","BRA") | inlist(iso3code,"AFG","KEN");
generate SAB_N  = SAB  if 	inlist(iso3code,"IND","NGA","PAK","CHN","ETH","COD","PHL","UGA","BRA") | 
							inlist(iso3code,"AFG","KEN","BGD","CMR","MLI","ZMB","GHA","MDG","NER") |
							inlist(iso3code,"TCD","ZWE")
							;

* Generating a ANC4 indictor fugure;
twoway 	scatter ANC4 country_n_code [w = birthsthousands_2022] if ontrack,  msymbol(circle_hollow) ||
		scatter ANC4 country_n_code [w = birthsthousands_2022] if !ontrack,  msymbol(circle_hollow) ||
		scatter ANC4_N country_n_code [w = birthsthousands_2022] if !ontrack,  msymbol(.) mlabel(iso) msize(tiny) mlabsize(2) mlabcol(red) mcolor(red) ||
		scatter ANC4_N country_n_code [w = birthsthousands_2022] if ontrack,   msymbol(.) mlabel(iso) msize(tiny) mlabsize(2) mlabcol(blue) mcolor(blue)
		//scatter ANC4 country_n_code [w = birthsthousands_2022] if !ontrack,  msymbol(.) mlabel(iso) msize(tiny) mlabsize(2) mlabcol(red) mcolor(red) ||
		//scatter ANC4 country_n_code [w = birthsthousands_2022] if ontrack,   msymbol(.) mlabel(iso) msize(tiny) mlabsize(2) mlabcol(blue) mcolor(blue)
		xtitle("")
		xlabel(none)
		ytitle(ANC4: percent of women, size(3))
		ylabel(20(20)100, labsize(3))
		legend(pos(6) ring(0) col(1)
				size(4) symxsize(10) 
				textwidth(55)
				rowgap(0.03pt)
				justification(left)
				region(style(none)) margin(zero) bmargin(4 0 0 0)
				order(1 2)
				label(1 "on track countries")
				label(2 "off track countries")
				)			  
		;
		
graph export "ANC.png", as(png) replace;


* Generating a SAB indictor fugure;
twoway 	scatter SAB country_n_code [w = birthsthousands_2022] if ontrack,  msymbol(circle_hollow) ||
		scatter SAB country_n_code [w = birthsthousands_2022] if !ontrack,  msymbol(circle_hollow) ||
		//scatter SAB country_n_code [w = birthsthousands_2022] if !ontrack,  msymbol(.) mlabel(iso) msize(tiny) mlabsize(2) mlabcol(red) mcolor(red) ||
		//scatter SAB country_n_code [w = birthsthousands_2022] if ontrack,   msymbol(.) mlabel(iso) msize(tiny) mlabsize(2) mlabcol(blue) mcolor(blue)
		scatter SAB_N country_n_code [w = birthsthousands_2022] if !ontrack,  msymbol(.) mlabel(iso) msize(tiny) mlabsize(2) mlabcol(red) mcolor(red) ||
		scatter SAB_N country_n_code [w = birthsthousands_2022] if ontrack,   msymbol(.) mlabel(iso) msize(tiny) mlabsize(2) mlabcol(blue) mcolor(blue)
		xtitle("")
		xlabel(none)
		ytitle(SUB: percent of deliveries, size(3))
		ylabel(20(20)100, labsize(3))
		legend(pos(6) ring(0) col(1)
				size(4) symxsize(10) 
				textwidth(55)
				rowgap(0.03pt)
				justification(left)
				region(style(none)) margin(zero) bmargin(4 0 0 0)
				order(1 2)
				label(1 "on track countries")
				label(2 "off track countries")
				)			  

		;		
		
graph export "SUB.png", as(png) replace;


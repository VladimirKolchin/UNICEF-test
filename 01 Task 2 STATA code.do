
*** This STATA processes TASK .
*** created on Aug 20, 2024, by Vladimir Kolchin.


* reading the MICS data
import delimited "C:\Users\wb313884\OneDrive - WBG\UNICEF\01_rawdata\Zimbabwe_children_under5_interview.csv", clear varnames(1)

* convert string data into stata date format
gen int_date = date( interview_date,"YMD")
gen birth_date = date( child_birthday,"YMD")

/* if read in different order 
gen int_date = date( interview_date,"MDY")
gen birth_date = date( child_birthday,"MDY")
*/

* obtain number of months from date of birth and interview date
gen age_in_months = round((int_date - birth_date)/(365/12),1)

gen age_in_years = floor(age_in_month/12)

* recoding missing and 2 to 0
recode ec* (2 = 0) (8 9 = .)

* generating four variable for each domain
egen litMath   = rowmean(ec6 ec7 ec8)
egen physical  = rowmean(ec9 ec10)
egen learning  = rowmean(ec11 ec12)
egen social    = rowmean(ec13 ec14 ec15)


* obtaining regression coefficients
regress litMath age_in_months
	local litMath_coeff = strofreal(_b[age_in_month],"%5.4f")
regress physical age_in_months
	local physical_coeff = strofreal(_b[age_in_month],"%5.4f")
regress learning age_in_months
	local learning_coeff = strofreal(_b[age_in_month],"%5.4f")
regress social age_in_months
	local social_coeff = strofreal(_b[age_in_month],"%5.4f")

* creating a varlist containing variable for each domain
local vars litMath physical learning social

* creating low and upper bound of the confidence interval
foreach var of local vars {
	running `var' age_in_months, gense(`var'_se) nograph
	running `var' age_in_months, gen(`var'_gen)  nograph // mean here
	generate `var'_ub = `var'_gen  + 1.96*`var'_se
	generate `var'_lb = `var'_gen  - 1.96*`var'_se
	
}


* generating figure for litMath domain
twoway rarea litMath_lb   litMath_ub   age_in_months, sort color(gs14) ||  ///
       line  litMath_gen age_in_months, msize(vsmall) mcolor(gs8) sort ///
	   xtitle("Age in months", size(2.9) margin(0 0 0 2)) ///
	   ytitle("Proportion", size(3) margin(0 2 0 0)) ///
	   legend(off) ///
	   title(Literature + Math, size(3.5)) ///
	   xlabel(36 40(5)60, labsize(2.8) nogrid) ///
	   ylabel(0(0.1)0.4, labsize(2.8) nogrid) ///
	   text(0.37 41 "Estimated slope = `litMath_coeff'***", size(2.5)) ///
	   subtitle(, size(3) position(11)) ///
			ymtick(, tp(inside) tlength(0.4)) ///
			plotregion(style(none)) ///
			graphregion(fcolor(gs16) margin(medium) lstyle(none)) ///
			name(litMath, replace)

* generating figure for Physical domain			
twoway rarea physical_lb   physical_ub   age_in_months, sort color(gs14) ||  ///
       line  physical_gen age_in_months, msize(vsmall) mcolor(gs8) sort ///
	   xtitle("Age in months", size(2.9) margin(0 0 0 2)) ///
	   ytitle("Proportion", size(3) margin(0 2 0 0)) ///
	   ylabel(0.4(0.1)1, labsize(2.8) nogrid) ///
	   xlabel(36 40(5)60, labsize(2.8) nogrid) ///
	   text(0.97 41 "Estimated slope = `physical_coeff'", size(2.5)) ///
	   legend(off) ///
	   title(Physical, size(3.5)) ///
	   subtitle(, size(3) position(11)) ///
			ymtick(, tp(inside) tlength(0.4)) ///
			plotregion(style(none)) ///
			graphregion(fcolor(gs16) margin(medium) lstyle(none)) ///
			name(physical, replace)
			
* generating figure for Learning domain
twoway rarea learning_lb  learning_ub   age_in_months, sort color(gs14) ||  ///
       line  learning_gen age_in_months, msize(vsmall) mcolor(gs8) sort ///
	   xtitle("Age in months", size(2.9) margin(0 0 0 2)) ///
	   ytitle("Proportion", size(3) margin(0 2 0 0)) ///
	   ylabel(0.4(0.1)1, labsize(2.8) nogrid) ///
	   xlabel(36 40(5)60, labsize(2.8) nogrid) ///
	   text(0.97 41 "Estimated slope = `learning_coeff'***", size(2.5)) ///
	   legend(off) ///
	   title(Learning, size(3.5)) ///
	   subtitle(, size(3) position(11)) ///
			ymtick(, tp(inside) tlength(0.4)) ///
			plotregion(style(none)) ///
			graphregion(fcolor(gs16) margin(medium) lstyle(none)) ///
			name(learning, replace)
			
* * generating figure for Social domain
twoway rarea social_lb  social_ub   age_in_months, sort color(gs14) ||  ///
       line  social_gen age_in_months, msize(vsmall) mcolor(gs8) sort ///
	   xtitle("Age in months", size(2.9) margin(0 0 0 2)) ///
	   ytitle("Proportion", size(3) margin(0 2 0 0)) ///
	   ylabel(0.4(0.1)1, labsize(2.8) nogrid) ///
	   xlabel(36 40(5)60, labsize(2.8) nogrid) ///
	   legend(off) ///
	   text(0.97 41 "Estimated slope = `social_coeff'*", size(2.5)) ///
	   title(Social, size(3.5)) ///
	   subtitle(, size(3) position(11)) ///
			ymtick(, tp(inside) tlength(0.4)) ///
			plotregion(style(none)) ///
			graphregion(fcolor(gs16) margin(medium) lstyle(none)) ///
			name(social, replace)

* combining figures into one figure
graph combine litMath physical learning social, col(2)
graph export four_graphs.png, as(png) replace
			
			
			
			
			
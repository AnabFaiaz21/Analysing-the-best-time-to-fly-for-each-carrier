/* Project- New York City Airbnb Open Data */

/* 2. Loading data */
proc import datafile= "/home/u60694061/BAN110ZBB(DJ)/Project/AB_NYC_2019(Lalith).csv"
 out= ab_project
 dbms = csv;
run;

proc print data= ab_project (obs=10);
run;

/* Dataset Charcteristics */
proc means data= ab_project;
run;

/* 3.1.1. If categorical, show the frequency distribution of each of the possible values. 
Interpret. Is the dataset balanced? Any other comment? */

proc freq data= ab_project order=freq;
table neighbourhood_group neighbourhood room_type;
run;
/* The dataset is not balanced. If we look at the frequency of the categorical variables, we observed that it is not equally distributed. */ 


/* 3.1.2.	If numerical, show the statistics (min, max, mean) and the shape of the distribution through a histogram. */
proc means data=ab_project min max mean;
var price reviews_per_month;
run;

ods select Histogram;
proc univariate data=ab_project;
   histogram;
run;

/*--------------------------------------------------------------------------------------------------------------------*/
/* 5. Numerical Variables */
/* Check errors (range of values/ less than/larger than) */
title "Range of values";
ODS select extremeobs quantiles plots;
proc univariate data= ab_project plots;
 id id;
 var price reviews_per_month;
run;

/*----------------------------------------------------------------------*/
/* Finding extreme observations for Price*/
proc print data=ab_project;
 where (price not between 30 and 8000 and price is not missing);
 id id;
 var price;
run;

/* Delete extreme observations for Price*/
data extobs_ny;
 set mylib.ab_project;
 
 if price <30 then 
  delete;
 else if price >8000 then
  delete;
run;

/* Evaluation after deleting extreme observations of Price*/
proc univariate data= extobs_ny plots;
 id id;
 var price;
run;
/*--------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------------------*/
/* Finding extreme observation for Reviews Per Month */
proc print data= extobs_ny;
 where (reviews_per_month not between 0 and 20 and reviews_per_month is not missing);
 id id;
 var reviews_per_month;
run;

/* Deleting extreme observations for reviews per month*/
data extobs_rpm;
 set  extobs_ny;
 
 if reviews_per_month < 1 then 
  delete;
 else if  reviews_per_month >20 then
  delete;
run;

/* Evaluation after deleting extreme observations */
proc univariate data= extobs_rpm plots;
 id id;
 var reviews_per_month;
run;
/*---------------------------------------------------------------------------------------------*/


/*------------------------OUTLIERS--------------------------------------------------------------------------------*/
/* Checking the distribution of some numerical variables to decide which method to use for outlier detection */

Title "Boxplot of Price";
proc sgplot data= extobs_ny;
  vbox price;
run;


/* Interquartile range to find and detect the outliers for price */
title "Outliers Based on Interquartile Range";
proc means data= extobs_rpm noprint;
var price;
output out=Tmp
 Q1=
 Q3=
 QRange= / autoname;
run;

data _null_;
 file print;
 set extobs_rpm (keep=id price);
  if _n_ = 1 then set Tmp;
   if price le price_Q1 - 1.5*price_QRange and not missing(price)
or

price ge price_Q3 + 1.5*price_QRange then
 put "Possible Outlier for Price " id "Value
of price is "Price;
run;

/* Deleting the outliers of price using the Interquartile range method */
title "Deleting Outliers Based on Interquartile Range";
data final_price;
 file print;
 set extobs_rpm;
  if _n_ = 1 then set Tmp;
   if price le price_Q1 - 1.5*price_QRange and not missing(price)
or
price ge price_Q3 + 1.5*price_QRange then
 delete;
run;

title "Distribution of Price without outliers";
proc sgplot data= final_price;
 histogram price;
 density price;
run;

title "Box plot of price without outliers";
proc sgplot data= final_price;
 vbox price;
run;
title;

proc print data= final_price(obs=10);
run;

/*---------------------------------------------------------------------------------------------------*/

/* Interquartile range to find and detect the outliers for revies per month*/

Title "Boxplot of Reviews Per Month";
proc sgplot data= extobs_rpm;
  vbox reviews_per_month;
run;

title "Outliers Based on Interquartile Range";
proc means data= final_price noprint;
var reviews_per_month;
output out=Tmp
 Q1=
 Q3=
 QRange= / autoname;
run;

data _null_;
 file print;
 set final_price;
  if _n_ = 1 then set Tmp;
   if reviews_per_month le reviews_per_month_Q1 - 1.5*reviews_per_month_QRange and not missing(reviews_per_month)
or
reviews_per_month ge reviews_per_month_Q3 + 1.5*reviews_per_month_QRange then
 put "Possible Outlier for reviews per month " id "Value
of reviews per month is "reviews_per_month;
run;

/* Deleting the outliers of reviews per month using the Interquartile range method */
title "Deleting Outliers of reviews per monthBased on Interquartile Range";
data final_abnyc;
 file print;
 set final_price ;
  if _n_ = 1 then set Tmp;
   if reviews_per_month le reviews_per_month_Q1 - 1.5*reviews_per_month_QRange and not missing(reviews_per_month)
or
reviews_per_month ge reviews_per_month_Q3 + 1.5*reviews_per_month_QRange then
 delete;
run;

title "Distribution of Price without outliers";
proc sgplot data= final_abnyc;
 histogram reviews_per_month;
 density reviews_per_month;
run;

title "Box plot of price without outliers";
proc sgplot data= final_abnyc;
 vbox reviews_per_month;
run;

/* Testing for normality again with histogram and QQ plot */
proc univariate data=final_abnyc;
 var reviews_per_month price;
 qqplot reviews_per_month price;
run;
/*------------------------------------------------------------------------------------------------------------*/


/*-----------------------------------------------*/
/* Removing missing dates */
data missingdate;
 set final_abnyc;
 if missing(last_review) then
  delete;
run;

proc print data=missingdate (obs=100);
 var last_review ;
run;
/*-----------------------------------------------*/

/*---------------------------------------------CHARACTER VARIABLES---------------------------------------------*/
/* Code to find the missing values in character variables */
title "Checking Missing Character Values"; 
proc format;
value $Count_Missing ' ' = 'Missing' other = 'Nonmissing';
run; 

title"Frequency distribution before deleting missing variables";
proc freq data=ab_project;
tables _character_ / nocum missing;
format _character_ $count_missing. ;
run;

/* Deleting the missing character variables */
data missing_where;
set ab_project;
if missing(host_name) then delete;
 else if missing(neighbourhood) then delete;
  else if missing(neighbourhood_group) then delete;
   else if missing(room_type) then delete;
    else if missing(name) then delete;
run;

title"Frequency distribution after deleting missing variables";
proc freq data= missing_where;
tables _character_ / nocum missing;
format _character_ $count_missing. ;
run;
/*---------------------------------------------------------------------------------------------------------*/

*Program to PROPCASE all the character variables in the AirBnb data set;
Proc freq data=missing_where order=freq;
tables neighbourhood_group;
run;

data Airbnb_0;
set missing_where;
 array Chars[*] _character_;
 do i = 1 to dim(Chars);
Chars[i] = propcase(Chars[i]);
end;
drop i;
run;

title "Listing the First 10 Observations in Data Set Neighbourhoods";
proc print data= AirBnb_0(obs=20) noobs;
run;

proc freq data=Airbnb_0 order=freq;
tables neighbourhood_group ;
run;
/*------------------------------------------------------------------------------------------------------------*/

/* Changing the Category of Airbnb data*/
data airbnb_2;
set Airbnb_0;
if room_type = "Private room" Then room_type ="Private";
 else if room_type = "Entire home/apt" Then room_type ="Private"; 
  else if room_type = "Shared room" then room_type = "Shared";
run;

proc print data = airbnb_2 (obs=10);
run;


*2016-07-26 HZ statins and pneunomia reanalyze;
libname cprd 'C:\';
libname statins 'C:\';
libname hes 'C:\';
libname cohort 'C:\';

*identify the file that contains the codes for statins;
data medication;
	infile 'C:\.csv' dsd missover;
	input definition$ A m dose$ prodcode$ t m productname$ drugsubstancename$ s f r b b d;
	keep definition dose prodcode productname drugsubstancename;
run;

data statins.medication;
	set medication;
	prodcod=input(prodcode,7.);
run;

*create the file that contains the statins' product code;
data statin;
	set statins.medication;
	if definition='statins' then i=1;
	else if i=0;
	if i=0 then delete;
run;

*take the first three digit of the product code from statin;
data statins.statincode;
	set statin;
	prodcod=input(prodcode,7.);
	keep definition prodcod dose drugsubstancename;
run;

proc sort data=statins.statincode;
	by prodcod;
run;

data d (rename=(prodcod=productcode)); set statins.statincode; run;
data a; merge d(in=in1) statins.covariatestatins_code(in=in2);by productcode; if in1 and not in2;run;


proc sort data=statins.therapy1;
	by id product_code;
run;

proc sql;
	create table therapy001 as
	select distinct t.*, a.*
	from cprd.therapy1 as t, statins.statincode as a
	where t.product_code=a.prodcod
	order by t.id;
quit;

proc sort data=therapy001;
	by id product_code;
run; 

data therapy1;
	set therapy001;
	by id product_code;
	if first.id;
	keep id product_code;
run;*/

*loop;
%macro therapy;
proc sql;
	%do i=1 %to 46;
	create table therapy&i as
	select distinct t.*, a.*
	from cprd.therapy&i as t, statins.statincode as a
	where t.product_code=a.prodcod
	order by id;
	%end;
quit;

%do i=1 %to 46;
proc sort data=therapy&i;
	by id date;
%end;
run; 

data statins.cprdstatins_full;
	set therapy1-therapy46;
	by id date;
run;

/*proc datasets nolist;
	delete therapy1-therapy46;
run;
quit;*/
%mend therapy;
%therapy;


proc sort data=statins.cprdstatins_full out=cprdstatins_full;
	by id date;
run;

*check for the 25,437,436;
data cprdstatins_full_split;
	set statins.cprdstatins_full;
	if definition='statins' then do;
	if index(drugsubstancename,"atorvast")>0 then atorv=1;
	else atorv=0;
	if index(drugsubstancename,"fluvasta")>0 then fluva=1;
	else fluva=0;
	if index(drugsubstancename,"pravasta")>0 then prava=1;
	else prava=0;
	if index(drugsubstancename,"rosuvast")>0 then rosuv=1;
	else rosuv=0;
	if index(drugsubstancename,"simvasta")>0 then simva=1;
	else simva=0;
	if index(drugsubstancename,"cerivast")>0 then ceriva=1;
	else ceriva=0;
	dose2=dose*1;
	end;
	if definition='TB' then tb=1; else tb=0;
	if definition='other lipid lowering agents' or definition='fibrate' then lipid=1; else lipid=0;
	if definition not in('statins','TB','other lipid lowering agents','fibrate') then other=1; else other=0;
run;

proc freq data=cprdstatins_full_split;table drugsubstancename;run;
*26182661;

data cprdstatins_full_splitcount;
	set cprdstatins_full_split;
	count+1;
	by id date;
	if first.date then count=1;
run;
*;

proc freq data=cprdstatins_full_splitcount; table count; run;

proc sql;
	create table statins.cprdstatins_full_max as
	select distinct id, date, 
				sum(dose2) as dose, max(count) as count, max(atorv) as atorv, max(fluva) as fluva, max(prava) as prava, max(rosuv) as rosuv, max(simva) as simva, max(ceriva) as ceriva,
				max(tb) as tb, max(lipid) as lipid, max(other) as other 
	from cprdstatins_full_splitcount
	group by id, date
	order by id, date;
quit;
*25540565;

proc sql;
	select count(distinct id) from statins.cprdstatins_full_max;
quit;
*622787;

data statins.cprdstatins_full_prescriptions;
	set statins.cprdstatins_full_max;
	statins=sum(atorv,fluva,prava,rosuv,simva);
run;
*25540565;

proc freq data=statins.cprdstatins_full_prescriptions; table statins; run;
*25422234+7589*2+4*3+3*4=25437436;

********;
*test for the covariate file;
*create the file with the covariate file. try to get statin.;
**************;
*open the covariate file;
proc import out=statins.covariatestatinsraw
			datafile="C:\.xlsx"
			dbms=excel replace;
	sheet="therapy";
	getnames=yes;
run;

*covert the character to the numeric of the medcod variable;
*this file is medical diagnosis, not drugs prescription;

data covariatestatins;
	set statins.covariatestatinsraw;
	productcode=prodcode*1;
	if cat='statins';
run;

*merge by product id;
%macro statins_therapy_covariate;
proc sql;
	%do i=1 %to 46;
	create table therapy&i as
	select distinct t.*, a.*
	from cprd.therapy&i as t, covariatestatins as a
	where t.product_code=a.productcode
	order by id;
	%end;
quit;

%do i=1 %to 46;
proc sort data=therapy&i;
	by id product_code;
%end;
run; 

data statins_therapy_covariate;
	set therapy1-therapy46;
	by id product_code;
	if first.id;
run;

data statins_therapy_full_covariate;
	set therapy1-therapy46;
	by id product_code;
run;

proc datasets nolist;
	delete therapy1-therapy46;
run;
quit;
%mend statins_therapy_covariate;
%statins_therapy_covariate;

data statins.cprdtherapy_covariate;
	set statins_therapy_covariate;
run;

proc sql; select count(distinct id) from statins.cprdtherapy_covariate; quit;
*622,783;

*check for the statins code;
data covariatestatins_code;
	set covariatestatins;
	keep productcode;
run;

proc compare base=statincode compare=covariatestatins_code;
	var prodcod;
	with productcode;
run;

proc sort data=statins.statincode; by prodcod; run;

*******************;
*took all the ids from the XXXX subjects;
*create a dataset with ids from therapy, and data from patient and practice;
*create eligibility with patient and practice datasets;
data patient;
	set cprd.patient1;
	practice_id=mod(id,1000);
run;

*create a dataset that combines the information in both the patient and practice;
proc sql;
	create table patient_practice as
	select distinct t.*, a.*
	from patient as t, cprd.practice1 as a 
	where t.practice_id=a.practice
	order by t.id;
quit;

*create a table with only the variables that need to be of use for calculating the start and the end of study;
data patient_practice;
	set patient_practiceraw;
	keep id yob frd crd reggap uts dod tod lcd male;
run;

*open the hes database;
*try to find the linkdate variable;

*identify the ids that included in the XXXX data;
data ids_CPRD;
	set statins.cprdstatins;
	i=1;
	keep id;
run;
*622787;

*merge the data of the XXXX ids with the data in the linkage database;
proc sql;
	create table linkageraw as
	select t.*, a.*
	from statins.cprdstatins as t, hes.linkage_eligibility as a
	where t.id=a.id
	order by t.id;
quit;
*622554;

*drop the hes=0 variables;
data linkage;
	set linkageraw;
	if hes=1;
run;

data nolinkage;
	merge linkage(in=in1) ids_cprd(in=in2);
	by id;
	if in2 and not in1;
	keep id;
run;

*count distinct ids;
proc sql;
	select count(distinct id)
	from nolinkage;
quit;
*2434;

proc means data=linkage nmiss; var linkdate;run;
***********************************;
********************************;
*merge the linkage data with the patient_practice information;
proc sql;
	create table eligibilityraw as 
	select t.*, a.*
	from linkage as t, patient_practice as a
	where t.id=a.id
	order by t.id;
quit;

*create a table with only the variables that need to be of use to calculate the start and the end of the study;
data eligibility_nolinkage;
	set eligibilityraw;
	keep id yob frd crd reggap uts dod tod lcd linkdate male;
run;
data statins.eligibility;
	set eligibilityraw;
	if reggap<30 then base=intnx('year',frd,+1,'same');
	else if reggap>=30 then base=intnx('year',crd,+1,'same');
	entry=mdy(4,1,1998);
	out=mdy(10,31,2011);
	age=mdy(1,1,yob+40);
	uts_updated=intnx('year',uts,+1,'same');
	start_study=max(age,entry,uts_updated,base);
	end_recruit=min(dod,tod,lcd,out,linkdate);
	format start_study date9. end_recruit date9.;
	if start_study<end_recruit;
run;
*data eligibility includes 557,670 ids;

proc sql;
	create table cprdstatins_eligibility as
	select a.*, b.start_study, b.end_recruit
	from statins.cprdstatins_full_prescriptions as a, statins.eligibility as b
	where a.id=b.id;
quit;
*24554220;

proc sql;
	select count(distinct id) from cprdstatins_eligibility;
quit;
*557670;

data cprdstatins_eligibility_date;
	set cprdstatins_eligibility;
	if start_study<=date<=end_recruit and statins>=1 then output;
run;
*19906607;

proc sql;
	select count(distinct id) from cprdstatins_eligibility_date;
quit;

proc freq data=cprdstatins_eligibility_date; tables atorv fluva prava rosuv simva;run;
*521018
/not521507;

proc means data=eligibilityraw2 nmiss; var male;run;*/
data eligibilityraw3;
	set eligibilityraw2;
	if hes=1 then indicator=1;
	else indicator=0;
	if indicator =0 then delete;
run;
data eligibility1; set eligibilityraw2;
if reggap<30 then 
start_study=max(mdy(1,1,yob+40), mdy(4,1,1998),intnx('year',uts,1,'same'), intnx('year',frd,1,'same'));
else if reggap>=30 then 
start_study=max(mdy(1,1,yob+40),mdy(4,1,1998),intnx('year',uts,1,'same'), intnx('year',crd,1,'same'));
format start_study date9.;
end_recruit=min(lcd,tod,dod,linkdate,mdy(10,31,2011));
format end_recruit date9.;
run;
data eligibility2;
	set eligibility1;
	if start_study<end_recruit then output;
run;
data a; merge eligibility(in=in1) eligibility2(in=in2);by id; if in1 and not in2;run;
*restrict all the criteria to the data and try to find the start and the end date;
*save it as a permanent database;
*data eligibilityraw2 includes 622787-2434=620353 ids;
proc means data=eligibility nmiss; var male start;run;

*make a difference in data;
data eligibility_age_baseline_id; 
	merge statins.eligibility(in=in1) eligibility_nolinkage(in=in2); 
	by id; 
	if in2 and not in1;
	keep id;
run;

* eligibility_age_baseline_id contains 62683=10438+52245 ids;
proc sql;
	create table exclusion_age_baseline as
	select t.*, a.*
	from eligibility_age_baseline_id as t, eligibility_nolinkage as a
	where t.id=a.id
	order by t.id;
quit;
* eligibility_age_baseline contains 62683 ids;

data a; set exclusion_age_baseline;
if male=. then output;run;

*create and count the frequencies for the age less than 40 years;
data exclusion_age;
	set exclusion_age_baseline;
	if reggap<30 then base=intnx('year',frd,+1,'same');
	else if reggap>=30 then base=intnx('year',crd,+1,'same');
	entry=mdy(4,1,1998);
	out=mdy(10,31,2011);
	age=mdy(1,1,yob+40);
	uts_updated=intnx('year',uts,+1,'same');
	start_study=max(age,entry,uts_updated,base);
	end_recruit=min(dod,tod,lcd,out);
	format start_study date9. end_recruit date9.;
	if start_study=age then i=1;
	else i=0;
run;

proc freq data=exclusion_age;
	tables i;
run;
*10,438 and 52,245;

data eligibility_test;
	set eligibility;
	if cmiss(of male) then delete;
run;
proc means data=eligibility_test nmiss; var male;run;

data eligibility_test2;
	set eligibility;
	if cmiss(of start) then delete;
run;

*count distinct ids;
proc sql;
	select count(distinct id)
	from cprd.eligibility;
quit;
*;

data test;
	set eligibility;
	if birth='0' then delete;
run;

*prescriptions for statin or other lipid lowering medications;
proc sql;
	create table statinprescription as
	select t.*, a.id
	from statins.cprdstatins as t, statins.eligibility as a
	where t.id=a.id;
quit;

*other lipid lowering medications;
data otherlipidraw;
 set medication;
 if definition='other li' then i=1;
 else if i=0;
 if i=0 then delete;
run;

proc sort data=otherlipidraw;
	by prodcode;
run;

proc sort data=statinprescription;
	by product_code;
run;

*take the first three digit of the product code from other lipid lowering medication;
data otherlipid;
	set otherlipidraw;
	prodcod=input(prodcode,7.);
	keep prodcod definition;
run;

*merge with the other lipid lowering medications;
proc sql;
	create table exclusionlipid as
	select t.*, a.id
	from otherlipid as t, statinprescription as a
	where t.prodcod=a.product_code
	order by a.id;
quit; 

proc means data=therapy nmiss; var male;run;

****************************;
***prescriptions of Statins for 557,670;
data eligibility (keep=id); set statins.eligibility;run;

proc sql; create table prescription1 as
select a.*, b.id
from statins.cprdstatins_full as a, eligibility as b
where a.id=b.id
order by a.id;
quit;
*25,157,930;

proc sort data=prescription1 out=prescription2; by id date product_code;run;

proc freq data=statins.medication;table definition;run;

*testing;
proc sql;
	create table ther1 as
	select unique e.id, e.start, e.end, t.date, t.product_code, t.qty, t.dd, t.days, d.definition, d.dose, d.drugsubstancename
	from statins.eligibility as e, cprd.therapy1 as t, statins.statincode as d
	where e.id=t.id and t.product_code=d.prodcod
	order by e.id, t.date;
quit;

*create the big therapy with all the necessary information;
%let ther=46;
%macro prescriptions;
proc sql;
	%do i=1 %to &ther;
	create table therapy_statins&i as
	select unique e.id, e.start_study, e.end_recruit, t.date, t.product_code, t.qty, t.dd, t.days, d.definition, d.dose, d.drugsubstancename
	from statins.eligibility as e, cprd.therapy&i as t, statins.statincode as d
	where e.id=t.id and t.product_code=d.prodcod
	order by e.id, t.date;
	%end;
quit;

data statins.ther_onlystatins;
	set therapy_statins1-therapy_statins&ther;
	by id date;
run;
%mend prescriptions; 
%prescriptions

*check for the frequencies for different drug names;
proc freq data=statins.ther_onlystatins;table drugsubstancename;run;
*24712907;

data ther_onlystatins;
	set statins.ther_onlystatins;
	count+1;
	by id date;
	if first.date then count=1;
run;
*24712907;

proc freq data=ther_onlystatins; table count; run;

data ther_onlystatins2;
	set ther_onlystatins;
	if index(drugsubstancename,"atorvast")>0 then atorv=1;
	else atorv=0;
	if index(drugsubstancename,"fluvasta")>0 then fluva=1;
	else fluva=0;
	if index(drugsubstancename,"pravasta")>0 then prava=1;
	else prava=0;
	if index(drugsubstancename,"rosuvast")>0 then rosuv=1;
	else rosuv=0;
	if index(drugsubstancename,"simvasta")>0 then simva=1;
	else simva=0;
	if index(drugsubstancename,"cerivast")>0 then ceriva=1;
	else ceriva=0;
	dose2=dose*1;
run;
*24712907;

data check;
	set statins.ther_statins;
	where count>1 and definition='statins';
run; 

*with distinct id, start, end and date;
proc sql;
	create table statins.therapy_onlystatins as
	select distinct id, start_study, end_recruit, date, 
				sum(dose2) as dose, max(count) as count, max(atorv) as atorv, max(fluva) as fluva, max(prava) as prava, max(rosuv) as rosuv, max(simva) as simva, max(ceriva) as ceriva
	from ther_onlystatins2
	group by id, start_study, end_recruit, date
	order by id, date;
quit;
*24,554,220;

data statins.therapy_onlystatins4;
	set statins.therapy_onlystatins;
	statins=sum(atorv,fluva,prava,rosuv,simva,ceriva);
	if start<=date<end;
run;
*19,962,211;

proc freq data=statins.therapy_onlystatins4; table statins; run;
*19956435+5892*2+2*3+4*1=19,968,229;

*second check, the same code as the above*******************************just to check with all the medication if we have the same result***************;
*create the big therapy with all the necessary information;

proc import out=statins.covariate_excludedrugs
			datafile="C:\.xlsx"
			dbms=excel replace;
	sheet="exclude drugs";
	getnames=yes;
run;

%let ther=46;
%macro prescriptions;
proc sql;
	%do i=1 %to &ther;
	create table ther&i as
	select unique e.id, e.start_study, e.end_recruit, t.date, t.product_code, t.qty, t.dd, t.days, d.definition, d.dose, d.drugsubstancename
	from statins.eligibility as e, cprd.therapy&i as t, statins.covariate_excludedrugs as d
	where e.id=t.id and t.product_code=d.prodcode
	order by e.id, t.date;
	%end;
quit;

data statins.ther_excludedrugs;
	set ther1-ther&ther;
	by id date;
run;
%mend prescriptions; 
%prescriptions
*26,439,515;

*check if covariate(masha), sheet exclude drug and exclusion drug-statincode has the same statin
*compare the two file: statincode and covariate_excludedrugs;
data covariate_excludedrugs_statins;
	set statins.covariate_excludedrugs;
	if definition='statins';
	prodcod=prodcode*1;
	i='masha';
	keep definition i prodcod;
run;
proc sort data=statins.statincode; by prodcod; run;
proc sort data=covariate_excludedrugs_statins; by prodcod; run;
data test; merge statins.statincode covariate_excludedrugs_statins;by prodcod;run;

*for the 19,968,229;
*check for the frequencies for different drug names;
proc freq data=statins.ther_statins;table drugsubstancename;run;

proc sort data=statins.ther_statins dupout=check nodupkey;by id date product_code qty dd days; run;

data statins.ther_excludedrugs_count;
	set statins.ther_excludedrugs;
	count+1;
	by id date;
	if first.date then count=1;
run;
*26,439,515;

proc freq data=statins.ther_excludedrugs_count; table definition drugsubstancename; run;

data statins.ther_statins2;
	set statins.ther_excludedrugs_count;
	if definition='statins' then do;
	if index(drugsubstancename,"atorvast")>0 then atorv=1;
	else atorv=0;
	if index(drugsubstancename,"fluvasta")>0 then fluva=1;
	else fluva=0;
	if index(drugsubstancename,"pravasta")>0 then prava=1;
	else prava=0;
	if index(drugsubstancename,"rosuvast")>0 then rosuv=1;
	else rosuv=0;
	if index(drugsubstancename,"simvasta")>0 then simva=1;
	else simva=0;
	if index(drugsubstancename,"cerivast")>0 then ceriva=1;
	else ceriva=0;
	dose2=dose*1;
	end;
	if definition='TB' then tb=1; else tb=0;
	if definition='fibrate' then fibrate=1;else fibrate=0;
	if definition='other lipid lowering agents' then lipid=1; else lipid=0;
	if definition not in('statins','TB','other lipid lowering agents','fibrate') then other=1; else other=0;
run;

data check;
	set statins.ther_statins;
	where count>1 and definition='statins';
run; 

data statins.ther_statins00;
	set statins.ther_statins2;
	start_study=start;
	end_recruit=end;
run;


*with distinct id, start, end and date;
proc sql;
	create table statins.therapy_statins as
	select distinct id, start_study, end_recruit, date, 
				sum(dose2) as dose, max(count) as count, max(atorv) as atorv, max(fluva) as fluva, max(prava) as prava, max(rosuv) as rosuv, max(simva) as simva, max(ceriva) as ceriva,
				max(tb) as tb, max(lipid) as lipid, max(fibrate) as fibrate, max(other) as other
	from statins.ther_statins2
	group by id, start_study, end_recruit, date
	order by id, date;
quit;
*25,507,804;

data statins.therapy_allprescriptions;
	set statins.therapy_statins;
	statins=sum(atorv,fluva,prava,rosuv,simva);
	if start_study<=date<end_recruit;
run;
*20,587,342;

proc freq data=statins.therapy_allprescriptions; tables statins; run;
*19886099+5626*2+2*3+1*4=19,897,361;

data therapy_oneyearbefore;
	set statins.therapy_statins;
	before_start=intnx('year',start,-1,'same');
	statins=sum(atorv,fluva,prava,rosuv,simva);
	if before_start<=date<end;
run;
*21748306;

proc sql;
	select count(distinct id) from statins.therapy_allprescriptions;
quit;
*522753;

data statins;
	set statins.therapy_allprescriptions;
	if statins>=1;
run;
*19891728;

proc sql;
	select count(distinct id) from statins;
quit;
*520788;

proc freq data=statins.therapy_allprescriptions; table statins;run;

data statins.therapy_allprescriptions00;
	set statins.therapy_allprescriptions;
	start_study=start;
	end_recruit=end;
	format start_study date9.;
	format end_recruit date9.;
run;

*************************************
*multiple statins on the same day;
data statins.therapy_multiplestatins;
	set statins.therapy_allprescriptions;
	if statins=0 or statins=1 then indicator=0;
	else indicator=1;
	if indicator=1;
run;
*630641
;
proc freq data=statins.therapy_multiplestatins;table statins; run;
*prescription of multiple statins on the same day 5626*2+2*3+1*4=11,262;

*prescriptions for statin or other lipid lowering medications in the year before cohort entry;
*all statins in all therapy;
*use the lagdate;
*subtract one data base from another;
data therapy_excludemultiplestatins;
	merge statins.therapy_multiplestatins(in=in1) statins.therapy_allprescriptions(in=in2);
	by id date;
	if in2 and not in1;
run;
*19,956,701;

data statins.cprdstatins_lagdate;
	set statins.therapy_excludemultiplestatins;
	lagdate=lag(date);
	lagtb=lag(tb);
	lagfibrate=lag(fibrate);
	laglipid=lag(lipid);
	lagceriva=lag(cerivast);
	lag=lag()
	by id;
	if first.id then lagdate=.;
	format lagdate date9.;
run;
*19,956,701;

data statins.ther_statins2;
	set statins.ther_excludedrugs_count;
	if definition='statins' then do;
	if index(drugsubstancename,"atorvast")>0 then atorv=1;
	else atorv=0;
	if index(drugsubstancename,"fluvasta")>0 then fluva=1;
	else fluva=0;
	if index(drugsubstancename,"pravasta")>0 then prava=1;
	else prava=0;
	if index(drugsubstancename,"rosuvast")>0 then rosuv=1;
	else rosuv=0;
	if index(drugsubstancename,"simvasta")>0 then simva=1;
	else simva=0;
	if index(drugsubstancename,"cerivast")>0 then ceriva=1;
	else ceriva=0;
	dose2=dose*1;
	end;
	if definition='TB' then tb=1; else tb=0;
	if definition='fibrate' then fibrate=1;else fibrate=0;
	if definition='other lipid lowering agents' then lipid=1; else lipid=0;
	if definition not in('statins','TB','other lipid lowering agents','fibrate') then other=1; else other=0;
run;


proc sort data=statins.cprdstatins_lagdate; by id date; run;

*t0 is the cohort entry date;
data statins.cprdstatins_oneyearb;
	set statins.cprdstatins_lagdate;
	if date-lagdate>365 then t0=date;
	if date-lagdate<=365 then i=0;
	else i=1;
	format t0 date9.;
run;

proc freq data=statins.cprdstatins_oneyearb; table statins; run;


data statins.cprd_slf;
	set statins.cprdstatins_oneyearb;
	if statins=1 or lipid=1 or fibrate=1 or ceriva=1;
run;
*19956701;



proc freq data=statins.cprd_slf; tables t0 i;run;

data statins.cprd_exclusion_statinslipid;
	set statins.cprd_cohortentry_statinslipid;
	if i=0;
run;
*prescriptions for statin or other lipid lowering medications in the year before cohort entry
20,261,551;


*find the cohort entry date for each participant;
proc sort data=eligibility_therapy2;
	by id date;
run;

*find the lagdate and multiple statins on the same day;
data statins.cprdstatins_lagdate_mstatins;
	set statins.ther_statins2;
	lagdate=lag(date);
	by id;
	if first.id then lagdate=.;
	format lagdate date9.;
run;

data statins.cprd_cohortentry_multiplesameday;
	set statins.cprdstatins_lagdate_mstatins;
	if date=lagdate then multiple=1;
	else multiple=0;
run;

proc freq data=statins.cprd_cohortentry_multiplesameday; table multiple; run;
*931,711;

*patients with a prescription for anti-tuberculosis medication in the year before cohort entry;
data statins.therapy_cohortentry_TB; 
	set statins.ther_statins2;
	if tb=1;
run;
*14,460;

*patients hospitalized with a community-acquired pneumonia in the year before cohort entry;
*HCAP;
data hcap;
	set hes.diagnosis_epi;
run;

proc import out=statins.covariatehes
			datafile="C:.xlsx"
			dbms=EXCEL replace;
	sheet="hes";
	getnames=yes;
run;

*get the hcap codes;
data statins.covariateheshcap;
	set statins.covariatehes;
	if code='hcap';
run;

*merge with the data with the cohort entry date;
proc sql;
	create table hcap_cohortentry;
	select distinct a.*,b.*
	from hes.diagnosis_epi as a, statins.covariateheshcap as b
	where a.icd10=b.code;
	order by a.icd10;
quit;

*hospitalized on the day of cohort entry or for >1 days within 30 days before cohort entry;
*delete the outpatient visits;
data patient_cohortentry;
	set hes.hospital;
	stay=disch-admit;
	format stay;
	if stay=0 and source=19 and destination=19 then delete;
	if stay=. then delete;
run;

proc sql;
	create table hospitalized_cohortentry as
	select distinct base.t0, patient.* 
	from statins.cprd_cohortentry as base, patient_cohortentry as patient
	where base.id=patient.id
	order by base.id;
quit;

data hospitalized_30cohortentry;
	set hospitalized_cohortentry;
	if t0-30<admit<=t0;
run;
*63617;

*history of cancer;
cprd.clinical
cprd.referral
cprd.test

*define HCAP?;
data diagnosis_cancer;
	set hes.diagnosis_epi;
	if "C00"<=icd10<"C98";
run;

%macro clinical;
	%do i=1 %to 26;
	data clini&i;
		set cprd.clinical&i;
		if medical_code=42600;
	run;
	%end;
quit;

data clinical;
	set clini1-clini26;
	by id;
run;

proc datasets nolist;
	delete therapy1-therapy46;
run;
quit;
%mend clinical;
%clinical;

%let n=2;
%macro referral;
	%do i=1 %to &n.;
	data refer&i;
		set cprd.referral&i;
		if medical_code=42600;
	run;
	%end;
quit;

data referral;
	set refer1-refer&n.;
	by id;
run;

proc datasets nolist;
	delete therapy1-therapy46;
run;
quit;
%mend referral;
%referral;

%let n=31;
%macro test;
	%do i=1 %to &n.;
	data test&i;
		set cprd.test&i;
		if medical_code=42600;
	run;
	%end;
quit;

data test;
	set test1-test&n.;
	by id;
run;

proc datasets nolist;
	delete therapy1-therapy46;
run;
quit;
%mend test;
%test;
*save as permanent datasets;
data statins.clinical;
	set clinical;
run;

data statins.referral;
	set referral;
run;

data statins.test;
	set test;
run;

************************************************************based on the cohort, select cases;

proc import out=statins.covariatehes
	datafile="C:\.xlsx"
	dbms=excel replace;
	sheet="hes";
	getnames=yes;
run;

proc freq data=cohort.selected; table exposure;run;

proc sql;
	create table selected as
	select distinct e.id, e.male, e.yob, e.start_study, e.end_recruit, s.t0, e.linkdate, e.tod, e.dod, e.toreason, e.lcd, s.exposure
	from cohort.selected as s, statins.eligibility as e
	where e.id=s.id
	order by id;
quit;
*346,992;

*2016-07-25;

proc freq data=hcap1;table icd10;run;

*censoring due to death;

proc freq data=hcap2;table stay;run;


*19 the usual place of residence, including no fixed abode;
data hcap2;
	set hcap2;
	if stay=0 and source=19 and destination=19 then delete;
	if stay=. then delete;
run;
*29144;

data first_hcap;
	set cases;
	by id t0 hcap_admit disch spell;
	if first.t0;
run;
*12942;


proc sort data=first_hcap(rename=(dischmeth=olddischmeth)) out=first_hcap2;
	by id t0 hcap_admit disch spell;
run;

*death at admission of hospitalization;
proc sql;
	create table fatal1 as
	select distinct h.*, t.dischmeth
	from first_hcap2 as h, hes.hospital as t
	where h.id=t.id and h.spell=t.spell and t.dischmeth=4
	order by id, spell, hcap_admit;
quit;
*3751
/3797;

proc sql;
	create table hosp1 as
	select distinct h.t0, t.*
	from first_hcap as h, hes.hospital as t
	where h.id=t.id and h.disch<=t.admit<=h.t0+730
	order by id, t0, admit, disch;
quit;
*5255
/3448;

*delete outpatient visit;
data hosp2;
	set hosp1;
	stay=admit-disch;
	if stay=0 and source=19 and destination=19 then delete;
	if disch=. then delete;
	if stay=. then delete;
run;
*3170
/1993;

data hosp3_death;
	set hosp2;
	if dischmeth=4;
run;
*403
/229;

data hosp4;
	set first_hcap(keep=id t0 hcap_admit disch rename=(hcap_admit=admit)) hosp1(keep=id t0 admit disch);
run;
*18197;

proc sort nodupkey; by id t0 admit disch;run;
*18150;

data hosp5;
	set hosp4;
	by id t0 admit;
	lagdisch=lag(disch);
	format lagdisch date9.;
	if first.t0 then lagdisch=.;
	diff=admit-lagdisch;
run;
*18150;

data hosp6;
	set hosp5;
	by id t0 admit;
	retain count;
	if first.t0 then count=1;
	if diff>0 then count=count+1;
run;
*18150;

data hosp7;
	set hosp5;
	by id t0 admit;
	retain count;
	if first.t0 then count=1;
	if diff>0 and lagdisch ne . then count=count+1;
run;

proc compare base=hosp6 compare=hosp7;run;

proc sql;
	create table hosp8 as
	select distinct id, t0, admit, min(admit) as minadmit format date9., disch, max(disch) as maxdisch format date9.
	from hosp6
	group by id, t0, count
	order by id, t0, admit, disch;
quit;

data hosp9;
	set hosp8;
	by id t0 admit disch;
	if first.t0;
run;
*12942;

*death at admission of hospitalization + death after hospitalization(at the hospital the entire time);
proc sql;
	create table fatal2 as
	select distinct h.*
	from hosp8 as h , hosp3_death as d
	where h.id=d.id and h.t0=d.t0 and h.disch=d.disch
	order by id, t0, admit, disch;
quit;

data fatal;
	set fatal1(keep=id spell disch t0 dischmeth hcap_admit rename=(hcap_admit=admit)) fatal2(keep=id t0 minadmit maxdisch rename=(minadmit=admit maxdisch=disch));
	by id t0;
run;
*4156;

proc sort nodupkey; by id t0 admit disch;run;
*4114;

*death at the discharge;
data fatal_all;
	set fatal(rename=(disch=death_disch));

data cases;
	set first_hcap fatal_all;
	by id t0;
run;

proc sql;
	create table cases_grouped as
	select distinct id, t0, max(hcap_admit) as hcap_admit, max(fatal) as, max() as
	from cases;
	group by id, t0
	order by id, t0, hcap_admit;
quit;

****************************;
*hospitalization after t0, stay>1;
proc sql;
	create table hosp as
	select distinct s.id, s.t0, h.admit, h.disch, (h.disch-h.admit) as stay, h.source, h.destination
	from selected as s, hes.hospital as h
	where s.id=h.id and s.t0<=h.admit<=s.end_recruit
	order by id, admit;
quit;
	
data hosp_stay;
	set hosp;
	if stay=0 and source=19 and destination=19 then delete;
	if stay=. then delete;
run;
*393 002;

proc freq data=hosp_stay; table stay destination; run;

data hosp_stay2;
	set hosp_stay;
	by id admit;
	lagdisch=lag(disch);
	format lagdisch date9.;
	if first.id then lagdisch=.;
	diff=admit-lagdisch;
run;

data c;
set hosp_stay2;
if diff<0 and diff ne .;
run;

data hosp_stay3;
	set hosp_stay2;
	by id admit;
	retain count;
	if first.id then count=1;
	if diff>0 then count=count+1;
run;

proc sql;
	create table hosp_stay4;
	select distinct id, t0, min(admit) as admit, max(disch) as disch, (calculated disch - calculated admit) as stay, count
	from hosp_stay3 
	group by id, t0, count
	order by id, admit;
quit;

data hosp_stay5;
	set hosp_stay4;
	by id admit;
	if stay<1 then delete;

data c;
set hosp_stay4;
if stay=1;
run;*/


*get the information;
*date of death, reason for transfer, date of transfer;

*15517;
*end of follow up;
*select cases;
*prescence of pneumonia recorded on the day of admission or the day after admission are cases;
*or any hospitalization with a length of stay >1 day;
*except for patients who die on their admission date;
data hcap_exit1;
	set hcap2;
	if days_after_admission>1 then delete;
	if stay=0 and dischmeth=4 then cases=2;
	if stay>0 then cases=1;
run;
*20335;

proc freq data=hcap_exit1; table cases;run;
*20080 cases;

data hcap_exit2;
	set hcap_exit1;
	if cases=1;
run;


proc import out=statins.covariate


*covariates;
proc sql;
	create table covariate;
	select
	from clinical as c, 
quit;




	



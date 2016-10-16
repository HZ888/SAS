*2016-08-01 HZ statins and pneunomia reanalyze;
*;
libname cprd 'C:\';
libname statins 'C:\';
libname hes 'C:\';
libname cohort 'C:\';

*hdps;
data case;
	merge cohort.selected statins.cases_ids;
	by id;
run;

data cohort_new;set case;run;
data covariate;set cohort.covariate;run;

proc sql;
create table cohort as
select cov.*,coh.outcome
from cohort_new as coh, covariate as cov
where coh.id=cov.id
order by coh.id;
quit;

data cohort;
	set cohort;
	if outcome=. then outcome=0;
run;

%let clin=26;
%let ref=2;
%let imm=1;
%let lab=9;
%let ther=46;


%macro hdps_info;
%do i=1 %to &clin;
proc sql;
  	create table clin&i as
	select unique coh.id, c.medical_code,c.date
	from cohort as coh, cprd.clinical&i as c
	where coh.id=c.id and intnx('year',coh.t0,-1,'same')<=c.date<=coh.t0
	order by coh.id, c.medical_code, c.date;
  %end;
  %do i=1 %to &ref;
  proc sql;
  create table ref&i as 
  	select unique coh.id,  r.medical_code, r.date
	from cohort as coh, cprd.referral&i as r
	where coh.id=r.id and intnx('year',coh.t0,-1,'same')<=r.date<=coh.t0
	order by coh.id, r.medical_code, r.date;
  %end;
  %do i=1 %to &imm;
  proc sql;
  create table imm&i as 
  	select unique coh.id, im.medical_code, im.date
	from cohort as coh, cprd.immunisation&i as im
	where coh.id=im.id and intnx('year',coh.t0,-1,'same')<=im.date<=coh.t0
	order by coh.id, im.medical_code, im.date;
  %end;
  %do i=1 %to &lab;
  proc sql;
  create table lab&i as 
  	select unique coh.id,  l.medical_code, l.date
	from cohort as coh, cprd.test&i as l
	where coh.id=l.id and intnx('year',coh.t0,-1,'same')<=l.date<=coh.t0
	order by coh.id, l.medical_code, l.date;
  %end;
  %do i=1 %to &ther;
  proc sql;
  	create table ther&i as
	select unique coh.id, t.product_code, t.bnfcode, t.date
	from cohort as coh, cprd.therapy&i as t
	where coh.id=t.id and intnx('year',coh.t0,-1,'same')<=t.date<=coh.t0 
	order by coh.id, t.product_code;
  %end;
  quit;
  proc sql;
  	create table hosp as
	select unique coh.id, d.icd10,d.start,d.end, d.spell, d.episode, substr(d.icd10,1,5) as code
	from cohort as coh, hes.diagnosis_epi as d
	where coh.id=d.id and intnx('year',coh.t0,-1,'same')<=d.start<=coh.t0
	order by coh.id, d.start, d.end;
	quit;
  proc sql;
  	create table procedures as
	select unique coh.id,p.start, p.end, p.spell, p.episode, p.opcs,substr(p.opcs,1,3) as code
	from cohort as coh, hes.procedures as p
	where coh.id=p.id and intnx('year',coh.t0,-1,'same')<=p.start<=coh.t0
	order by coh.id,p.start, p.end;
	quit;
 data statins.gp;
  set clin1-clin&clin ref1-ref&ref imm1-imm&imm lab1-lab&lab;
  by id medical_code date;
 run;
 data statins.therapy;
  set ther1-ther&ther;
  by id product_code;
 run;
%mend hdps_info;
%hdps_info;

proc datasets nolist;
delete clin1-clin&clin ref1-ref&ref imm1-imm&imm ther1-ther&ther lab1-lab&lab;
run;

data gp; set statins.gp  (where=(medical_code ne 0 and medical_code ne 14));
data therapy; set statins.therapy (where=(bnfcode ne 0));
run;

proc import datafile='C:\' out=medical DBMS=TAB;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

data medical; set medical(rename=(medcode=medical_code));run;

* drop duplicates of the same medical code per patient per day;
proc sql;
create table gp1 as
select unique g.id, g.medical_code, g.date
from gp as g
order by g.id, g.medical_code, g.date;
quit;

* combine all medical records with readcodes;
proc sql;
create table gp_dimension as
select unique g.*, m.readcode, substr(m.readcode,1,3) as code
from gp1 as g, medical as m
where g.medical_code=m.medical_code 
order by g.id, g.medical_code, g.date, m.readcode;
quit;

* Exclude exposure codes;
proc sql;
create table therapy_exclude as
select t.*
from therapy as t, statins.medication as e
where t.product_code=e.prodcod
order by t.id, t.product_code, t.date;
quit;

proc sort data=therapy;by id product_code date;run;

data one;
merge therapy(in=a) therapy_exclude(in=b);
by id product_code date;
if a and not b;
run;

* select unique bnfcodes per date;
proc sql;
create table therapy_dimension as
select unique t.id, t.date, t.bnfcode as code
from one as t
order by t.id, t.date, t.bnfcode;
quit;

/* Unique dx per episode */

proc sort data=hosp nodupkey;by id code episode;run;

/*data out.therapy_dimension; set therapy_dimension;run;*/
/*data out.gp_dimension;set gp_dimension;run;*/
/*data out.proc_dimension; set procedures;run;*/
/*data out.hosp_dimension;set hosp;run;*/

/*data therapy_dimension; set out.therapy_dimension;run;*/
/*data gp_dimension;set out.gp_dimension;run;*/
/*data procedures; set out.proc_dimension;run;*/
/*data hosp;set out.hosp_dimension;run;*/

options mprint;
%include "C:\";
%RunHighDimPropScore(var_patient_id=id,
                           input_cohort=cohort,
                           vars_force_categorical= obesity,
                           output_detailed      = output_detailed,
                           result_diagnostic    = result_diagnostic,
                           output_scored_cohort = output_scored_cohort,
                           result_estimates     = result_estimates,
                           var_outcome  = outcome,
                           var_exposure = exposure,
                           percent_trim = 5,
                           trim_mode    = Both,
                           top_n  = 200,
                           k      = 500,
                           vars_demographic=,
                           vars_predefined=obesity alcohol  
                           cov_dm cov_hypertension cov_mi cov_revasc cov_stroke gp_visits prescriptions,  
                           vars_ignore=,
                           input_dim1=therapy_dimension code,
                           input_dim2=gp_dimension code,
                           input_dim3=hosp code,
                           input_dim4=procedures code);
                                     
proc sort data=p4; by estimate;run;
proc sort data=p4;by variable;run;

* to check which HDPS selected variables are more influential use id column from t_ps_calc to identify the original code;
proc contents data=t_ps_calc;run;

data temp;set t_ps_calc;
coding_id=put(id,4.);
run;

data temp1;set p4;
coding_id=substr(variable,3,6);run;

proc sort;by coding_id;
run;

proc sort data=temp;by coding_id;run;

/* create a table to verify which codes are selected from which dimension */
proc sql;
create table estimates as
select t.type,t.item,t.source_table,t.frequency_type,t1.estimate,t1.variable,t1.coding_id
from temp as t, temp1 as t1
where t.coding_id=t1.coding_id
order by estimate;
quit;

proc freq;table source_table;run;
/* 32% from gp dimension, 37% from therapy dimension, 27% from hosp dimension, 4% from procedures dimension */

/* output the dataset in case you want to look at the codes in detail */
data out.hdps_empirical_selected; set estimates;run;


* plot the distributions by exposure status;
proc univariate data=output_scored_cohort_4 noprint;histogram ps; class exposed;run;

* look at the distribution summary statistics by exposure;
proc univariate data=output_scored_cohort_4;var ps;class exposed;run;

* trimming the data where the distributions overlap;
proc sql;
create table ps_range as
select *, max(ps) as max_ps, min(ps) as min_ps from output_scored_cohort_4
group by exposed; 
quit;

proc sql;
create table ps_trim as
select *, max(min_ps) as trim_min_ps, min(max_ps) as trim_max_ps from ps_range
having ps >= calculated trim_min_ps and ps <= calculated trim_max_ps
order by ID;
quit;

data ps_overlap_trim;
set ps_trim;
drop max_ps min_ps trim_min_ps trim_max_ps;
run;

proc freq data=ps_overlap_trim; table outcome exposed;run;
proc freq data=cohort; table outcome;run;

proc rank data=ps_overlap_trim out=trim_ranked groups=10;
var ps;
ranks PSranks;
run;

/*data out.hdps_trimmed;set trim_ranked;run;*/

/* output HDPS created file with the estimated PS for plotting */
/*data out.output_scored_cohort_4;set output_scored_cohort_4;run;*/


proc export data=trim_ranked (keep=id exposed ps) outfile='C:\';run;


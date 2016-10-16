*2016-07-27 HZ statins and pneunomia reanalyze;
*;
libname cprd 'C:\';
libname statins 'C:\';
libname hes 'C:\';
libname cohort 'C:';

*match on:

*duration of follow up;
*cohort entry date (+-90 days);
*age;
*sex;

data cases2;
	set statins.cases;
	age=year(t0)-yob;
	dof=exit-t0;
run;

proc univariate data=cases2; var dof; histogram; run;
*case is ready;
***************;

data hdps;
	infile 'C:.csv' missover dsd;
	input id exposed ps;
run;

proc sql;
	create table control as
	select distinct s.*,d.male, d.dod, d.tod
	from cohort.selected as s, cprd.patient1 as d
	where s.id=d.id
	order by id;
quit;
*346992
;

proc sort data=statins.therapy_allprescriptions00; by id date;run;

proc sql;
	create table control2 as
	select distinct h.*, a.ceriva, a.statins, a.date
	from control as h, statins.therapy_allprescriptions00 as a
	where h.id=a.id
	order by id, date;
quit;
*12796971
;

data control2_1;
	set control2;
	if t0<=date<=end_recruit;
run;
*12672021
;

data control3;
	set control2_1;
	out=mdy(10,31,2011);
	end_follow_up=t0+730 ;
	if ceriva=1 then ceriva_date=date;
	if statins>1 then statins_date=date;
	format statins_date ceriva_date end_follow_up out date9.;
	exit=min(dod, tod, ceriva_date, statins_date, out, end_follow_up);
	format exit date9.;
	dof=exit-t0;
run;

proc freq data=control3;table statins;run;

proc sql; select count(distinct id) from control3;quit;
*346992;

proc sort data=control3; by id date;run;

data control4;
	set control3;
	by id date;
	if first.id;
run;
proc univariate data=control4; var dof;histogram;run;

data statins.cohort;
	merge cohort.covariate(in=a) hdps(in=b) statins.cases(in=c) control4(in=d);
	by id;
	if a and b;
run;
*346983
;

proc freq data=statins.cohort; table cases;run;

proc means data=statins.cohort; var dof;run;

data cohort;
	set statins.cohort;
	keep id cases age dof male t0 exit;
	if cases=. then cases=0;
run;
*346983
;

data cases4;
	set statins.cases3;
	retain cnt 0;
	cnt=cnt+1;
run;

data cases5;
	set cases4;
	keep id age dof male t0 cnt;
run;

*use macro as loops for matching;
%let n=2470;


data case1;
	set cases5;
	if cnt=1;
run;

proc sql;
	create table match1 as
	select a.*
	from case1 as a, cohort as o
	where a.dof<=o.dof and a.age=o.age and a.male=o.male and -90<= (a.t0-o.t0)<=90;
quit;


*match1-match2470;
*risk set sampling;
proc sql;
	create table case_control as
	select o.id, o.t0, o.age, o.male, o.dof
	from cases2 as a, cohort as o
	where a.dof<=o.dof and a.age=o.age and a.male=o.male and -90<= (a.t0-o.t0)<=90;
quit;
*352589
;

proc sql;
create table r1 as
  select e.id as caseid, c.id, c.age, c.male,c.t0, c.exit,c.dof, c.t0+(e.exit-e.t0) as indexdate format=date9.,
             count(c.id)-1 as nb
  from cohort as e, cohort as c
  where e.cases = 1 and (e.exit-e.t0) <= (c.exit-c.t0) and not ( e.id ne c.id and c.cases=1 and (e.exit-e.t0) = (c.exit-c.t0) )
            and  c.age=e.age and c.male=e.male  and e.t0-90 <= c.t0 <= e.t0+90 
  group by e.id
  order by e.id, c.id;
quit;
*348514
;
data test; set r1; where nb = 0; run;


proc sql;
create table r2 as
  select e.id as caseid, c.id, c.age, c.male,c.t0, c.exit,c.dof, c.t0+(e.exit-e.t0) as indexdate format=date9.,
             count(c.id)-1 as nb
  from r1 as e, cohort as c
  where e.nb=0 and (e.exit-e.t0) <= (c.exit-c.t0) and not ( e.id ne c.id and c.cases=1 and (e.exit-e.t0) = (c.exit-c.t0) )
            and  e.age-1 <= c.age <= e.age+1 and c.male=e.male  and e.t0-90 <= c.t0 <= e.t0+90 
  group by e.id
  order by e.id, c.id;
quit;
data test1; set r2; where nb = 0; run;


proc sql;
create table r3 as
  select e.id as caseid, c.id, c.age, c.male,c.t0, c.exit,c.dof, c.t0+(e.exit-e.t0) as indexdate format=date9.,
             count(c.id)-1 as nb
  from r1 as e, cohort as c
  where e.nb=0 and (e.exit-e.t0) <= (c.exit-c.t0) and not ( e.id ne c.id and c.cases=1 and (e.exit-e.t0) = (c.exit-c.t0) )
            and  e.age-2 <= c.age <= e.age+2 and c.male=e.male  and e.t0-90 <= c.t0 <= e.t0+90 
  group by e.id
  order by e.id, c.id;
quit;
data test2; set r3; where nb = 0; run;

proc univariate data=cohort;var age;histogram;run;

proc sort data=cohort; by age;run;

data riskset;
  set r1(where=(nb >0)) r2(where=(nb >0)) r3;
  by caseid id;
  if caseid = id then do;
            outcome = 1;
            _nsize_=1;
  end;
  else do;
            outcome = 0;
            _nsize_=min(10,nb);
  end;
  *drop nb;
run;

proc sort data=riskset; by caseid outcome id; run;

proc sort data=riskset out=sampsize(keep=caseid outcome _nsize_) nodupkey; by caseid outcome _nsize_; run;

*for each case, up to 10 controls will be randomly seleted using risk set sampling;
proc surveyselect data=riskset out=cc (drop=nb: selectionprob samplingweight)
	method=srs  sampsize=sampsize selectall
	seed=10 ;
	strata caseid outcome;
quit;

proc univariate data=riskset;var _nsize_;run;

data out.riskset;set riskset;run;
data out.cc;set cc;run;

data statins.cc;set cc;
weight=1/_nsize_;
run;

proc sort data=cc;by outcome;run;

proc freq data=cc;table male; by outcome;
weight weight;
run;

proc sql;
	select count( distinct caseid)
	from statins.cc;
quit;

data a; set statins.cases;if id=2257 then output;run;

*2016-07-26 HZ statins and pneunomia reanalyze;
libname cprd 'C:';
libname statins 'C:';
libname hes 'C:\';
libname cohort 'C:';
*Define HCAP;
*patients will be followed until an HCAP;
proc sql;
	create table hcap1 as
	select distinct d.id, d.start format=date9., d.end, c.end_recruit, c.t0, d.spell, d.episode, d.icd10, d.icd10x, d.dorder, c.start_study, c.exposure
	from statins.covariatehes as h, hes.diagnosis_epi as d, cohort.selected as c
	where h.cat='hcap' and (substr(d.icd10,1,3) in ('J13', 'J14', 'J15') or h.code=d.icd10) and d.id=c.id and t0<=start<=end_recruit
	order by id, start, t0;
quit;
*29681;

*censoring due to death;
*date of death in cprd;
proc sql;
	create table hcap_exit1 as
	select h.*, c.dod, c.toreason, c.tod, (c.dod) as censordeath
	from hcap1 as h, cprd.patient1 as c
	where h.id=c.id
	order by id, t0;
quit;

*date of death in hes;
proc sql;
	create table hcap2 as
	select distinct d.id, (e.disch-e.admit) as stay, (d.start-e.admit) as days_after_admission, d.spell, d.episode, e.destination, e.dischmeth, 
d.start, d.end, e.admit, e.disch, e.source, d.start_study, d.end_recruit, d.t0, d.icd10, d.exposure, e.order, e.days, e.type, 
e.admitmeth, e.mainspec, e.treatspec, e.idconsul, e.intend_manag, e.classpat, e.firstreg
	from hcap_exit1 as d, hes.episodes as e
	where d.id=e.id and d.episode=e.episode and d.start=e.start and d.spell=e.spell
	order by id, start, t0;
quit;
*29663;

proc sort nodupkey; by id t0 admit disch; run;

data hcap3;
	set hcap2;
	by id t0 admit;
	lagdisch=lag(disch);
	format lagdisch date9.;
	if first.t0 then lagdisch=.;
	diff=admit-lagdisch;
run;

data hcap4;
	set hcap3;
	by id t0 admit;
	retain count;
	if first.t0 then count=1;
	if diff>0 then count=count+1;
run;
*18093;

proc sql;
	create table hcap5 as
	select distinct h.*, min(h.admit) as minadmit format date9., max(h.disch) as maxdisch format date9. 
	from hcap4 as h
	group by id, t0, count
	order by id, t0, admit, disch;
quit;

data hcap6;
	set hcap5;
	by id t0 minadmit maxdisch;
	if first.t0;
run;
*14679;

data hcap7;
	set hcap6;
	if dischmeth=4 then death_date=disch;
	format death_date date9.;
run;
*14679
;

*prescription of cerivastatin, receipt of multiple statin prescriptions on the same day;
proc sql;
	create table hcap8 as
	select h.*, a.ceriva, a.statins, a.date
	from hcap7 as h, statins.therapy_allprescriptions00 as a
	where h.id=a.id and h.start_study=a.start_study and h.end_recruit=a.end_recruit
	order by id, t0;
quit;

proc sql;
	select count(distinct id) 
	from hcap8;
quit;
*2834;

*the end of the study period(Oct 31st 2011);
*the end of follow up(730 days);
data hcap9;
	set hcap8;
	out=mdy(10,31,2011);
	end_follow_up=t0+730 ;
	if ceriva=1 then ceriva_date=date;
	if statins>=1 then multiple_statins_date=date;
	format multiple_statins_date ceriva_date end_follow_up date9.;
run;

proc freq data=hcap9; table statins;run;


*any hospitalization with a stay>1 day;
data hcap10;
	set hcap9;
	if stay>0;
run;

proc sql;
	select count(distinct id) 
	from hcap10;
quit;
*2683;


*define cases;
proc sql;
	create table cases as
	select distinct c.*, d.male, d.yob, d.dod, d.tod 
	from hcap10 as c, cprd.patient1 as d
	where c.id=d.id
	order by id, t0;
quit;	
*prescence of pneumonia recorded on the day of admission;
data cases1;
	set cases;
	if admit=start or days_after_admission>1;
	exit=min(start, dod, tod, ceriva_date, multiple_statins_date, out, end_follow_up);
	format exit date9.;
run;

proc sort data=cases1; by id exit;run;

data cases2_1;
	set cases1;
	if exit=start;
run;

data cases2_2;
	set cases2_1;
	by id exit;
	if first.id;
run;
*2195;

*length of stay greater than one day;
data cases2;
	set cases2_2;
	if stay>0;
run;

*except who die on their admission date;
data statins.cases;
	set cases2;
	if stay=0 and dischmeth=4 then cases=0;
	else cases=1;
run;

proc freq data=cases; table cases; run;

proc sql;
	select count(distinct id) 
	from statins.cases;
quit;
*2470;

proc sort data=statins.cases; by id date;run;

*take the first line of the first prescription of statin;

data new (keep=id start); set statins.cases_ids;run;
data new1; merge cohort(in=in1) new(in=in2);by id; if in1;run;


data diagnoraw;
set table_diagnosis;
run;

data diagi48;
set diagnoraw;
i48=substrn(dx,1,3);
run;

data diagi484273;
set diagi48;
fourtwoseventhree=substrn(dx,1,4);
run;

data diagiraw;
set diagi484273;
if fourtwoseventhree="4273" then i=1;
else if i48="I48" then i=2;
else i=0;
run;
*delete irrelavent lines, keep only the ones with the diagnosis;
data diagi;
set diagiraw;
if i=0 then delete;
run;
*count how many participants that have the 4237 and i48 diagnosis;
ods rtf file='sample_size.rtf';
proc sql;
select count(distinct id)
from diagi;
quit;
ods rtf close;
*drop irrelatvent variables;
data diagnosis;
set diagi;
drop i48 fourtwoseventhree i;
run; 

proc sort data=diagnosis;
by id date;
run;
data diagafib;
set diagnosis;
by id date;
if first.id;
run;

*demographics;
data demograw;
set table_demographics;
run;
proc sort data=demograw;
by id;
run;
*combine demographic data and diagnostic data by ID;
data demogdiagafibraw;
merge demograw diagafib;
by id;
run;
*delete missing values in the data set with afib diagnostic date;
data demogdiagafib;
set demogdiagafibraw;
if cmiss(of _all_) then delete;
run;
*calculate the look back time: start date-AFIB date;
data lookbacktimeraw;
set demogdiagafib;
difference=datdif(start,date,'act/act');
difference2=date-start;
put difference=;
run;

*to calculate the lookbacktime variable, which include one year period before the afib date or less than one year 
if the start time is within the range,;
data lookbacktime_test;
set lookbacktimeraw;
pretime=date-max(start,intnx('year',date,-1,'same'));
run;

*look back time:mean and standard deviation;
ods rtf file='time.rtf';
proc means data=lookbacktime_test mean std;
var pretime;
output out=pretime;
run;
ods rtf close;

data year_of_afib;
set demogdiagafib;
year_of_afib = year(date);
dif=year_of_afib - year_of_birth;
keep id date dif;
run;

ods rtf file='mean.rtf';
proc means data=year_of_afib mean std;
var dif;
output out=mean;
run;
ods rtf close;

*age at afib: mean 75.4482759 and std 10.9035685.;
ods rtf file='women.rtf';
proc freq data=demogdiagafib;
table male;
run;
ods rtf close;

*to calculate the Year of AFIB diagnosis;
data year_afib_diagnosis;
set diagafib;
year=year(date);
keep id year;
run;

data year_afib_diagnosis2;
set year_afib_diagnosis;
if year<2000 then i=1;
else i=0;
run;
ods rtf file='0-2000.rtf';

proc freq data=year_afib_diagnosis2;
table i;
run;
ods rtf close;

data year_afib_diagnosis3;
set year_afib_diagnosis;
if year>=2000 and year<=2005 then i=2;
else i=0;
run;

ods rtf file='2000-2005.rtf';
proc freq data=year_afib_diagnosis3;
table i;
run;
ods rtf close;

data year_afib_diagnosis4;
set year_afib_diagnosis;
if year>=2006 and year<=2009 then i=3;
else i=0;
run;

ods rtf file='2006-2009.rtf';
proc freq data=year_afib_diagnosis4;
table i;
run;

ods rtf close;
data year_afib_diagnosis5;
set year_afib_diagnosis;
if year>2009 then i=4;
else i=0;
run;

ods rtf file='2009-.rtf';
proc freq data=year_afib_diagnosis5;
table i;
run;
ods rtf close;

*comorbidities;
*try to merge two datasets by id;
*diagafib2 contains 348 subjects without duplicates of ids;
data diagafib2(rename=(date=dateafib dx=dxafib));
set diagafib;
run; 
proc sort data=diagafib2;
by id;
run;
proc sort data=diagnoraw;
by id date;
run;
data diagnosis_at_baseline;
merge diagnoraw diagafib2;
by id;
run;

*drop the lines with missing values;
*baseline2 contains;
data diagnosis_at_baseline2;
set diagnosis_at_baseline;
if cmiss(of _all_) then delete;
run;
*calculate the difference between two dates;
data diagnosis_at_baseline3;
format baseline date9.;
set diagnosis_at_baseline2;
baseline=intnx('year',dateafib,-1,'same');
run;
*delete the lines that is not within the one year period before afib happens;
data diagnosis_at_baseline4;
set diagnosis_at_baseline3;
if baseline<date and date<=dateafib then i=1;
else i=0;
if i=0 then delete;
run;

*to calculate Comorbidities at baseline
1-STROKE
2-DIABETES
3-HYPERTENSION
4-MYOCARDIAL INFARCTION
5-Congestive Heart Failure
6-Vascular Disease;
data comorbidities;
set diagnosis_at_baseline4;
if '401'<=dx<'406' or 'I10'<=dx<'I16' then com=3;
else if '410'<=dx<'413' or 'I21'<=dx<'I23' or 'I24'<=dx<'I25' or 'I252'<=dx<'I253' then com=4;
else if '428'<=dx<'429' or dx in ('40201','40211','40291','40401','40403','40411','40413','40491','40493') or 'I50'<=dx<'I51' or substr(dx,1,4) in ('I110','I130','I132') then com=5;
else if '440'<=dx<'442' or '444'<=dx<'446' or 'I70'<=dx<'I72' or 'I74'<=dx<'I75' then com=6; 
else if '250'<=dx<'251' or 'E10'<=dx<'E15' then com=2;
else if '433'<=dx<'435' or dx in: ('431','436') or dx in: ('I63','I65','I663','I61','I64') then com=1;
else com=0;
run;
*delete irrelavent lines, keep only the lines with dx in our list of comorbidities;
data comorbidities2;
set comorbidities;
if com=0 then delete;
run;
*stroke 
with only the stroke related participants;
data stroke;
set comorbidities2;
if com=1 then i=1;
else i=0;
if i=0 then delete;
run;
data stroke2;
set stroke;
by id date;
if first.id;
run;
*diabetes;
data diabetes;
set comorbidities2;
if com=2 then i=1;
else i=0;
if i=0 then delete;
run;
data diabetes2;
set diabetes;
by id date;
if first.id;
run;
*hypertension;
data hypertension;
set comorbidities2;
if com=3 then i=1;
else i=0;
if i=0 then delete;
run;
data hypertension2;
set hypertension;
by id date;
if first.id;
run;
*Myocardial infarction;
data mi;
set comorbidities2;
if com=4 then i=1;
else i=0;
if i=0 then delete;
run;
data mi2;
set mi;
by id date;
if first.id;
run;
*heart failure;
data hf;
set comorbidities2;
if com=5 then i=1;
else i=0;
if i=0 then delete;
run;
data hf2;
set hf;
by id date;
if first.id;
run;
*Vascular Disease;
data vd;
set comorbidities2;
if com=6 then i=1;
else i=0;
if i=0 then delete;
run;
data vd2;
set vd;
by id date;
if first.id;
run;

*count the number of stroke participants;
data com;
merge diagafib(in=a keep=id) stroke2(in=b keep=id) diabetes2(in=c keep=id) hypertension2(in=d keep=id) mi2(in=e keep=id) hf2(in=f keep=id) vd2(in=g keep=id);
by id;
if a;
if b then stroke=1; else stroke=0;
if c then diabetes=1; else diabetes=0;
if d then hypertension=1; else hypertension=0;
if e then mi=1; else mi=0;
if f then hf=1; else hf=0;
if g then vd=1; else vd=0;
run;
ods rtf file='comorbidities.rtf';
proc freq data=com;
table stroke diabetes hypertension mi hf vd;
run;
ods rtf close;
*drug
open the file with drug names;
data drug;
infile 'C:\.csv' missover dsd;
input cat $ din denocom form ahf dosage;
run;
data test;
	set drug;
	if cat='statins';
run;


*open the drug raw dataset;
data drugraw;
set table_drug;
run;
*sort before merging;
proc sort data=drug;
by din;
run;
proc sort data=drugraw;
by din;
run;
*merge by din; 
/*data drug2;
merge drug drugraw;
by din;
run;*/

proc sql;
create table drug2 as
select distinct t.*, din.cat
from table_drug as t, drug as din
where t.din=din.din
order by t.id, t.date;
quit;

data test;
	set drug2;
	if cat='statins';
run;
proc freq data=drug; table cat; run; 
proc sort data=drug2;
by id;
run;

*have the dataset that contains the date of afib and the baseline data;
Proc sort data=diagafib;
by id date;
run;
*keep only the afib date, baseline date and the id.;
data baseline(rename=(date=dateafib));
set diagafib;
by id date;
if first.id;
run;

data drug100;
	merge drug2(in=a) baseline(in=b keep=id dateafib);
	by id;
	if a and b;
run;

data drug101;
	set drug100;
		if intnx('year',dateafib,-1,'same')<date<=dateafib;
run;

*check that we have participants within the 348 range, excluding the ones without afib diagnosis;
proc sql;
select count (distinct id) from drug101;
quit;

proc sort data=drug101; by id cat; run; 

*since din does not matter, so here i delete the din column and the sample indicator column;
data drug7;
set drug101;
by id cat;
if first.cat;
keep id cat;
run;

*label for each drug;
data drug10;
set drug7;
if cat='ac' then ac=1;
else if cat='ap' then ap=1;
else if cat='asa' then asa=1;
else if cat='ace' then ace=1;
else if cat='arb' then arb=1;
else if cat='bb' then bb=1;
else if cat='ccb' then  ccb=1;
else if cat='diu' then diu=1;
else if cat='insulin' then ins=1;
else if cat='oad' then oad=1;
else if cat='statins' then stat=1;
run;

proc sql;
	create table alldrug as
	select distinct cohort.id, cohort.dateafib, max(d.ac) as OAC, max(d.ap) as AP, max(d.asa) as ASP,
	max(d.ace) as AC, max(d.arb) as AR, max(d.bb) as BETABLO , max(d.ccb) as CHANNEL, max(d.diu) as DIURETICS,
	max(d.ins) as INSULIN, max(d.oad) as OADD, max(d.stat) as statins
	from drug10 as d , baseline as cohort
	where d.id=cohort.id
	group by cohort.id
	order by cohort.id;
quit;

data final;
	merge alldrug baseline(in=a);
	 by id;
	 if a;
	 array cov {11} OAC AP ASP AC AR BETABLO CHANNEL DIURETICS INSULIN OADD statins;
	 do i=1 to 11;
		if cov{i}=. then cov{i}=0;
	end;
run;
ods rtf file='medication_at_baseline.rtf';
proc freq data=final;
table OAC AP ASP AC AR BETABLO CHANNEL DIURETICS INSULIN OADD statins;
run;

ods rtf close;
proc sort data=drug10;
by i;
run;
*follow-up time;
data followuptimeraw;
set demogdiagafib;
difference=datdif(date,end,'act/act');
put difference=;
run;
data followuptime;
set followuptimeraw;
if difference<365 then time=difference;
else time=365;
run;
*follow up time:mean and standard deviation;
ods rtf file='followuptime.rtf';
proc means data=followuptime mean std;
var time;
output out=followuptime;
run;
ods rtf close;
*comorbidities;
data followuptime2;
format followup date9.;
set diagnosis_at_baseline2;
followup=intnx('year',dateafib,+1,'same');
run;
*delete the lines that is not within the one year period after afib happens;
data followuptime3;
set followuptime2;
if followup>date and date>=dateafib then i=1;
else i=0;
if i=0 then delete;
run;
*to calculate Comorbidities at followup
1-STROKE
2-DIABETES
3-HYPERTENSION
4-MYOCARDIAL INFARCTION
5-Congestive Heart Failure
6-Vascular Disease;
data comorbidities_followup;
set followuptime3;
if '401'<=dx<'406' or 'I10'<=dx<'I16' then com=3;
else if '410'<=dx<'413' or 'I21'<=dx<'I23' or 'I24'<=dx<'I25' or 'I252'<=dx<'I253' then com=4;
else if '428'<=dx<'429' or dx in ('40201','40211','40291','40401','40403','40411','40413','40491','40493') or 'I50'<=dx<'I51' or substr(dx,1,4) in ('I110','I130','I132') then com=5;
else if '440'<=dx<'442' or '444'<=dx<'446' or 'I70'<=dx<'I72' or 'I74'<=dx<'I75' then com=6; 
else if '250'<=dx<'251' or 'E10'<=dx<'E15' then com=2;
else if '433'<=dx<'435' or dx in: ('431','436') or dx in: ('I63','I65','I663','I61','I64') then com=1;
else com=0;
run;
*delete irrelavent lines, keep only the lines with dx in our list of comorbidities;
data comorbidities_followup2;
set comorbidities_followup;
if com=0 then delete;
run;
*stroke 
with only the stroke related participants;
data stroke_followup;
set comorbidities_followup2;
if com=1 then i=1;
else i=0;
if i=0 then delete;
run;
data stroke_followup2;
set stroke_followup;
by id date;
if first.id;
run;
*diabetes;
data diabetes_followup;
set comorbidities_followup2;
if com=2 then i=1;
else i=0;
if i=0 then delete;
run;
data diabetes_followup2;
set diabetes_followup;
by id date;
if first.id;
run;
*hypertension;
data hypertension_followup;
set comorbidities_followup2;
if com=3 then i=1;
else i=0;
if i=0 then delete;
run;
data hypertension_followup2;
set hypertension_followup;
by id date;
if first.id;
run;
*Myocardial infarction;
data mi_followup;
set comorbidities_followup2;
if com=4 then i=1;
else i=0;
if i=0 then delete;
run;
data mi_followup2;
set mi_followup;
by id date;
if first.id;
run;
*heart failure;
data hf_followup;
set comorbidities_followup2;
if com=5 then i=1;
else i=0;
if i=0 then delete;
run;
data hf_followup2;
set hf_followup;
by id date;
if first.id;
run;
*Vascular Disease;
data vd_followup;
set comorbidities_followup2;
if com=6 then i=1;
else i=0;
if i=0 then delete;
run;
data vd_followup2;
set vd_followup;
by id date;
if first.id;
run;
*count the number of stroke, diabetes, hypertension, mi, hf, and vd participants;
data com_followup;
merge diagafib(in=a keep=id) stroke_followup2(in=b keep=id) diabetes_followup2(in=c keep=id) hypertension_followup2(in=d keep=id) mi_followup2(in=e keep=id) hf_followup2(in=f keep=id) vd_followup2(in=g keep=id);
by id;
if a;
if b then stroke=1; else stroke=0;
if c then diabetes=1; else diabetes=0;
if d then hypertension=1; else hypertension=0;
if e then mi=1; else mi=0;
if f then hf=1; else hf=0;
if g then vd=1; else vd=0;
run;
ods rtf file='comorbidities_followup.rtf';
proc freq data=com_followup;
table stroke diabetes hypertension mi hf vd;
run;
ods rtf close;
*medication
*have the dataset that contains the date of afib and one year followup;
Proc sort data=followuptime3;
by id followup;
run;
*keep only the afib date, baseline date and the id.;
data followup;
set followuptime3;
by id followup;
if first.id;
run;
*make the dataset of 348 ids and the one-year time window of followup;
data followup2;
set followup;
keep followup id dateafib;
run;
*sort before merging;
proc sort data=followup2;
by id;
run;
proc sort data=drug3;
by id;
run;
*merge the dataset (with dates of taking the medication) with the dataset (with the followup dates);
*merge with the datasets that contains only the 348 ids;
data drug_followup4;
merge followup2(in=a) drug3(in=b);
by id;
if a then sample=1;else sample=0;
if b;
run;
*keep only the 348 participants;
data drug_followup5;
set drug_followup4;
if sample=0 then delete;
run;
*check that we have participants within the 348 range, excluding the ones without afib diagnosis;
proc sql;
select count (distinct id) from drug_followup5;
quit;
*restrict the date is within the one year follow up time;
data drug_followup6;
set drug_followup5;
if followup>date and date>=dateafib then i=1;
else i=0;
if i=0 then delete;
run;
*since din does not matter, so here i delete the din column and the sample indicator column;
data drug_followup7;
set drug_followup6;
keep id cat;
run;
*delete missing values;
data drug_followup8;
set drug_followup7;
if cmiss(of _all_) then delete;
run;
*sort before keep the first line;
proc sort data=drug_followup8;
by id cat;
run;
*keep only one copy of the id for each drug category;
data drug_followup9;
set drug_followup8;
by id cat;
if first.cat;
run;
*label for each drug;
data drug_followup10;
set drug_followup9;
if cat='ac' then i=1;
else if cat='ap' then i=2;
else if cat='asa' then i=3;
else if cat='ace' then i=4;
else if cat='arb' then i=5;
else if cat='bb' then i=6;
else if cat='ccb' then i=7;
else if cat='diu' then i=8;
else if cat='insulin' then i=9;
else if cat='oad' then i=10;
else if cat='statins' then i=11;
else i=0;
run;
ods rtf file='medication_at_baseline.rtf';
proc freq data=drug_followup10;
table i;
run;
ods rtf close;
proc sort data=drug_followup10;
by i;
run;


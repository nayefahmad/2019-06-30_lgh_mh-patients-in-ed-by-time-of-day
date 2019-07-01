

----------------------------------------------------------
-- LGH AVERAGE CENSUS BY TIME OF DAY FOR SURGERY UNITS
----------------------------------------------------------



--TODO: --------------------------------------
-- remove criteria for surge only (joining on ADR) 

-----------------------------------------------


-----------------------------------------------
-- USER INPUTS: 
-----------------------------------------------

declare @startdate date
	,@enddate date
	,@numdays int
set @startdate='04/1/2016'
set @enddate='03/31/2017'
set @numdays = datediff(dd, @startdate, @enddate) + 1

--select @numdays as numdays; 

declare @site varchar(100)
set @site='lions gate hospital'

-----------------------------------------------


-----------------------------------------------
-- CLEANUP: 
-----------------------------------------------
IF OBJECT_ID('tempdb..#HospitalistList') IS NOT NULL DROP TABLE #HospitalistList; 
IF OBJECT_ID('tempdb.dbo.#time') IS NOT NULL DROP TABLE #time; 
IF OBJECT_ID('tempdb.dbo.#date') IS NOT NULL DROP TABLE #date; 
IF OBJECT_ID('tempdb.dbo.#census') IS NOT NULL DROP TABLE #census; 
-----------------------------------------------



use ADTCMart 

set nocount on  --Stops the message that shows the count of the number of rows affected by a Transact-SQL statement

/***** create table of hospitalists *****/
create table #HospitalistList (Hospitalist varchar(100))

if @site='richmond hospital'
begin
insert into #HospitalistList (Hospitalist) values
	('CHEE, PETER')
	,('LEE, TRACY Y.Y.')
	,('LI, DAVID')
	,('WONG, EDWARD')
	,('KIRK, JESSICA')
	,('GARRY, BENEDICT MICHAEL')
	,('BALOG, STEPHANIE ANNE')
	,('FUNG, SARAH SZE LOK')
	,('STOKES, ERIKA')
	,('SY, CANDICE')
	,('HSU, JUSTIN WEI-CHEN')
	,('BAJWA, SUKHDEEP KAUR')
	,('PHO, MARK')
	,('BOOTH, ESTHER')
	,('ARTHUR, JILLIAN CATHERINE')
	,('Barnhill, J.')
	,('CHANG, JACK')
	,('FUNG, CLEMENT')
	,('GERZALEZ-ROMULUS, MARIE-CHRISTINA')
	,('HERNANDEZ, JENNY LEE')
	,('LI, HIU-WAH')
	,('MINHAS, SHIKHA')
	,('NGAI, TYLER WING-TAI')
	,('SINGLETON-POLSTER, AMY JEAN')
end

if @site='lions gate hospital'
begin
insert into #HospitalistList (Hospitalist) values
	('BRACHE, MORGAN L.')
	,('BYMAN, ANDREA')
	,('CHAN, PHILIP')
	,('CHORNY, IRINA')
	,('EARLY, ANITA M.')
	,('Evans, David Joseph')
	,('KAZEMI, ALI-REZA')
	,('KROLL, EDWARD S.')
	,('LEA, JOHN')
	,('LONG, BRUCE FREDERICK')
	,('MCFEE, INGRID')
	,('MORGENSTERN, KATHERINE')
	,('O''NEIL, MICHAEL BRENDAN')
	,('PURVIS, ALISON')
	,('SAUNIER, JEREMY GABRIEL')
	,('STOKES, ERIKA')
	,('ZIBIN, KERRY')
end

if @site='vancouver general hospital'
begin
insert into #HospitalistList (Hospitalist) values
	('BAKONYI, J.')
	,('BARBOUR, K.A.')
	,('BENEDEK, C.')
	,('CHONG, TIFFANY LINDA')
	,('CHOW, F.H.')
	,('EVANS, DAVID JOSEPH')
	,('GILL, AMANPREET KAUR')
	,('JACOBSON, DEBORAH L.')
	,('KRYKORKA, PETER')
	,('LAPIN, MICHAEL')
	,('LEE, DONALD D.')
	,('LI, DAVID')
	,('MAKHOULIAN, NATALIE')
	,('MALHI, LUVDEEP KAUR')
	,('MARCH, RODERICK')
	,('MAYSON, T.A.')
	,('PALETTA, MICHAEL')
	,('RIDLEY, JOHN')
	,('SHIVDASANI, K.')
	,('SKURIDINA, NATALIYA')
	,('TOGNOTTI, D.')
	,('TUKKER, RODERICK PETER')
	,('VASTARDIS, A.')
	,('WILTON, D.')
	,('YOUSEFI, VANDAD')
end; 

--select * from #HospitalistList;

----------------------------------------------
/***** create time table *****/
----------------------------------------------
SELECT distinct ROW_NUMBER() OVER(ORDER BY [Time24Hr]) AS Row,cast([Time24Hr] as time) as [Time24Hr]
  into #time
  FROM [ADTCMart].[dim].[Time]
  where right([Time24Hr],2)='01'
 
--select * from #time; 

----------------------------------------------
/***** create date table *****/
----------------------------------------------
SELECT distinct ROW_NUMBER() OVER(ORDER BY shortdate) AS Row,
	cast(shortdate as date) as shortdate
into #date
FROM [ADTCMart].[dim].[Date]
where cast(shortdate as date) between @startdate and @enddate
order by shortdate; 

select * from #date order by shortdate; 


----------------------------------------------
/***** create census table *****/
----------------------------------------------
create table #census (censusdate date
	,censustime time
	,nursingunitcode varchar(100)
	,accountnum varchar(50))
	--,AttendDoctorCode varchar(50)
	--,AttendDoctorName varchar(100) 
	--,[AttendDoctorService] varchar(100)
	--,ALCFlag varchar(10)
	--,[PatientServiceDescription] varchar(100)
	--,[AdmitToCensusDays] int)

select * from #census -- order by attenddoctorname; 


----------------------------------------------
/***** establish baseline census data *****/
----------------------------------------------
declare @censusdate date
	,@censusdatecounter int
	,@censusdatecountermax int
set @censusdatecounter =1
set @censusdatecountermax = (select max(row) from #date)


while @censusdatecounter <= @censusdatecountermax 
BEGIN
set @censusdate =(select shortdate from #date where row=@censusdatecounter)

insert into #census 
select cast(@censusdate as date) as censusdate
	,cast(dateadd(mi,1,cast(@censusdate as datetime)) as time) as censustime
	,nursingunitcode
	,accountnum
	--,AttendDoctorCode
	--,AttendDoctorName
	--,case when [AttendDoctorName] in (select hospitalist from #hospitalistlist) 
	--	then 'Hospitalist' 
	--	else [AttendDoctorService] 
	--	end as [AttendDoctorService]
	--,case when Patientservicecode like 'AL[0-9]' or Patientservicecode like 'A[0-9]%' or Patientservicecode = 'ALC' 
	--	then 'ALC' 
	--	else 'Not ALC' 
	--	end as ALCFlag
	--,[PatientServiceDescription]
	--,[AdmitToCensusDays]
from [ADTC].[CensusView] adt
inner join [ADRMart].[dbo].[vwAbstractFact] adr
	on (adt.PatientID = adr.PatientID 
		and adt.[AccountNum] = adr.registernumber) 
where facilitylongname=@site
	--and [AttendDoctorName] in (select hospitalist from #hospitalistlist)
	--and accounttype in ('i','inpatient')
	--and AccountSubType  in ('Acute','Geriatric','*IP Hospice','*IP Medical','*IP Obstetrics','*IP Pediatrics','*IP Psychiatric','*IP Surgical')
	--and [NursingUnitCode] not like 'M[0-9]%'
	--and Patientservicecode<>'nb'
	and censusdate=dateadd(dd,-1,@censusdate)
	--and adr.MainPtServiceDesc in ('Cardiovascular Surgery'
	--	, 'General Surgery'
	--	, 'Neurosurgery'
	--	, 'Orthopaedic Surgery'
	--	, 'Plastic Surgery') 

--select * from #census --order by censusdate,censustime; 

--/***** loop through the times *****/
declare @timecounter int
	,@timecountermax int
set @timecounter=2
set @timecountermax=24

while @timecounter <= @timecountermax 
BEGIN

--/***** add baseline census each hour ****/
insert into #census
select censusdate
	,(select [Time24Hr] from #time 
		where row=@timecounter) as censustime
	,nursingunitcode
	,accountnum
	--,AttendDoctorCode
	--,AttendDoctorName
	--,[AttendDoctorService]
	--,ALCFlag
	--,[PatientServiceDescription]
	--,[AdmitToCensusDays]
from #census 
where censusdate=@censusdate and censustime=(select [Time24Hr] from #time where row=@timecounter-1)

--/***** add admissions each hour *****/
insert into #census
select cast(adjustedadmissiondate as date) as censusdate
	,(select [Time24Hr] from #time 
		where row=@timecounter) as censustime
	,admissionnursingunitcode as nursingunitcode
	,AccountNumber as accountnum
	--,[AdmissionAttendingDoctorCode] as AttendDoctorCode
	--,[AdmissionAttendingDoctorName] as AttendDoctorName
	--,case when [AdmissionAttendingDoctorName] in (select hospitalist from #hospitalistlist) 
	--	then 'Hospitalist' 
	--	else [admissionAttendingDoctorService] 
	--	end as [AttendDoctorService]
	--,'Not ALC' as ALCFlag
	--,[AdmissionPatientServiceDescription] as [PatientServiceDescription]
	--,0 as [AdmitToCensusDays]
from [ADTC].[AdmissionDischargeView]
where admissionfacilitylongname=@site
	--and [AttendDoctorName] in (select hospitalist from #hospitalistlist)
	and cast(adjustedadmissiondate as date)=@censusdate 
	--and accounttype in ('i','inpatient')
	--and admissionAccountSubType  in ('Acute','Geriatric','*IP Hospice','*IP Medical','*IP Obstetrics','*IP Pediatrics','*IP Psychiatric','*IP Surgical')
	--and [AdmissionNursingUnitCode] not like 'M[0-9]%'
	--and admissionPatientservicecode<>'nb'
	and cast(adjustedadmissiontime as time) between (select [Time24Hr] from #time where row=@timecounter-1) and (select [Time24Hr] from #time where row=@timecounter)

--/***** remove discharges each hour *****/
delete #census
where accountnum in (
select AccountNumber
	--cast(adjusteddischargedate as date) as censusdate,(select [Time24Hr] from #time where row=@timecounter) as censustime
	--,dischargenursingunitcode as nursingunitcode,AccountNumber as accountnum
	--,case when [dischargeAttendingDrName] in (select hospitalist from #hospitalistlist) then 'Hospitalist' else [dischargeAttendingDrService] end as [AttendDoctorService]
	--,case when DischargePatientServiceCode like 'AL[0-9]' or DischargePatientServiceCode like 'A[0-9]%' then 'ALC' else 'Not ALC' end as ALCFlag
	--,[dischargePatientServiceDescription] as [PatientServiceDescription]
	--,0 as [AdmitToCensusDays]
from [ADTC].[AdmissionDischargeView]
where dischargefacilitylongname=@site
	--and [AttendDoctorName] in (select hospitalist from #hospitalistlist)
	and cast(adjusteddischargedate as date)=@censusdate 
	--and accounttype in ('i','inpatient')
	--and dischargeAccountSubType  in ('Acute','Geriatric','*IP Hospice','*IP Medical','*IP Obstetrics','*IP Pediatrics','*IP Psychiatric','*IP Surgical')
	--and [dischargeNursingUnitCode] not like 'M[0-9]%'
	--and dischargePatientservicecode<>'nb'
	and cast(adjusteddischargetime as time) between (select [Time24Hr] from #time where row=@timecounter-1) and (select [Time24Hr] from #time where row=@timecounter)
	) and censusdate=@censusdate and censustime = (select [Time24Hr] from #time where row=@timecounter)


set @timecounter =@timecounter +1
END

set @censusdatecounter= @censusdatecounter+1
END


/*
if @site='lions gate hospital'
begin
select * into dssi.dbo.LGHCensusByTOD_FY2016
from #census
end

if @site='vancouver general hospital'
begin
select * into dssi.dbo.VGHCensusByTOD_FY2016
from #census
end
*/

----------------------------------------------
/********  Ends here *******/
----------------------------------------------
-- return daily total census figures for surgery units: 
select censusdate
	,censustime
	,nursingunitcode
	,count(*) as census
from #census
	--where [AttendDoctorService]='hospitalist'
where nursingunitcode in ('6e', '6w', 'sco')
group by censusdate,censustime, nursingunitcode
order by censusdate,censustime, nursingunitcode


--drop table #hospitalistlist 
--drop table #time
--drop table #date
--drop table #census


/*
----------------------------------------------
/***** Return data *******/
----------------------------------------------

-- select * from #census order by censusdate, accountnum, attenddoctorservice, attenddoctorname, censustime; 

/*
-- group by fiscal period: 
select fiscalperiodlong
	,censustime
	,[AttendDoctorService]
	,count(*)*1.0/daysinfiscalperiod as avgcensus
from #census
left outer join dim.[date] on cast(shortdate as date)=censusdate
--where [AttendDoctorService]='hospitalist'
group by fiscalperiodlong,censustime,[AttendDoctorService],daysinfiscalperiod
order by fiscalperiodlong,censustime
*/

-- group by censusdate, doctorService: 
select censusdate
	,censustime
	--,[AttendDoctorService]
	,nursingunitcode
	,count(*)*1.0 as census
	,sum(case when alcflag<>'alc' then 1 else 0 end)*1.0 as acutecensus
	,sum(case when alcflag='alc' then 1 else 0 end)*1.0 as alccensus
from #census
	left outer join dim.[date] 
	on cast(shortdate as date)=censusdate
	--where [AttendDoctorService]='hospitalist'
	--and censustime ='00:01:00.0000000'
where nursingunitcode in ('6w') 
group by censusdate
	,censustime
	--,[AttendDoctorService]
	, nursingunitcode
	, daysinfiscalperiod
order by censusdate,censustime, nursingunitcode


-- group by drcode, drname, grouping across days and times: 
select AttendDoctorCode
	,AttendDoctorName
	,[AttendDoctorService]

	-- for the avg across the day, we need to divide the total for the day by 24 hours: 
	,(count(*)*1.0/@numdays/24) as avg_daily_census
	,(sum(case when alcflag<>'alc' then 1 else 0 end)*1.0/@numdays/24) as avg_daily_acutecensus
	,(sum(case when alcflag='alc' then 1 else 0 end)*1.0/@numdays/24) avg_daily_alccensus

from #census
	left outer join dim.[date] 
		on cast(shortdate as date)=censusdate
	--where [AttendDoctorService]='hospitalist'
	--and censustime ='00:01:00.0000000'
where [AttendDoctorService] in (
	'Family Practice/General Practice Medicine'
	,'Hospitalist'
	,'Internal Medicine')
group by AttendDoctorCode
	,AttendDoctorName
	,[AttendDoctorService]
order by AttendDoctorService 
	,AttendDoctorName; 

/*
-- why are there repeated names with different codes??? 
select attenddoctorcode, attenddoctorname 
from #census 
--group by attenddoctorcode, attenddoctorname 
order by AttendDoctorname; 

--compare with attendoctor names from adtcs: 
--each doc should have only 1 code associated with them 
select attenddoctorcode, attenddoctorname, [AttendDoctorService], FacilityLongName, count(*)   
from adtc.Censusview 
where [FacilityLongName] = 'Lions Gate Hospital' 
group by attenddoctorcode, attenddoctorname,[AttendDoctorService], FacilityLongName  
order by AttendDoctorname; 
*/
*/
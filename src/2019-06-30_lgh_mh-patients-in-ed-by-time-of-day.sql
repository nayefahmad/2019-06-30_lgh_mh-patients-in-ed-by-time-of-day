

/* ---------------------------------
LGH MH patients in ED, by hour of day 
2019-06-30
Nayef 

*/ ---------------------------------

-- based on start time 
select interval_1_hour_at_start_date
     -- , patient_id 
    , count(1) as num 
from emergency
where facility_short_name = 'LGH'
    and fiscal_year_at_start_date in ('18/19', '19/20') 
    and start_date_id < '20190624' 
    
    
group by interval_1_hour_at_start_date







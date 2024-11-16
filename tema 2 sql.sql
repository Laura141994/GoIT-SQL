SELECT ad_date, campaign_id,sum(spend) as total_cost, 
sum(impressions)as impressions_number, 
sum(clicks) as total_clicks, 
sum(value) as total_conversion_value,
sum(spend)/ sum(clicks) as CPC,
sum(cast(spend as float)) / sum(cast(impressions as float))*1000 as CPM,
sum(cast(clicks as float))/ sum(cast(impressions as float)) *1000 as CTR,
sum(value :: float) / sum(spend :: float)*100 as ROMI
FROM public.facebook_ads_basic_daily
where clicks>0 and impressions>0 and spend>0
group by ad_date, campaign_id
order by ad_date, campaign_id


WITH campaign_stats as (
select 
campaign_id,
sum(spend) as total_cost, 
sum(value) as total_conversion_value,
sum(value :: float) / sum(spend :: float)*100 as ROMI
from public.facebook_ads_basic_daily 
group by campaign_id 
)
select campaign_id,total_cost ,ROMI
from campaign_stats
where total_cost>500000
order by ROMI desc 
limit 1;


select *
from public.facebook_ads_basic_daily


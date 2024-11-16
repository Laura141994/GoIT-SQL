create view comb_date as
with comb as (
select
	fab.ad_date,
	fc.campaign_id,
	fad.adset_id,
	coalesce (fab.spend,0) as spend,
	coalesce (fab.impressions,0) as impressions,
	coalesce (fab.reach,0) as reach,
	coalesce (fab.clicks,0) as clicks,
	coalesce (fab.leads,0) as leads,
	coalesce (fab.value,0) as value,
	coalesce (fab.url_parameters, '0') as url_p
from
	public.facebook_ads_basic_daily as fab
left join public.facebook_adset as fad on
	fab.adset_id = fad.adset_id
left join public.facebook_campaign as fc on
	fab.campaign_id = fc.campaign_id
union all
select 
	gabd.ad_date,
	gabd.campaign_name,
	null as adset_id,
	coalesce (gabd.spend,0)as spend,
	coalesce (gabd.impressions,0) as impressions,
	coalesce (gabd.reach,0) as reach,
	coalesce (gabd.clicks,0) as clicks,
	coalesce (gabd.leads,0) as leads,
	coalesce (gabd.value,0) as value,
	coalesce (gabd.url_parameters,'0') as url_p
from
	public.google_ads_basic_daily as gabd
)
select
	ad_date,
	url_p,
	sum(spend) as total_spend,
	 sum(impressions)as impressions,
	sum(reach)as reach,
	sum(clicks)as clicks,
	sum(leads)as leads,
	sum(value) as total_value,
	case 
		WHEN LOWER(SUBSTRING(url_p FROM 'utm_campaign=([^#!&]+)')) = 'nan' THEN NULL 
        ELSE LOWER(SUBSTRING(url_p FROM 'utm_campaign=([^#!&]+)'))
	end utm_campaign,
	case
		when sum(impressions)>0 then (SUM(CAST(clicks AS FLOAT)) / SUM(CAST(impressions AS FLOAT))) *100
		else 0
	end as CTR,
	case
		when SUM(clicks) > 0 THEN SUM(spend) / SUM(clicks) else 0
	end as CPC,
	case 
		when sum(impressions)>0 then (SUM(CAST(spend AS FLOAT))) / SUM(CAST(impressions AS FLOAT)) *1000 else 0
	end as CPM,
	case
		when sum(spend)>0 then ((SUM(CAST(value AS FLOAT)) - SUM(CAST(spend AS FLOAT))) / SUM(CAST(spend AS FLOAT))) * 100 else 0
	end as ROMI	
from
	comb
GROUP BY 
ad_date, 
url_p
order by ad_date asc

select * from view.comb_date

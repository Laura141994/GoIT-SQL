--primutl CTE unde combinam datele 
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
),
sec_cte as(
select -- al doilea CTE unde agregam datele
	DATE_TRUNC('month', ad_date) AS ad_month, -- Prima zi a lunii
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
ad_month,
utm_campaign
), cte_diff as(
select -- al treilea cte unde calculam diferentele si afisam rezultatul final
        ad_month,
        total_spend,
        impressions,
        clicks,
        total_value,
        utm_campaign,
        CPC,
        CTR,
        CPM,
        ROMI,
        -- Calculează diferențele procentuale față de luna anterioară
        LAG(CPM) OVER(PARTITION BY utm_campaign ORDER BY ad_month) AS prev_month_CPM,
        CASE
            WHEN LAG(CPM) OVER(PARTITION BY utm_campaign ORDER BY ad_month) IS NOT NULL THEN 
                ((CPM - LAG(CPM) OVER(PARTITION BY utm_campaign ORDER BY ad_month)) / NULLIF(LAG(CPM) OVER(PARTITION BY utm_campaign ORDER BY ad_month), 0)) * 100 -- (curent - anterior) / anterior * 100
            ELSE 0
        END AS CPM_diff,
        LAG(CTR) OVER(PARTITION BY utm_campaign ORDER BY ad_month) AS prev_month_CTR,
        CASE 
            WHEN LAG(CTR) OVER(PARTITION BY utm_campaign ORDER BY ad_month) IS NOT NULL THEN 
                ((CTR - LAG(CTR) OVER(PARTITION BY utm_campaign ORDER BY ad_month)) / NULLIF(LAG(CTR) OVER(PARTITION BY utm_campaign ORDER BY ad_month), 0)) * 100
            ELSE 0
        END AS CTR_diff,
        LAG(ROMI) OVER(PARTITION BY utm_campaign ORDER BY ad_month) AS prev_month_ROMI,
        CASE 
            WHEN LAG(ROMI) OVER(PARTITION BY utm_campaign ORDER BY ad_month) IS NOT NULL THEN 
                ((ROMI - LAG(ROMI) OVER(PARTITION BY utm_campaign ORDER BY ad_month)) / NULLIF(LAG(ROMI) OVER(PARTITION BY utm_campaign ORDER BY ad_month), 0)) * 100
            ELSE 0
        END AS ROMI_diff
    FROM 
        sec_cte
)    --selectam rezultatele finale
select
 ad_month,
    utm_campaign,
    total_spend,
    impressions,
    clicks,
    total_value,
    CTR,
    CPM,
    ROMI,
    CPM_diff,
    CTR_diff,
    Romi_diff
 from cte_diff
order by 
utm_campaign,
ad_month



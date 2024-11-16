WITH facebook_comb AS (
    SELECT 
        fbd.ad_date,
        fc.campaign_name,
        fbd.spend,
        fbd.impressions,
        fbd.reach,
        fbd.clicks,
        fbd.leads,
        fbd.value,
        fa.adset_name
    FROM public.facebook_ads_basic_daily AS fbd
    INNER JOIN facebook_adset AS fa ON fbd.adset_id = fa.adset_id
    INNER JOIN facebook_campaign AS fc ON fbd.campaign_id = fc.campaign_id
),
google_comb AS (
    SELECT 
        gabd.ad_date,
        gabd.campaign_name,
        gabd.spend,
        gabd.impressions,
        gabd.reach,
        gabd.clicks,
        gabd.leads,
        gabd.value,
        NULL AS adset_name 
    FROM public.google_ads_basic_daily AS gabd
)
SELECT 
    ad_date,
    campaign_name,
    SUM(spend) AS total_spend,
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks,
    SUM(value) AS total_value
FROM (
    SELECT * FROM facebook_comb
    UNION ALL
    SELECT * FROM google_comb
) comb_ads
GROUP BY ad_date, campaign_name
ORDER BY ad_date, campaign_name;

select*
from public.facebook_ads_basic_daily 
order by ad_date asc  

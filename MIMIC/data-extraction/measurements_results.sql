SELECT DISTINCT 
chart.icustay_id as icustay_id,
chart.valuenum as spO2_Value,
chart.charttime as measurement_time
FROM `oxygenators-209612.mimiciii_clinical.chartevents` AS chart
WHERE chart.itemid in (220277, 646) 
AND chart.valuenum IS NOT NULL

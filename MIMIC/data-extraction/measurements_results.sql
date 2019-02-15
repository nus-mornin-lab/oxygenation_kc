WITH ce AS (SELECT DISTINCT 
chart.icustay_id,
chart.valuenum as spO2_Value,
chart.charttime
FROM `oxygenators-209612.mimiciii_clinical.chartevents` AS chart
WHERE chart.itemid in (220277, 646) 
AND chart.valuenum IS NOT NULL
-- exclude rows marked as error
and (chart.error <> 1 OR chart.error IS NULL) --chart.error IS DISTINCT FROM 1
-- We remove oxygen measurements that are outside of the range [10, 100]
AND chart.valuenum >= 10 AND chart.valuenum <= 100
)

-- Edited from https://github.com/cosgriffc/hyperoxia-sepsis
SELECT DISTINCT
    ce.icustay_id
  , COUNT(ce.spO2_Value) OVER(PARTITION BY ce.icustay_id) AS nOxy
  , PERCENTILE_CONT(ce.spO2_Value, 0.5) OVER(PARTITION BY ce.icustay_id) AS median
  , AVG(CAST(ce.spO2_Value < 94 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS propBelow
  , AVG(CAST(ce.spO2_Value > 97 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS propAbove
FROM ce
INNER JOIN `oxygenators-209612.mimiciii_clinical.mimic_oxygen_therapy` vd ON ce.icustay_id = vd.icustay_id
WHERE vd.vent_start <= ce.charttime AND vd.vent_end >= ce.charttime
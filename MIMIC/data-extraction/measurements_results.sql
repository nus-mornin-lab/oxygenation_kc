WITH ce AS (SELECT DISTINCT 
chart.icustay_id,
chart.valuenum as spO2_Value,
chart.charttime
FROM `oxygenators-209612.mimiciii_clinical.chartevents` AS chart
WHERE chart.itemid in (220277, 646) 
AND chart.valuenum IS NOT NULL
-- exclude rows marked as error
and (chart.error <> 1 OR chart.error IS NULL) --chart.error IS DISTINCT FROM 1
)

-- Edited from https://github.com/cosgriffc/hyperoxia-sepsis
SELECT
    ce.icustay_id,
    ce.spO2_Value
FROM ce
INNER JOIN `oxygenators-209612.mimiciii_clinical.mimic_oxygen_therapy` vd ON ce.icustay_id = vd.icustay_id
WHERE vd.vent_start <= ce.charttime AND vd.vent_end >= ce.charttime AND vd.ventnum_seq = 1
WITH 

chart AS (
SELECT * FROM `oxygenators-209612.eicu.nursecharting`),


SELECT 
  chart.patientunitstayid as icustay_id,
  SAFE_CAST(chart.nursingchartvalue as FLOAT64) as spO2_Value, 
  chart.nursingchartoffset / (24 * 60) as measurement_time      
FROM chart
WHERE chart.nursingchartcelltypevalname = "O2 Saturation"
/* The following selection can also be done in R to investigate any data quality issues
AND chart.nursingchartoffset / (24 * 60) > 0
AND chart.nursingchartoffset / (24 * 60) < pc.icu_length_of_stay */

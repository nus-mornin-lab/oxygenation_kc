WITH 

pat AS (
SELECT * FROM `oxygenators-209612.eicu.patient`),

chart AS (
SELECT * FROM `oxygenators-209612.eicu.nursecharting`),

pc AS (
SELECT * FROM `oxygenators-209612.eicu.patient_cohort`)



SELECT 
  pc.subject_id as patient_ID,
  SAFE_CAST(chart.nursingchartvalue as float) as spO2_Value, 
  chart.nursingchartoffset / (24 * 60) as measurement_time      
FROM pc
INNER JOIN chart
  ON chart.patientunitstayid = pc.icustay_id 
WHERE chart.nursingchartcelltypevalname = "O2 Saturation"
AND chart.nursingchartoffset / (24 * 60) > 0
AND chart.nursingchartoffset / (24 * 60) < pc.icu_length_of_stay

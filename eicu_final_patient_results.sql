WITH 

pat AS (
SELECT * FROM `oxygenators-209612.eicu.patient`),

pc AS (
SELECT * FROM `oxygenators-209612.eicu.patient_cohort`)

SELECT 
  pc.subject_id as patient_ID,
  pat.gender,
  pc.age,  
  pc.icu_length_of_stay,
  pc.max_fiO2,
  pat.hospitalid,
--  pc.is_first_icu_stay,
  CASE WHEN pat.unitdischargestatus = "Alive" THEN 0 ELSE 1 END AS mortality_in_ICU,
  CASE WHEN pat.hospitaldischargestatus = "Alive" THEN 0 ELSE 1 END AS mortality_in_Hospt
FROM pc
INNER JOIN pat
  ON pc.icustay_id = pat.patientunitstayid

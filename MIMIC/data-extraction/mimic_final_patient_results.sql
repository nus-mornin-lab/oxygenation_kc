WITH

mortality_type AS (
SELECT
  icu.icustay_id AS icustay_id,
  CASE WHEN admissions.deathtime BETWEEN admissions.admittime and admissions.dischtime
  THEN 1 
  ELSE 0
  END AS mortality_in_Hospt, 
  CASE WHEN admissions.deathtime BETWEEN icu.intime and icu.outtime
  THEN 1
  ELSE 0
  END AS mortality_in_ICU,
  admissions.deathtime as deathtime, 
  icu.intime as ICU_intime
FROM `oxygenators-209612.mimiciii_clinical.icustays` AS icu
LEFT JOIN `oxygenators-209612.mimiciii_clinical.admissions` AS admissions
  ON icu.hadm_id = admissions.hadm_id),



--NOTE currently unused, patient cohort to be moved to R

first_stay AS (
SELECT
MIN(DATE(icu.intime)) AS first_icu_date,
icu.subject_id AS subject_id
FROM `oxygenators-209612.mimiciii_clinical.icustays` AS icu
GROUP BY subject_id),


--NOTE currently unused, patient cohort to be moved to R

ventilation AS (
SELECT
  MAX(chart.valuenum) AS max_fiO2,
  chart.subject_id,
  chart.icustay_id
FROM `oxygenators-209612.mimiciii_clinical.chartevents` AS chart
WHERE chart.itemid in (3420, 190, 223835, 3422)
GROUP BY chart.subject_id, chart.icustay_id),


--NOTE currently unused, didn't seem to be output by previous MIMIC script

vent_settings AS (
SELECT
CASE (SELECT count(mechvent)
FROM `oxygenators-209612.mimiciii_clinical.ventsettings` AS ventsettings
WHERE mechvent = 1 
AND ventsettings.icustay_id = icu.icustay_id)  
WHEN 0 THEN 0 
ELSE 1 
END AS invasive
FROM `oxygenators-209612.mimiciii_clinical.icustays` AS icu)


-- Note that icustays has duplicate icustay_id, need to check the final
-- table has no duplicates.

SELECT DISTINCT
icu.hadm_id AS HADM_id,       
icu.icustay_id AS icustay_id,       
icu.subject_id AS patient_ID,
pat.gender AS gender,
DATE_DIFF(DATE(icu.intime), DATE(pat.dob), YEAR) AS age,  
DATETIME_DIFF(icu.outtime, icu.intime, HOUR) / 24 AS icu_length_of_stay,
mortality_type.* EXCEPT(icustay_id),
icd.* EXCEPT(subject_id, icustay_id),
apsiii.apsiii,
elix.congestive_heart_failure, 
elix.hypertension, 
elix.chronic_pulmonary, 
elix.diabetes_uncomplicated, 
elix.diabetes_complicated, 
elix.renal_failure, 
elix.liver_disease, 
elix.lymphoma, 
elix.solid_tumor, 
elix.metastatic_cancer,
angus.angus,
sofa.sofa,
fluid_balance.fluid_balance, 
mech_vent.tidal_high_count2 as tidal_count_percentage
FROM `oxygenators-209612.mimiciii_clinical.icustays` AS icu
INNER JOIN `oxygenators-209612.mimiciii_clinical.patients` AS pat
  ON icu.subject_id = pat.subject_id
LEFT JOIN mortality_type
  ON icu.icustay_id = mortality_type.icustay_id
LEFT JOIN `oxygenators-209612.mimiciii_clinical.icd_codes` AS icd 
  ON icu.hadm_id = icd.hadm_id
LEFT JOIN `oxygenators-209612.mimiciii_clinical.elixhauser_quan` AS elix
  ON icu.hadm_id = elix.hadm_id
LEFT JOIN `oxygenators-209612.mimiciii_clinical.angus_sepsis` AS angus
  ON icu.hadm_id = angus.hadm_id
LEFT JOIN `oxygenators-209612.mimiciii_clinical.apsiii` AS apsiii
  ON icu.icustay_id = apsiii.icustay_id
LEFT JOIN `oxygenators-209612.mimiciii_clinical.sofa` sofa 
  ON icu.icustay_id = SOFA.icustay_id
LEFT JOIN `oxygenators-209612.mimiciii_clinical.fluid_balance` fluid_balance 
  ON icu.icustay_id = fluid_balance.icustay_id
LEFT JOIN `oxygenators-209612.mimiciii_clinical.mechanical_ventilative_volume` mech_vent 
  ON icu.icustay_id = mech_vent.icustay_id

--Use this to validate non-duplicate icustay_id
--SELECT test.icustay_id, count(test.icustay_id) as c FROM test GROUP BY test.icustay_id ORDER BY c DESC LIMIT 100



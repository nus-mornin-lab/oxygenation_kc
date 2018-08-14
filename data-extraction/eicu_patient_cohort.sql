WITH 

pat AS (
SELECT * FROM `oxygenators-209612.eicu.patient`),

chart AS (
SELECT * FROM `oxygenators-209612.eicu.nursecharting`),


ps AS (
SELECT
  pat.uniquepid AS subject_id,
  pat.patienthealthsystemstayid AS hadm_id,
  pat.patientunitstayid AS icustay_id,
  SAFE_CAST(REGEXP_EXTRACT(pat.age, r"[0-9]+") as FLOAT64) AS age,
  pat.hospitaladmitoffset AS hospitaladmitoffset,
  pat.unitdischargeoffset / (24 * 60) AS icu_length_of_stay,
  pat.hospitalid AS hospital_id
FROM pat),


--TODO: Validate what O2 L/% is.

ventilation AS (
SELECT
  MAX(SAFE_CAST(chart.nursingchartvalue as FLOAT64)) AS max_fiO2,
  chart.patientunitstayid AS icustay_id
FROM chart
WHERE chart.nursingchartcelltypevalname = "O2 L/%"
GROUP BY chart.patientunitstayid)


SELECT
  ps.subject_id,
  ps.icustay_id,
  ps.age,
  ps.icu_length_of_stay,
  ventilation.max_fiO2,
  ps.hospital_id
  --CASE WHEN pat.hospitaladmitoffset = first_stay.first_icu_offset THEN 1 ELSE 0 END AS is_first_icu_stay
FROM ps
--INNER JOIN first_stay
--  ON ps.subject_id = first_stay.subject_id
LEFT JOIN ventilation
  ON ps.icustay_id = ventilation.icustay_id

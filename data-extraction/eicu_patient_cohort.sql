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
  SAFE_CAST(REGEXP_EXTRACT(pat.age, r"[0-9]+") as float) AS age,
  pat.hospitaladmitoffset AS hospitaladmitoffset,
  pat.unitdischargeoffset / (24 * 60) AS icu_length_of_stay,
  pat.hospitalid AS hospital_id
FROM pat
WHERE pat.unitdischargeoffset > 0),


--TODO: Figure out how to choose only the first stays, there doesn't seem
--      to be a simple way of determining this.
--
--      This method is wrong and will not select the first stay

--first_stay AS (
--SELECT
--  MAX(pat.hospitaladmitoffset) AS first_icu_offset,
--  pat.uniquepid AS subject_id
--FROM pat
--GROUP BY pat.uniquepid),


--TODO: Validate what O2 L/% is.

ventilation AS (
SELECT
  MAX(SAFE_CAST(chart.nursingchartvalue as float)) AS max_fiO2,
  chart.patientunitstayid AS icustay_id
FROM chart
WHERE chart.nursingchartcelltypevalname = "O2 L/%"
GROUP BY chart.patientunitstayid)


SELECT
  ps.subject_id AS subject_id,
  MAX(ps.icustay_id) AS icustay_id,
  MAX(ps.age) as age,
  MAX(ps.icu_length_of_stay) as icu_length_of_stay,
  MAX(ventilation.max_fiO2) as max_fiO2,
  MAX(ps.hospital_id) AS hospital_id
  --CASE WHEN pat.hospitaladmitoffset = first_stay.first_icu_offset THEN 1 ELSE 0 END AS is_first_icu_stay
FROM ps
--INNER JOIN first_stay
--  ON ps.subject_id = first_stay.subject_id
INNER JOIN ventilation
  ON ps.icustay_id = ventilation.icustay_id
GROUP BY ps.subject_id

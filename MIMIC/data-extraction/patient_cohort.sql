WITH ps AS (
SELECT
  icu.subject_id,
  icu.hadm_id,
  icu.icustay_id,
  pat.dob,
  DATE(icu.intime) AS icu_date,
  DATETIME_DIFF(icu.outtime, icu.intime, HOUR) / 24 AS icu_length_of_stay,
  DATE_DIFF(DATE(icu.intime), DATE(pat.dob), YEAR) AS age
FROM `oxygenators-209612.mimiciii_clinical.icustays` AS icu
INNER JOIN `oxygenators-209612.mimiciii_clinical.patients` AS pat
  ON icu.subject_id = pat.subject_id),
first_stay AS (
SELECT
MIN(DATE(icu.intime)) AS first_icu_date,
icu.subject_id AS subject_id
FROM `oxygenators-209612.mimiciii_clinical.icustays` AS icu
GROUP BY subject_id),
ventilation AS (
SELECT
  MAX(chart.valuenum) AS max_fiO2,
  chart.subject_id,
  chart.icustay_id
FROM `oxygenators-209612.mimiciii_clinical.chartevents` AS chart
WHERE chart.itemid in (3420, 190, 223835, 3422)
GROUP BY chart.subject_id, chart.icustay_id)
SELECT
  ps.subject_id AS subject_id,
  MAX(ps.icustay_id) AS icustay_id,
  MAX(ps.age) as age,
  MAX(ps.icu_length_of_stay) as icu_length_of_stay,
  MAX(ventilation.max_fiO2) as max_fiO2
FROM ps
INNER JOIN first_stay
  ON ps.subject_id = first_stay.subject_id
INNER JOIN ventilation
  ON ps.subject_id = ventilation.subject_id
WHERE age >= 16
AND icu_length_of_stay >= 3
AND first_stay.first_icu_date = icu_date
AND ventilation.max_fiO2 > 24
GROUP BY ps.subject_id

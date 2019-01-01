WITH icd_presence AS (
SELECT
icd.subject_id,
pat.icustay_id,
SAFE_CAST(SUBSTR(icd.icd9_code, 0, 3) as numeric) AS icd_num
FROM `oxygenators-209612.mimiciii_clinical.diagnoses_icd` AS icd
INNER JOIN `oxygenators-209612.mimiciii_clinical.patient_cohort` AS pat
  ON pat.subject_id = icd.subject_id)
SELECT
icd_presence.subject_id,
icd_presence.icustay_id,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 001 AND 139 THEN 1 END) > 0 AS has_infectous_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 140 AND 239 THEN 1 END) > 0 AS has_neoplasm_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 240 AND 279 THEN 1 END) > 0 AS has_endocrine_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 280 AND 289 THEN 1 END) > 0 AS has_blood_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 290 AND 319 THEN 1 END) > 0 AS has_mental_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 320 AND 389 THEN 1 END) > 0 AS has_nervous_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 390 AND 459 THEN 1 END) > 0 AS has_circulatory_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 460 AND 519 THEN 1 END) > 0 AS has_respiratory_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 520 AND 579 THEN 1 END) > 0 AS has_digestive_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 580 AND 629 THEN 1 END) > 0 AS has_urinary_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 630 AND 679 THEN 1 END) > 0 AS has_pregnancy_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 680 AND 709 THEN 1 END) > 0 AS has_skin_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 710 AND 739 THEN 1 END) > 0 AS has_muscle_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 740 AND 759 THEN 1 END) > 0 AS has_congenital_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 760 AND 779 THEN 1 END) > 0 AS has_perinatal_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 780 AND 799 THEN 1 END) > 0 AS has_other_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 800 AND 999 THEN 1 END) > 0 AS has_injury_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 410 AND 414 THEN 1 END) > 0 AS has_isachaemic_heart_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 427 AND 427 THEN 1 END) > 0 AS has_atrial_fibrillation_disease,
COUNT(CASE WHEN icd_presence.icd_num BETWEEN 434 AND 434 THEN 1 END) > 0 AS has_stroke_disease
FROM icd_presence
GROUP BY icd_presence.subject_id, icd_presence.icustay_id

WITH 

pat AS (
SELECT * FROM `oxygenators-209612.eicu.patient`),

diag AS (
SELECT * FROM `oxygenators-209612.eicu.diagnosis`),

apsiii_raw AS (
SELECT * FROM `oxygenators-209612.eicu.apachepatientresult`),

intakeoutput AS (
SELECT DISTINCT
patientunitstayid,
intakeoutputoffset,
nettotal
FROM `oxygenators-209612.eicu.intakeoutput`),

sofa_results AS (
SELECT * FROM `oxygenators-209612.eicu.sofa_results`),


icd_code AS (
SELECT
diag.patientunitstayid,
SAFE_CAST(SUBSTR(diag.icd9code, 0, 3) as INT64) AS icd9code,
icd9code AS icd9code_string
FROM diag),


icd_presence AS (
SELECT
icd_code.patientunitstayid,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 001 AND 139 THEN 1 END) > 0 AS has_infectous_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 038 AND 038 THEN 1 END) > 0 AS has_sepsis,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 140 AND 239 THEN 1 END) > 0 AS has_neoplasm_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 140 AND 209 THEN 1 END) > 0 AS has_cancer_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 240 AND 279 THEN 1 END) > 0 AS has_endocrine_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 250 AND 250 THEN 1 END) > 0 AS has_diabetes_mellitus_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 280 AND 289 THEN 1 END) > 0 AS has_blood_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 290 AND 319 THEN 1 END) > 0 AS has_mental_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 320 AND 389 THEN 1 END) > 0 AS has_nervous_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 390 AND 459 THEN 1 END) > 0 AS has_circulatory_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 401 AND 405 THEN 1 END) > 0 AS has_hypertension_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 430 AND 438 THEN 1 END) > 0 AS has_cerebrovascular_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 460 AND 519 THEN 1 END) > 0 AS has_respiratory_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 490 AND 496 THEN 1 END) > 0 AS has_copd_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 520 AND 579 THEN 1 END) > 0 AS has_digestive_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 571 AND 571 THEN 1 END) > 0 AS has_chronic_liver_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 580 AND 629 THEN 1 END) > 0 AS has_urinary_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 630 AND 679 THEN 1 END) > 0 AS has_pregnancy_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 680 AND 709 THEN 1 END) > 0 AS has_skin_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 710 AND 739 THEN 1 END) > 0 AS has_muscle_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 740 AND 759 THEN 1 END) > 0 AS has_congenital_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 760 AND 779 THEN 1 END) > 0 AS has_perinatal_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 780 AND 799 THEN 1 END) > 0 AS has_other_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 800 AND 999 THEN 1 END) > 0 AS has_injury_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 410 AND 414 THEN 1 END) > 0 AS has_isachaemic_heart_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 427 AND 427 THEN 1 END) > 0 AS has_atrial_fibrillation_disease,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 434 AND 434 THEN 1 END) > 0 AS has_stroke_disease,
COUNT(CASE WHEN icd_code.icd9code_string LIKE '%428%' THEN 1 END) > 0 AS CHF, -- Congestive heart failure
COUNT(CASE WHEN icd_code.icd9code_string LIKE '%427.31%' THEN 1 END) > 0 AS AF, -- Atrial fibrillation
COUNT(CASE WHEN icd_code.icd9code_string LIKE '%414.01%' THEN 1 END) > 0 AS CAD, -- Coronary artery disease
COUNT(CASE WHEN icd_code.icd9code_string LIKE '%585%' THEN 1 END) > 0 AS CKD -- Chronic kidney disease
FROM icd_code
GROUP BY icd_code.patientunitstayid),


apsiii AS (
SELECT
apsiii_raw.patientunitstayid,
MAX(apsiii_raw.apachescore) as apsiii
FROM apsiii_raw
GROUP BY apsiii_raw.patientunitstayid),


fluid_balance AS (
SELECT
intakeoutput.patientunitstayid,
SUM(intakeoutput.nettotal) as fluid_balance
FROM intakeoutput
GROUP BY intakeoutput.patientunitstayid),



end_of_life AS (
-- Per https://github.com/MIT-LCP/eicu-code/issues/65
SELECT DISTINCT patientunitstayid
FROM `oxygenators-209612.eicu.careplaneol`
WHERE activeupondischarge

UNION DISTINCT

SELECT DISTINCT patientunitstayid
FROM `oxygenators-209612.eicu.careplangeneral`
WHERE cplitemvalue = "No CPR"
OR cplitemvalue = "Do not resuscitate"
OR cplitemvalue = "Comfort measures only"
OR cplitemvalue = "End of life"
)



, oxygen_therapy AS (
	SELECT *
	FROM `oxygenators-209612.eicu.eicu_oxygen_therapy`
)


-- Extract maximum fraction of inspired oxygen (fiO2) during the oxygen therapy session considered
, fiO2 AS (
  SELECT
    MAX(CASE
      -- fiO2 is sometimes recorded as a fraction and sometimes as a percentage.
      -- We transform fiO2 into percentages.
      WHEN SAFE_CAST(chart.respchartvalue AS FLOAT64) <= 1 THEN 100*SAFE_CAST(chart.respchartvalue AS FLOAT64)
      ELSE SAFE_CAST(chart.respchartvalue AS FLOAT64)
    END) AS max_fiO2
    , chart.patientunitstayid AS icustay_id
  FROM `oxygenators-209612.eicu.respiratorycharting` AS chart
    INNER JOIN oxygen_therapy
    ON chart.patientunitstayid = oxygen_therapy.icustay_id
  WHERE
  	-- Indicates fiO2 record
  	LOWER(chart.respchartvaluelabel) IN ('fio2', 'fio2 (%)')
    -- We are only interested in measurements during the oxygen therapy session.
		AND chart.respchartoffset >= oxygen_therapy.vent_start
    AND chart.respchartoffset <= oxygen_therapy.vent_end
    -- fiO2 cannot be greater than 100%.
    AND SAFE_CAST(chart.respchartvalue AS FLOAT64) <= 100
  GROUP BY chart.patientunitstayid
)


-- Computing summaries of the blood oxygen saturation (SpO2)
, SpO2 AS (

	WITH ce AS (
		SELECT DISTINCT 
			chart.patientunitstayid AS icustay_id
			, SAFE_CAST(chart.nursingchartvalue as FLOAT64) as spO2_Value
			, chart.nursingchartoffset AS charttime
		FROM `oxygenators-209612.eicu.nursecharting` AS chart
		WHERE chart.nursingchartcelltypevalname = "O2 Saturation"
	)

	SELECT DISTINCT
		ce.icustay_id
		-- We currently ignore the time aspect of the measurements.
		-- However, one ideally should take into account that
		-- certain measurements are less spread out than others.
		, COUNT(ce.spO2_Value) OVER(PARTITION BY ce.icustay_id) AS nOxy
		, PERCENTILE_CONT(ce.spO2_Value, 0.5) OVER(PARTITION BY ce.icustay_id) AS median
		, AVG(CAST(ce.spO2_Value < 94 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS propBelow
		, AVG(CAST(ce.spO2_Value > 98 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS propAbove
	FROM ce
		INNER JOIN oxygen_therapy ON ce.icustay_id = oxygen_therapy.icustay_id
	WHERE
		-- We are only interested in measurements during the oxygen therapy session.
		oxygen_therapy.vent_start <= ce.charttime
		AND oxygen_therapy.vent_end >= ce.charttime
		-- We remove oxygen measurements that are outside of the range [10, 100]
		AND ce.spO2_Value >= 10
		AND ce.spO2_Value <= 100

)


-- Same as above but now only considering SpO2 measurements during the first
-- 24/48/72 hours
, SpO2_24 AS (

  WITH ce AS (
    SELECT DISTINCT 
      chart.patientunitstayid AS icustay_id
      , SAFE_CAST(chart.nursingchartvalue as FLOAT64) as spO2_Value
      , chart.nursingchartoffset AS charttime
    FROM `oxygenators-209612.eicu.nursecharting` AS chart
    WHERE chart.nursingchartcelltypevalname = "O2 Saturation"
  )

  SELECT DISTINCT
    ce.icustay_id
    -- We currently ignore the time aspect of the measurements.
    -- However, one idally should take into account that
    -- certain measurements are less spread out than others.
    , COUNT(ce.spO2_Value) OVER(PARTITION BY ce.icustay_id) AS nOxy_24
    , PERCENTILE_CONT(ce.spO2_Value, 0.5) OVER(PARTITION BY ce.icustay_id) AS median_24
    , AVG(CAST(ce.spO2_Value >= 94 AND ce.spO2_Value <= 98 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS prop_24
  FROM ce
    INNER JOIN oxygen_therapy ON ce.icustay_id = oxygen_therapy.icustay_id
  WHERE
    -- We are only interested in measurements during the first 24 hours of the oxygen therapy session.
    oxygen_therapy.vent_start <= ce.charttime
    AND oxygen_therapy.vent_end >= ce.charttime
    AND oxygen_therapy.vent_start + 24*60 >= ce.charttime
    -- We remove oxygen measurements that are outside of the range [10, 100]
    AND ce.spO2_Value >= 10
    AND ce.spO2_Value <= 100

)


, SpO2_48 AS (

  WITH ce AS (
    SELECT DISTINCT 
      chart.patientunitstayid AS icustay_id
      , SAFE_CAST(chart.nursingchartvalue as FLOAT64) as spO2_Value
      , chart.nursingchartoffset AS charttime
    FROM `oxygenators-209612.eicu.nursecharting` AS chart
    WHERE chart.nursingchartcelltypevalname = "O2 Saturation"
  )

  SELECT DISTINCT
    ce.icustay_id
    -- We currently ignore the time aspect of the measurements.
    -- However, one idally should take into account that
    -- certain measurements are less spread out than others.
    , COUNT(ce.spO2_Value) OVER(PARTITION BY ce.icustay_id) AS nOxy_48
    , PERCENTILE_CONT(ce.spO2_Value, 0.5) OVER(PARTITION BY ce.icustay_id) AS median_48
    , AVG(CAST(ce.spO2_Value >= 94 AND ce.spO2_Value <= 98 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS prop_48
  FROM ce
    INNER JOIN oxygen_therapy ON ce.icustay_id = oxygen_therapy.icustay_id
  WHERE
    -- We are only interested in measurements during the first 48 hours of the oxygen therapy session.
    oxygen_therapy.vent_start <= ce.charttime
    AND oxygen_therapy.vent_end >= ce.charttime
    AND oxygen_therapy.vent_start + 48*60 >= ce.charttime
    -- We remove oxygen measurements that are outside of the range [10, 100]
    AND ce.spO2_Value >= 10
    AND ce.spO2_Value <= 100

)


, SpO2_72 AS (

  WITH ce AS (
    SELECT DISTINCT 
      chart.patientunitstayid AS icustay_id
      , SAFE_CAST(chart.nursingchartvalue as FLOAT64) as spO2_Value
      , chart.nursingchartoffset AS charttime
    FROM `oxygenators-209612.eicu.nursecharting` AS chart
    WHERE chart.nursingchartcelltypevalname = "O2 Saturation"
  )

  SELECT DISTINCT
    ce.icustay_id
    -- We currently ignore the time aspect of the measurements.
    -- However, one idally should take into account that
    -- certain measurements are less spread out than others.
    , COUNT(ce.spO2_Value) OVER(PARTITION BY ce.icustay_id) AS nOxy_72
    , PERCENTILE_CONT(ce.spO2_Value, 0.5) OVER(PARTITION BY ce.icustay_id) AS median_72
    , AVG(CAST(ce.spO2_Value >= 94 AND ce.spO2_Value <= 98 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS prop_72
  FROM ce
    INNER JOIN oxygen_therapy ON ce.icustay_id = oxygen_therapy.icustay_id
  WHERE
    -- We are only interested in measurements during the first 72 hours of the oxygen therapy session.
    oxygen_therapy.vent_start <= ce.charttime
    AND oxygen_therapy.vent_end >= ce.charttime
    AND oxygen_therapy.vent_start + 72*60 >= ce.charttime
    -- We remove oxygen measurements that are outside of the range [10, 100]
    AND ce.spO2_Value >= 10
    AND ce.spO2_Value <= 100

)



SELECT 
  pat.gender,
  pat.unittype,
  pat.patientHealthSystemStayID as hospital_stay_id,
  pat.unitVisitNumber as unit_stay_number, -- counter for ICU visits on same hospital stay
  pat.hospitalDischargeYear, -- hospitalAdmitYear is missing in patient table
  pat.uniquepid AS patient_ID,
  pat.patientunitstayid AS icustay_id,
  SAFE_CAST(pat.age AS FLOAT64) AS age,
  pat.admissionHeight AS height,
  pat.admissionWeight AS weight,
--  pat.hospitaladmitoffset AS hospitaladmitoffset,
  pat.unitdischargeoffset / (24 * 60) AS icu_length_of_stay,
  pat.hospitalid AS hospital_id,
  pat.unitdischargestatus AS discharge_status_ICU,
  pat.hospitaldischargestatus AS discharge_status_Hospt,
  pat.ethnicity,
  icd_presence.* EXCEPT(patientunitstayid),
  apsiii.* EXCEPT(patientunitstayid),
  fluid_balance.* EXCEPT(patientunitstayid),
  sofa_results.* EXCEPT(patientunitstayid),
  IF(end_of_life.patientunitstayid IS NULL, FALSE, TRUE) as end_of_life
	, oxygen_therapy.* EXCEPT(icustay_id)
	, fiO2.max_fiO2
	, SpO2.* EXCEPT(icustay_id)
  , SpO2_24.* EXCEPT(icustay_id)
  , SpO2_48.* EXCEPT(icustay_id)
  , SpO2_72.* EXCEPT(icustay_id)
FROM pat
LEFT JOIN icd_presence
  ON pat.patientunitstayid = icd_presence.patientunitstayid
LEFT JOIN apsiii
  ON pat.patientunitstayid = apsiii.patientunitstayid
LEFT JOIN fluid_balance
  ON pat.patientunitstayid = fluid_balance.patientunitstayid
LEFT JOIN sofa_results
  ON pat.patientunitstayid = sofa_results.patientunitstayid
LEFT JOIN end_of_life
  ON pat.patientunitstayid = end_of_life.patientunitstayid
LEFT JOIN oxygen_therapy
  ON pat.patientunitstayid = oxygen_therapy.icustay_id
LEFT JOIN fiO2
  ON pat.patientunitstayid = fiO2.icustay_id
LEFT JOIN SpO2
  ON pat.patientunitstayid = SpO2.icustay_id
LEFT JOIN SpO2_24
  ON pat.patientunitstayid = SpO2_24.icustay_id
LEFT JOIN SpO2_48
  ON pat.patientunitstayid = SpO2_48.icustay_id
LEFT JOIN SpO2_72
  ON pat.patientunitstayid = SpO2_72.icustay_id
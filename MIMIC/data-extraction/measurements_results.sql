SELECT DISTINCT PC.subject_id as patient_ID,
              C.valuenum as spO2_Value, 
              C.valueuom as sp02_Unit,
              C.charttime as measurement_time
              
FROM `nus-datathon-2018-team-01.oxygenation.patient_cohort` PC
INNER JOIN `physionet-data.mimiciii_clinical.patients` P 
  ON P.subject_id = PC.subject_id
INNER JOIN `physionet-data.mimiciii_clinical.admissions` HADM
  ON PC.subject_id = HADM.subject_id
INNER JOIN `physionet-data.mimiciii_clinical.icustays` ICU
  ON PC.subject_id = ICU.subject_id
  AND HADM.HADM_ID = ICU.HADM_ID
INNER JOIN `physionet-data.mimiciii_clinical.chartevents` C
  ON C.subject_id = PC.subject_id 
    AND C.HADM_id = HADM.HADM_id 
    AND C.icustay_id = ICU.icustay_id 
    AND PC.icustay_id = ICU.icustay_id
INNER JOIN `nus-datathon-2018-team-01.oxygenation.icd_codes` ICD 
  ON ICD.subject_id = PC.subject_id 
  AND ICU.icustay_id = ICD.icustay_id
WHERE C.ITEMID in (220277, 646) 
AND C.valuenum IS NOT NULL; 
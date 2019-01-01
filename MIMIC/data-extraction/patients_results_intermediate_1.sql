SELECT DISTINCT 

                HADM.HADM_id,                 
                PC.subject_id as patient_ID,
                P.gender as gender,
                PC.age as age,  
              PC.icu_length_of_stay,
  CASE 
  WHEN HADM.deathtime BETWEEN HADM.admittime and HADM.dischtime
            THEN 1
  ELSE 0
  END AS mortality_in_Hospt, 
    CASE 
  WHEN HADM.deathtime BETWEEN icu.intime and icu.outtime
            THEN 1
  ELSE 0
  END AS mortality_in_ICU,
  HADM.deathtime as deathtime, 
  ICU.intime as ICU_intime, 
                ICD.*
  
FROM `oxygenators-209612.mimiciii_clinical.patient_cohort` PC
INNER JOIN `oxygenators-209612.mimiciii_clinical.patients` P 
  ON P.subject_id = PC.subject_id
INNER JOIN `oxygenators-209612.mimiciii_clinical.admissions` HADM
  ON PC.subject_id = HADM.subject_id
INNER JOIN `oxygenators-209612.mimiciii_clinical.icustays` ICU
  ON PC.subject_id = ICU.subject_id
  AND HADM.HADM_ID = ICU.HADM_ID
INNER JOIN `oxygenators-209612.mimiciii_clinical.chartevents` C
  ON C.subject_id = PC.subject_id 
    AND C.HADM_id = HADM.HADM_id 
    AND C.icustay_id = ICU.icustay_id 
    AND PC.icustay_id = ICU.icustay_id
INNER JOIN `oxygenators-209612.mimiciii_clinical.icd_codes` ICD 
  ON ICD.subject_id = PC.subject_id 
  AND ICU.icustay_id = ICD.icustay_id
WHERE C.ITEMID in (220277, 646) 
AND C.valuenum IS NOT NULL; 

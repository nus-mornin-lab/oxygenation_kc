SELECT PIR4.*, 
       SOFA.sofa
FROM `oxygenators-209612.mimiciii_clinical.patients_Results_Intermediate_4` PIR4
LEFT OUTER JOIN `oxygenators-209612.mimiciii_clinical.sofa` SOFA 
ON PIR4.patient_id = SOFA.subject_id 
AND PIR4.icustay_id = SOFA.icustay_id ; 

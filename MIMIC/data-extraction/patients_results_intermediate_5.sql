SELECT PIR4.*, 
       SOFA.sofa
FROM `nus-datathon-2018-team-01.oxygenation1.patients_Results_Intermediate_4` PIR4
LEFT OUTER JOIN `physionet-data.mimiciii_clinical.sofa` SOFA 
ON PIR4.patient_id = SOFA.subject_id 
AND PIR4.icustay_id = SOFA.icustay_id) ; 
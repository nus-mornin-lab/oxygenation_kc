SELECT
      PIR2.*,  
      CASE 
      (SELECT count(mechvent)
       FROM `physionet-data.mimiciii_clinical.ventsettings` VS
       WHERE mechvent = 1 
       AND VS.icustay_id = PIR2.icustay_id)  
       WHEN 0 THEN 0 
       ELSE 1 
       END AS invasive
FROM `nus-datathon-2018-team-01.oxygenation1.patients_Results_Intermediate_2` PIR2 
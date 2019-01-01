SELECT
      PIR2.*,  
      CASE 
      (SELECT count(mechvent)
       FROM `oxygenators-209612.mimiciii_clinical.ventsettings` VS
       WHERE mechvent = 1 
       AND VS.icustay_id = PIR2.icustay_id)  
       WHEN 0 THEN 0 
       ELSE 1 
       END AS invasive
FROM `oxygenators-209612.mimiciii_clinical.patients_Results_Intermediate_2` PIR2 

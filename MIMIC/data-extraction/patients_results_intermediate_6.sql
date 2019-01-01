SELECT PIR5.*, 
       MVV.tidal_high_count2 as tidal_count_percentage
FROM `oxygenators-209612.mimiciii_clinical.patients_Results_Intermediate_5` PIR5
LEFT OUTER JOIN `oxygenators-209612.mimiciii_clinical.mechanical_ventilative_volume` MVV 
ON PIR5.icustay_id = MVV.icustay_id;

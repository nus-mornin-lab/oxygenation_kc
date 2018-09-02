SELECT PIR5.*, 
       MVV.tidal_high_count2 as tidal_count_percentage
FROM `nus-datathon-2018-team-01.oxygenation1.patients_Results_Intermediate_5` PIR5
LEFT OUTER JOIN `nus-datathon-2018-team-01.oxygenation1.mechanical_ventilative_volume` MVV 
ON PIR5.icustay_id = MVV.icustay_id);
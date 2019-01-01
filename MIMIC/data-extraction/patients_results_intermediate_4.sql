SELECT PIR3.*, 
       FB.fluid_balance 
FROM `oxygenators-209612.mimiciii_clinical.patients_Results_Intermediate_3` PIR3 
LEFT OUTER JOIN `oxygenators-209612.mimiciii_clinical.fluid_balance` FB 
  ON PIR3.icustay_id = FB.icustay_id

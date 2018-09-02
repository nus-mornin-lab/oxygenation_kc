SELECT PIR3.*, 
       FB.fluid_balance 
FROM `nus-datathon-2018-team-01.oxygenation1.patients_Results_Intermediate_3` PIR3 
LEFT OUTER JOIN `nus-datathon-2018-team-01.oxygenation1.fluid_balance` FB 
  ON PIR3.icustay_id = FB.icustay_id
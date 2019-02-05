bq rm -f -t oxygenators-209612:mimiciii_clinical.patient_cohort
bq rm -f -t oxygenators-209612:mimiciii_clinical.icd_codes
bq rm -f -t oxygenators-209612:mimiciii_clinical.fluid_balance
bq rm -f -t oxygenators-209612:mimiciii_clinical.mechanical_ventilative_volume
bq rm -f -t oxygenators-209612:mimiciii_clinical.patients_Results_Intermediate_1
bq rm -f -t oxygenators-209612:mimiciii_clinical.patients_Results_Intermediate_2
bq rm -f -t oxygenators-209612:mimiciii_clinical.patients_Results_Intermediate_3
bq rm -f -t oxygenators-209612:mimiciii_clinical.patients_Results_Intermediate_4
bq rm -f -t oxygenators-209612:mimiciii_clinical.patients_Results_Intermediate_5
bq rm -f -t oxygenators-209612:mimiciii_clinical.patients_Results_Intermediate_6
bq rm -f -t oxygenators-209612:mimiciii_clinical.final_patients_results
bq rm -f -t oxygenators-209612:mimiciii_clinical.measurements_results
bq rm -f -t oxygenators-209612:mimiciii_clinical.mimic_final_patient_results

bq mk --use_legacy_sql=false --view "$(cat patient_cohort.sql)" oxygenators-209612:mimiciii_clinical.patient_cohort
bq mk --use_legacy_sql=false --view "$(cat icd_codes.sql)" oxygenators-209612:mimiciii_clinical.icd_codes
bq mk --use_legacy_sql=false --view "$(cat patients_results_intermediate_1.sql)" oxygenators-209612:mimiciii_clinical.patients_Results_Intermediate_1
bq mk --use_legacy_sql=false --view "$(cat patients_results_intermediate_2.sql)" oxygenators-209612:mimiciii_clinical.patients_Results_Intermediate_2
bq mk --use_legacy_sql=false --view "$(cat patients_results_intermediate_3.sql)" oxygenators-209612:mimiciii_clinical.patients_Results_Intermediate_3
bq mk --use_legacy_sql=false --view "$(cat fluid_balance.sql)" oxygenators-209612:mimiciii_clinical.fluid_balance
bq mk --use_legacy_sql=false --view "$(cat patients_results_intermediate_4.sql)" oxygenators-209612:mimiciii_clinical.patients_Results_Intermediate_4
bq mk --use_legacy_sql=false --view "$(cat patients_results_intermediate_5.sql)" oxygenators-209612:mimiciii_clinical.patients_Results_Intermediate_5
bq mk --use_legacy_sql=false --view "$(cat mechanical_ventilative_volume.sql)" oxygenators-209612:mimiciii_clinical.mechanical_ventilative_volume
bq mk --use_legacy_sql=false --view "$(cat patients_results_intermediate_6.sql)" oxygenators-209612:mimiciii_clinical.patients_Results_Intermediate_6
bq mk --use_legacy_sql=false --view "$(cat mimic_final_patient_results.sql)" oxygenators-209612:mimiciii_clinical.mimic_final_patient_results
bq mk --use_legacy_sql=false --view "$(cat measurements_results.sql)" oxygenators-209612:mimiciii_clinical.measurements_results
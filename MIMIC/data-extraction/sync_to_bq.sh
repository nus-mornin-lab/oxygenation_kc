bq rm -f -t oxygenators-209612:mimiciii_clinical.icd_codes
bq rm -f -t oxygenators-209612:mimiciii_clinical.fluid_balance
bq rm -f -t oxygenators-209612:mimiciii_clinical.mechanical_ventilative_volume
bq rm -f -t oxygenators-209612:mimiciii_clinical.measurements_results
bq rm -f -t oxygenators-209612:mimiciii_clinical.mimic_final_patient_results
bq rm -f -t oxygenators-209612:mimiciii_clinical.mimic_oxygen_therapy

bq mk --use_legacy_sql=false --view "$(cat icd_codes.sql)" oxygenators-209612:mimiciii_clinical.icd_codes
bq mk --use_legacy_sql=false --view "$(cat fluid_balance.sql)" oxygenators-209612:mimiciii_clinical.fluid_balance
bq mk --use_legacy_sql=false --view "$(cat mechanical_ventilative_volume.sql)" oxygenators-209612:mimiciii_clinical.mechanical_ventilative_volume
bq mk --use_legacy_sql=false --view "$(cat mimic_final_patient_results.sql)" oxygenators-209612:mimiciii_clinical.mimic_final_patient_results
bq mk --use_legacy_sql=false --view "$(cat mimic_oxygen_therapy.sql)" oxygenators-209612:mimiciii_clinical.mimic_oxygen_therapy
bq mk --use_legacy_sql=false --view "$(cat measurements_results.sql)" oxygenators-209612:mimiciii_clinical.measurements_results
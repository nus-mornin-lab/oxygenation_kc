bq rm -f -t oxygenators-209612:eicu.final_measurement_results
bq rm -f -t oxygenators-209612:eicu.final_patient_results
bq rm -f -t oxygenators-209612:eicu.oxygen_therapy
bq rm -f -t oxygenators-209612:eicu.oxygen_therapy_treatment

bq mk --use_legacy_sql=false --view "$(cat eicu_final_measurement_results.sql)" oxygenators-209612:eicu.final_measurement_results
bq mk --use_legacy_sql=false --view "$(cat eicu_final_patient_results.sql)" oxygenators-209612:eicu.final_patient_results
bq mk --use_legacy_sql=false --view "$(cat eicu_oxygen_therapy.sql)" oxygenators-209612:eicu.oxygen_therapy
bq mk --use_legacy_sql=false --view "$(cat eicu_oxygen_therapy_treatment.sql)" oxygenators-209612:eicu.oxygen_therapy_treatment

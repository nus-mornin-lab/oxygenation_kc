bq rm -f -t oxygenators-209612:eicu.final_measurement_results
bq rm -f -t oxygenators-209612:eicu.final_patient_results

bq mk --use_legacy_sql=false --view "$(cat eicu_final_measurement_results.sql)" oxygenators-209612:eicu.final_measurement_results
bq mk --use_legacy_sql=false --view "$(cat eicu_final_patient_results.sql)" oxygenators-209612:eicu.final_patient_results

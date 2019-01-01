WITH icus AS (
SELECT icustay_id, first_careunit as first_care_unit
FROM `oxygenators-209612.mimiciii_clinical.icustays`
order by first_careunit desc
limit 1
)
select or6.*, icus.first_care_unit from `oxygenators-209612.mimiciii_clinical.patients_Results_Intermediate_6` AS or6
left join icus on or6.icustay_id = icus.icustay_id
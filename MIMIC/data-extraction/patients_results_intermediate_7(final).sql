SELECT DISTINCT OR6.patient_id
      , max(icus.first_careunit) as first_care_unit
 from `nus-datathon-2018-team-01.oxygenation1.patients_Results_Intermediate_6` as or6
      left outer join `physionet-data.mimiciii_clinical.icustays`  as icus
      on icus.icustay_id = or6.icustay_id
where icus.first_careunit is not null
group by OR6.patient_id)
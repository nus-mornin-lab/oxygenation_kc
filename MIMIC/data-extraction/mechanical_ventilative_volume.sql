run_query('''-- choose ventilation records recorded in first 3 days
-- and if the endtime exceeds ICU intime + 24 hours, change the endtime to 'intime + 24 hours'
WITH vent_cohort AS (
 SELECT vd.icustay_id
    , icud.intime
    , vd.starttime
    , CASE WHEN vd.endtime > DATETIME_ADD(icud.intime, INTERVAL 24 HOUR)
         THEN DATETIME_ADD(icud.intime, INTERVAL 24 HOUR)
         ELSE vd.endtime
     END AS endtime
 FROM `physionet-data.mimiciii_clinical.icustay_detail` icud
    LEFT JOIN `physionet-data.mimiciii_clinical.ventdurations` vd
    ON vd.icustay_id = icud.icustay_id
 WHERE vd.starttime BETWEEN icud.intime AND DATETIME_ADD(icud.intime, INTERVAL 1 day)
)
, weight AS (
SELECT icustay_id
    , AVG(weight) AS weight
 FROM `physionet-data.mimiciii_clinical.weightdurations`
 GROUP BY icustay_id
)
 , tidal AS (
SELECT ce.icustay_id
    , safe_CAST(ce.value as FLOAT64) /wt.weight AS tidal_volume_per_weight
    --, ce.valueuom
    --, echo.weight
 FROM `physionet-data.mimiciii_clinical.chartevents` ce
 LEFT JOIN weight wt
    ON wt.icustay_id = ce.icustay_id
 LEFT JOIN vent_cohort vc
    ON ce.icustay_id = vc.icustay_id
 WHERE ce.itemid IN (681, 682, 224685) -- these itemid are for tidal volume
    AND wt.weight IS NOT NULL -- some guys didn't have these records, just remove them
    AND ce.charttime BETWEEN vc.starttime AND vc.endtime -- only select tidal volume recorded during invasive ventilation
)
, tidal_total AS (
 SELECT tidal.*
     , CASE WHEN tidal.tidal_volume_per_weight >= 6.5 THEN 1 ELSE 0 END AS tidal_label
     , tidal_total.total_count
    FROM tidal
       LEFT JOIN (
        SELECT icustay_id
            , count(icustay_id) AS total_count
         FROM tidal
         GROUP BY icustay_id
      ) tidal_total
       ON tidal_total.icustay_id = tidal.icustay_id
)
 , tidal_risk AS (
 SELECT tt.icustay_id
    , tt.total_count
    , sum(tt.tidal_label) AS tidal_high_count
  FROM tidal_total tt
  GROUP BY tt.icustay_id, tt.total_count
)
SELECT icustay_id
   , tidal_high_count
   , total_count
    , tidal_high_count/total_count AS tidal_high_count2
 FROM tidal_risk
 ORDER BY tidal_high_count DESC'''
set SEARCH_PATH TO mimiciii;

-- choose ventilation records recorded in first 3 days
-- and if the endtime exceeds ICU intime + 24 hours, change the endtime to 'intime + 24 hours'
WITH vent_cohort AS (
  SELECT vd.icustay_id
        , icud.intime
        , vd.starttime
        , CASE WHEN vd.endtime > icud.intime + INTERVAL '24' HOUR
                 THEN (icud.intime + INTERVAL '24' HOUR)
                 ELSE vd.endtime
          END
  FROM icustay_detail icud
       LEFT JOIN ventdurations vd
       ON vd.icustay_id = icud.icustay_id
       AND vd.starttime BETWEEN icud.intime AND icud.intime + INTERVAL '1' day
)

  , tidal AS (
SELECT ce.icustay_id
       , (ce.value::NUMERIC)/(echo.weight::NUMERIC) AS tidal_volume_per_weight
       --, ce.valueuom
       --, echo.weight
  FROM chartevents ce
  LEFT JOIN echo_categorized echo
       ON echo.hadm_id::text = ce.hadm_id::text
  LEFT JOIN vent_cohort vc
       ON ce.icustay_id = vc.icustay_id
 WHERE ce.itemid = ANY (ARRAY[681, 682, 224685]) -- these itemid are for tidal volume
       AND echo.weight IS NOT NULL -- some guys didn't have these records, just remove them
       AND echo.weight !~~ 'None' -- text in 'weight'
       AND ce.charttime BETWEEN vc.starttime AND vc.endtime  -- only select tidal volume recorded during invasive ventilation
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
       , tidal_high_count::NUMERIC /total_count AS tidal_high_count2
  FROM tidal_risk
  ORDER BY tidal_high_count DESC

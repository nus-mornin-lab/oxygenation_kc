-- The table constructs start and end time of oxygen therapy sessions,
-- along with an indicator whether supplemental oxygen, noninvasive ventilation, or invasive ventilation was involved.

-- Whenever a gap of 24 hours occurs between oxygen therapy or ventilation therapy records,
-- then we consider that a new oxygen therapy session has started.

-- This script uses oxygen therapy indicators from https://github.com/MIT-LCP/mimic-code/blob/master/concepts/durations/ventilation-durations.sql



-- First, create a temporary table to store relevant data from CHARTEVENTS.
WITH ventsettings AS (
select
  icustay_id, charttime
  -- case statement determining what type of oxygen therapy it is.
	-- type indicates whether the entry suggests invasive ventilation (4), noninvasive ventilation (3), either invasive or noninvasive ventilation (2), supplemental oxygen (1). If the entry does not suggest a type of oxygen therapy, type = 0.
  , max(
    case
      when itemid = 720 and value != 'Other/Remarks' THEN 2  -- VentTypeRecorded
      when itemid = 223848 and value != 'Other' THEN 2
      when itemid = 223849 then 2 -- ventilator mode
      when itemid = 467 and value = 'Ventilator' THEN 2 -- O2 delivery device == ventilator
      when itemid in (
		445, 448, 449, 450, 1340, 1486, 1600, 224687 -- minute volume
		, 639, 654, 681, 682, 683, 684,224685,224684,224686 -- tidal volume
        , 218,436,535,444,459,224697,224695,224696,224746,224747 -- High/Low/Peak/Mean/Neg insp force ("RespPressure")
        , 221,1,1211,1655,2000,226873,224738,224419,224750,227187 -- Insp pressure
	)
	THEN 2
	when itemid in (
	501,502,503,224702 -- PCV
	, 223,667,668,669,670,671,672 -- TCPCV
	, 224701 -- PSVlevel
	)
	THEN 3
      when itemid in
        (
 	543 -- PlateauPressure
        , 5865,5866,224707,224709,224705,224706 -- APRV pressure
        , 60,437,505,506,686,220339,224700 -- PEEP
        , 3459 -- high pressure relief
        )
        THEN 4
	-- The following are indicators of supplemental oxygen
	when itemid = 226732 and value in
        (
          'Nasal cannula', -- 153714 observations
          'Face tent', -- 24601 observations
          'Aerosol-cool', -- 24560 observations
          'Trach mask ', -- 16435 observations
          'High flow neb', -- 10785 observations
          'Non-rebreather', -- 5182 observations
          'Venti mask ', -- 1947 observations
          'Medium conc mask ', -- 1888 observations
          'T-piece', -- 1135 observations
          'High flow nasal cannula', -- 925 observations
          'Ultrasonic neb', -- 9 observations
          'Vapomist' -- 3 observations
        ) then 1
        when itemid = 467 and value in
        (
          'Cannula', -- 278252 observations
          'Nasal Cannula', -- 248299 observations
          -- 'None', -- 95498 observations
          'Face Tent', -- 35766 observations
          'Aerosol-Cool', -- 33919 observations
          'Trach Mask', -- 32655 observations
          'Hi Flow Neb', -- 14070 observations
          'Non-Rebreather', -- 10856 observations
          'Venti Mask', -- 4279 observations
          'Medium Conc Mask', -- 2114 observations
          'Vapotherm', -- 1655 observations
          'T-Piece', -- 779 observations
          'Hood', -- 670 observations
          'Hut', -- 150 observations
          'TranstrachealCat', -- 78 observations
          'Heated Neb', -- 37 observations
          'Ultrasonic Neb' -- 2 observations
        ) then 1
	-- Use of tube indicate invasive ventilation
	when itemid = 640 and value = 'Extubated' then 4
        when itemid = 640 and value = 'Self Extubation' then 4
      else 0
    end
    ) as type
    , max(
      case when itemid is null or value is null then 0
        -- extubated indicates ventilation event has ended
        when itemid = 640 and value = 'Extubated' then 1
        when itemid = 640 and value = 'Self Extubation' then 1
      else 0
      end
      )
      as Extubated
from `oxygenators-209612.mimiciii_clinical.chartevents` ce
where ce.value is not null and icustay_id IS NOT NULL
-- exclude rows marked as error
and (ce.error <> 1 OR ce.error IS NULL)--ce.error IS DISTINCT FROM 1
and ( itemid in
(
    -- the below are settings used to indicate ventilation
      720, 223849 -- vent mode
    , 223848 -- vent type
    , 445, 448, 449, 450, 1340, 1486, 1600, 224687 -- minute volume
    , 639, 654, 681, 682, 683, 684,224685,224684,224686 -- tidal volume
    , 218,436,535,444,224697,224695,224696,224746,224747 -- High/Low/Peak/Mean ("RespPressure")
    , 221,1,1211,1655,2000,226873,224738,224419,224750,227187 -- Insp pressure
    , 543 -- PlateauPressure
    , 5865,5866,224707,224709,224705,224706 -- APRV pressure
    , 60,437,505,506,686,220339,224700 -- PEEP
    , 3459 -- high pressure relief
    , 501,502,503,224702 -- PCV
    , 223,667,668,669,670,671,672 -- TCPCV
    , 224701 -- PSVlevel

    -- the below are settings used to indicate extubation
    , 640 -- extubated

    -- the below indicate oxygen/NIV, i.e. the end of a mechanical vent event
    , 468 -- O2 Delivery Device#2
    , 469 -- O2 Delivery Mode
    , 470 -- O2 Flow (lpm)
    , 471 -- O2 Flow (lpm) #2
    , 227287 -- O2 Flow (additional cannula)
    , 226732 -- O2 Delivery Device(s)
    , 223834 -- O2 Flow

    -- used in both oxygen + vent calculation
    , 467 -- O2 Delivery Device
) ) OR ( -- Fraction of inspired oxygen different from 21% indicates oxygen therapy
	itemid in (3420, 190, 223835, 3422) AND (
		-- valuenum is different from 21
		valuenum > 22
		OR valuenum < 20
	) AND (
		-- valuenum is different from .21
		valuenum > .22
		OR valuenum < .2
	)
)
group by icustay_id, charttime
UNION DISTINCT
-- add in the extubation flags from procedureevents_mv
-- note that we only need the start time for the extubation
-- (extubation is always charted as ending 1 minute after it started)
select
  icustay_id, starttime as charttime
  , 4 as type
  , 1 as Extubated
from `oxygenators-209612.mimiciii_clinical.procedureevents_mv`
where itemid in
(
  227194 -- "Extubation"
, 225468 -- "Unplanned Extubation (patient-initiated)"
, 225477 -- "Unplanned Extubation (non-patient initiated)"
)
),

vd0 as
(
  select
    *
    -- this carries over the previous charttime which had an oxygen therapy event
    , LAG(CHARTTIME, 1) OVER (partition by icustay_id order by charttime)
	as charttime_lag
  from ventsettings
)
, vd1 as
(
  select
      icustay_id
      , charttime
      , type
      , Extubated

      -- If the time since the last oxygen therapy event is more than 24 hours,
	-- we consider that ventilation had ended in between.
	-- That is, the next ventilation record corresponds to a new ventilation session.
      , CASE
		WHEN DATETIME_DIFF(CHARTTIME, charttime_lag, HOUR) > 24 THEN 1
		WHEN charttime_lag IS NULL THEN 1 -- No lag can be computed for the very first record
		ELSE 0
	END AS newvent
  -- use the staging table with only oxygen therapy records from chart events
  FROM vd0
)
, vd2 as
(
  select vd1.*
  -- create a cumulative sum of the instances of new ventilation
  -- this results in a monotonic integer assigned to each instance of ventilation
  , SUM( newvent )
      OVER ( partition by icustay_id order by charttime )
    as ventnum
  from vd1
)

--- now we convert CHARTTIME of ventilator settings into durations
-- create the durations for each oxygen therapy instance
-- We only keep the first oxygen therapy instance
, vd3 AS
(
select icustay_id
  , ventnum
  , max(charttime) as vent_end
  , min(charttime) as vent_start
  , max(type) as type
from vd2
group by icustay_id, ventnum
)

-- If the last record was not extubation, add an hour to vent_duration as the oxygen therapy probably continued for longer
, vd4 AS
(
select icustay_id, type AS oxygen_therapy_type
  , ventnum
  , vent_start
  , CASE
	WHEN last_extubation = vent_end THEN vent_end -- Last record was extubation
	ELSE DATETIME_ADD(vent_end, INTERVAL 1 HOUR)
  END as vent_end
from vd3 LEFT JOIN (
SELECT
icustay_id AS extub_id,
max(charttime) as last_extubation
FROM vd2
WHERE Extubated = 1
GROUP BY icustay_id, ventnum
)
ON vd3.icustay_id = extub_id
)

select vd4.*
  -- We use `MINUTE` here as `HOUR` would result in the difference of 1.59pm and 2.01pm to be recorded as 1 hour.
	, DATETIME_DIFF(vent_end, vent_start, MINUTE)/60 AS vent_duration
  , MIN(vent_start) OVER(PARTITION BY icustay_id) AS vent_start_first
from vd4
WITH respchart AS (
	SELECT *
	FROM `oxygenators-209612.eicu.respiratorycharting`
)

, nursechart AS (
	SELECT *
	FROM `oxygenators-209612.eicu.nursecharting`
)

, pat AS (
	SELECT *
	FROM `oxygenators-209612.eicu.patient`
)


-- Extract the type of oxygen therapy.
-- The categories are invasive ventilation,
-- noninvasive ventilation, and supplemental oxygen.
, ventsettings0 AS (
	SELECT patientunitstayid AS icustay_id
		, charttime
		, MAX(CASE

			-- Invasive ventilation
			WHEN
				string IN (
					'plateau pressure',
					'postion at lip',
					'position at lip',
					'pressure control'
				)
				OR string LIKE '%set vt%'
				OR string LIKE '%sputum%'
				OR string LIKE '%rsbi%'
				OR string LIKE '%tube%'
				OR string LIKE '%ett%'
				OR string LIKE '%endotracheal%'
				OR string LIKE '%tracheal suctioning%'
				OR string LIKE '%tracheostomy%'
				OR string LIKE '%reintubation%'
				OR string LIKE '%assist controlled%'
				OR string LIKE '%volume controlled%'
				OR string LIKE '%pressure controlled%'
				OR string LIKE '%trach collar%'
			THEN 4

			-- Noninvasive ventilation
			WHEN
				string IN (
					'bi-pap',
					'ambubag'
				)
				OR string LIKE '%ipap%'
				OR string LIKE '%niv%'
				OR string LIKE '%epap%'
				OR string LIKE '%mask leak%'
				OR string LIKE '%volume assured%'
				OR string LIKE '%non-invasive ventilation%'
				OR string LIKE '%cpap%'
			THEN 3

			-- Either invasive or noninvasive ventilation:
			WHEN
				string IN (
					'flowtrigger',
					'peep',
					'tv/kg ibw',
					'mean airway pressure',
					'peak insp. pressure',
					'exhaled mv',
					'exhaled tv (machine)',
					'exhaled tv (patient)',
					'flow sensitivity',
					'peak flow',
					'f total',
					'pressure to trigger ps',
					'adult con setting set rr',
					'adult con setting set vt',
					'vti',
					'exhaled vt',
					'adult con alarms hi press alarm',
					'mve',
					'respiratory phase',
					'inspiratory pressure, set',
					'a1: high exhaled vt',
					'set fraction of inspired oxygen (fio2)',
					'insp flow (l/min)',
					'adult con setting spont exp vt',
					'spont tv',
					'pulse ox results vt',
					'vt spontaneous (ml)',
					'peak pressure',
					'ltv1200',
					'tc'
				)
				OR (
					string LIKE '%vent%'
					AND NOT string LIKE '%hyperventilat%'
				)
				OR string LIKE '%tidal%'
				OR string LIKE '%flow rate%'
				OR string LIKE '%minute volume%'
				OR string LIKE '%leak%'
				OR string LIKE '%pressure support%'
				OR string LIKE '%peep%'
				OR string LIKE '%tidal volume%'
			THEN 2

			-- Supplemental oxygen:
			WHEN
				string IN (
					't-piece',
					'blow-by',
					'oxyhood',
					'nc',
					'oxymizer',
					'hfnc',
					'oximizer',
					'high flow',
					'oxymask',
					'nch',
					'hi flow',
					'hiflow',
					'hhfnc',
					'nasal canula',
					'face tent',
					'high flow mask',
					'aerosol mask',
					'venturi mask',
					'cool aerosol mask',
					'simple mask',
					'face mask'
				)
				OR string LIKE '%nasal cannula%'
				OR string LIKE '%non-rebreather%'
				OR string LIKE '%nasal mask%'
				OR string LIKE '%face tent%'
			THEN 1

			-- Oxygen therapy but unknown what type:
			WHEN
				string IN (
					'pressure support',
					'rr spont',
					'ps',
					'insp cycle off (%)',
					'lpm o2',
					'trach mask/collar'
				)
				OR string LIKE '%spontaneous%'
				OR string LIKE '%oxygen therapy%'
			THEN 0

			ELSE NULL

		END) AS oxygen_therapy_type
		, MAX(activeUponDischarge) AS activeUponDischarge
	FROM (

		SELECT patientunitstayid
			, nursingChartOffset AS charttime
			, LOWER(nursingchartvalue) AS string
			, NULL AS activeUponDischarge
		FROM nursechart

		UNION ALL

		SELECT patientunitstayid
			, respchartoffset AS charttime
			, LOWER(respchartvaluelabel) AS string
			, NULL AS activeUponDischarge
		FROM respchart

		UNION ALL

		-- Oxygen device from respchart
		SELECT patientunitstayid
			, respchartoffset AS charttime
			, LOWER(respchartvalue) AS string
			, NULL AS activeUponDischarge
		FROM respchart
		WHERE LOWER(respchartvaluelabel) IN (
			'o2 device',
			'respiratory device',
			'ventilator type',
			'oxygen delivery method'
    	)

    	UNION ALL

    	-- The treatment table also contains info on oxygen therapy.
    	SELECT patientunitstayid
			, treatmentoffset AS charttime
			, LOWER(treatmentstring) AS string
			, activeUponDischarge
		FROM `oxygenators-209612.eicu.treatment`
	)
	WHERE charttime >= -60
	GROUP BY icustay_id, charttime

	UNION ALL

	-- The following indicates oxygen therapy but unclear what type.
	SELECT patientunitstayid AS icustay_id
		, nursingchartoffset AS charttime
		, 0 AS oxygen_therapy_type
		, NULL AS activeUponDischarge
	FROM nursechart
	WHERE nursingchartoffset >= -60
		AND nursingchartcelltypevallabel = 'O2 L/%'
		AND SAFE_CAST(nursingChartValue AS INT64) > 0
		AND SAFE_CAST(nursingChartValue AS INT64) <= 100

	UNION ALL

	-- fraction of inspired oxygen (fiO2) outside of [.2, .22] and [20, 22]
	-- indicates oxygen therapy.
	SELECT patientunitstayid AS icustay_id
		, respchartoffset AS charttime
		, 0 AS oxygen_therapy_type
		, NULL AS activeUponDischarge
	FROM respchart
	WHERE respchartoffset >= -60
		AND LOWER(respchartvaluelabel) IN ('fio2', 'fio2 (%)')
		AND (
			SAFE_CAST(respchartvalue as FLOAT64) < .2
			OR (
				SAFE_CAST(respchartvalue as FLOAT64) > .22
				AND SAFE_CAST(respchartvalue as FLOAT64) < 20
			)
			OR SAFE_CAST(respchartvalue as FLOAT64) > 22
		)
)


-- Ensure charttime is unique
, ventsettings AS (
	SELECT icustay_id
		, charttime
		, MAX(oxygen_therapy_type) AS oxygen_therapy_type
		, MAX(activeUponDischarge) AS activeUponDischarge
	FROM ventsettings0
	-- If oxygen_therapy_type is NULL,
	-- then the record does not correspond with oxygen therapy.
	WHERE oxygen_therapy_type IS NOT NULL
	GROUP BY icustay_id, charttime
)


, vd0 as
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
      , oxygen_therapy_type
      , activeUponDischarge

      -- If the time since the last oxygen therapy event is more than 24 hours,
	-- we consider that ventilation had ended in between.
	-- That is, the next ventilation record corresponds to a new ventilation session.
      , CASE
		WHEN charttime - charttime_lag > 24*60 THEN 1
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
	SELECT icustay_id
		, ventnum
		, CASE
			-- If activeUponDischarge, then the unit discharge time is vent_end
			WHEN (
				MAX(activeUponDischarge)
				-- vent_end cannot be later than the unit discharge time.
				-- However, unitdischargeoffset often seems too low.
				-- So, we only use it if it yields and extension of the
				-- ventilation time from ventsettings.
				AND MAX(charttime)+60 < MAX(pat.unitdischargeoffset)
			)
			THEN MAX(pat.unitdischargeoffset)
			-- End time is currently a charting time
			-- Since these are usually recorded hourly, ventilation is actually longer.
			-- We therefore add 60 minutes to the last time.
			ELSE MAX(charttime)+60
		END AS vent_end
		, MIN(charttime) AS vent_start
		, MAX(oxygen_therapy_type) AS oxygen_therapy_type
	FROM vd2
		LEFT JOIN pat
		ON vd2.icustay_id = pat.patientunitstayid
	GROUP BY icustay_id, ventnum
)


select vd3.*
	-- vent_duration is in hours.
	, (vent_end - vent_start) / 60 AS vent_duration
	, MIN(vent_start) OVER(PARTITION BY icustay_id) AS vent_start_first
from vd3
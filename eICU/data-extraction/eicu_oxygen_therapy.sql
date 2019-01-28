WITH nursechart AS (
SELECT patientunitstayid as icustay_id,
		nursingChartOffset as time,
      max(CASE
    
WHEN -- Invasive ventilation
nursingchartcelltypevallabel = 'O2 Admin Device' AND (
LOWER(nursingchartvalue) IN (
'ett',
'trach collar'
)
)
THEN 4

WHEN -- Noninvasive ventilation
nursingchartcelltypevallabel = 'O2 Admin Device' AND (
LOWER(nursingchartvalue) IN (
'bi-pap',
'cpap',
'ambubag',
'niv'
)
OR LOWER(nursingchartvalue) LIKE '%bipap%'
)
THEN 3

WHEN -- Either invasive or noninvasive ventilation:
nursingchartcelltypevallabel = 'O2 Admin Device' AND (
LOWER(nursingchartvalue) IN (
'ventilator',
'ltv1200',
'vent',
'vented',
'tc'
)
)
THEN 2

WHEN -- Supplemental oxygen:
nursingchartcelltypevallabel = 'O2 Admin Device' AND (
LOWER(nursingchartvalue) IN (
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
OR LOWER(nursingchartvalue) LIKE '%nasal cannula%'
OR LOWER(nursingchartvalue) LIKE '%non-rebreather%'
)
THEN 1

WHEN -- Oxygen therapy but unknown what type:
nursingchartcelltypevallabel = 'O2 Admin Device' AND (
LOWER(nursingchartvalue) IN (
'trach mask/collar'
)
OR ( nursingchartcelltypevallabel = 'O2 L/%'
    AND SAFE_CAST(nursingChartValue AS INT64) > 0
    AND SAFE_CAST(nursingChartValue AS INT64) <= 100
    )
)
THEN 0

ELSE NULL
  END) AS type
   FROM `oxygenators-209612.eicu.nursecharting`
  WHERE nursingChartOffset >= -60 AND
(
-- Invasive ventilation
nursingchartcelltypevallabel = 'O2 Admin Device' AND (
LOWER(nursingchartvalue) IN (
'ett',
'trach collar'
)
)

OR
-- Noninvasive ventilation
nursingchartcelltypevallabel = 'O2 Admin Device' AND (
LOWER(nursingchartvalue) IN (
'bi-pap',
'cpap',
'ambubag',
'niv'
)
OR LOWER(nursingchartvalue) LIKE '%bipap%'
)

OR
-- Either invasive or noninvasive ventilation:
nursingchartcelltypevallabel = 'O2 Admin Device' AND (
LOWER(nursingchartvalue) IN (
'ventilator',
'ltv1200',
'vent',
'vented',
'tc'
)
)

OR
-- Supplemental oxygen:
nursingchartcelltypevallabel = 'O2 Admin Device' AND (
LOWER(nursingchartvalue) IN (
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
OR LOWER(nursingchartvalue) LIKE '%nasal cannula%'
OR LOWER(nursingchartvalue) LIKE '%non-rebreather%'
)

OR
-- Oxygen therapy but unknown what type:
nursingchartcelltypevallabel = 'O2 Admin Device' AND (
LOWER(nursingchartvalue) IN (
'trach mask/collar'
)
OR ( nursingchartcelltypevallabel = 'O2 L/%'
    AND SAFE_CAST(nursingChartValue AS INT64) > 0
    AND SAFE_CAST(nursingChartValue AS INT64) <= 100
    )
)
)
GROUP BY patientunitstayid, nursingChartOffset
),




respchart_device AS (
SELECT patientunitstayid as icustay_id,
		respchartoffset as time,
      max(CASE
    
WHEN -- Invasive ventilation
LOWER(respchartvalue) IN (
'ett',
'trach collar'
)
THEN 4

WHEN -- Noninvasive ventilation
LOWER(respchartvalue) IN (
'bi-pap',
'cpap',
'ambubag',
'niv'
)
OR LOWER(respchartvalue) LIKE '%bipap%'
THEN 3

WHEN -- Either invasive or noninvasive ventilation:
LOWER(respchartvalue) IN (
'ventilator',
'ltv1200',
'vent',
'vented',
'tc'
)
THEN 2

WHEN -- Supplemental oxygen:
LOWER(respchartvalue) IN (
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
OR LOWER(respchartvalue) LIKE '%nasal cannula%'
OR LOWER(respchartvalue) LIKE '%non-rebreather%'
THEN 1

WHEN -- Oxygen therapy but unknown what type:
LOWER(respchartvalue) IN (
'trach mask/collar'
)
THEN 0

ELSE NULL
  END) AS type
   FROM `oxygenators-209612.eicu.respiratorycharting`
  WHERE respchartoffset >= -60 AND
-- respchartvalue indicates oxygen therapy type if the following holds:
LOWER(respchartvaluelabel) IN (
      'o2 device',
      'respiratory device',
      'ventilator type',
	'oxygen delivery method'
    )
AND
(
-- Invasive ventilation
LOWER(respchartvalue) IN (
'ett',
'trach collar'
)

OR
-- Noninvasive ventilation
LOWER(respchartvalue) IN (
'bi-pap',
'cpap',
'ambubag',
'niv'
)
OR LOWER(respchartvalue) LIKE '%bipap%'

OR
-- Either invasive or noninvasive ventilation:
LOWER(respchartvalue) IN (
'ventilator',
'ltv1200',
'vent',
'vented',
'tc'
)

OR
-- Supplemental oxygen:
LOWER(respchartvalue) IN (
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
OR LOWER(respchartvalue) LIKE '%nasal cannula%'
OR LOWER(respchartvalue) LIKE '%non-rebreather%'

OR
-- Oxygen therapy but unknown what type:
LOWER(respchartvalue) IN (
'trach mask/collar'
)
)
GROUP BY patientunitstayid, respchartoffset
),





respchart AS (
SELECT patientunitstayid as icustay_id,
					respchartoffset as time,
      max(CASE
    
WHEN -- Invasive ventilation
LOWER(respchartvaluelabel) IN (
'plateau pressure',
'endotracheal tube placement',
'secured at-ett',
'tube size',
'endotracheal position at lip',
'postion at lip',
'chest tube size',
'position at lip',
'trachestomy tube size',
'chest tube position',
'et tube repositioned',
'chest tube insertion status',
'ett sedation vacation',
'pressure control'
)
OR LOWER(respchartvaluelabel) LIKE '%set vt%'
OR LOWER(respchartvaluelabel) LIKE '%sputum%'
OR LOWER(respchartvaluelabel) LIKE '%rsbi%'
OR LOWER(respchartvaluelabel) LIKE '%tube%'
OR LOWER(respchartvaluelabel) LIKE '%ett%'
OR LOWER(respchartvaluelabel) LIKE '%endotracheal%'
THEN 4

WHEN -- Noninvasive ventilation
LOWER(respchartvaluelabel) IN (
'bipap delivery mode',
'non-invasive ventilation mode',
'cpap',
'peep/cpap'
)
OR LOWER(respchartvaluelabel) LIKE '%ipap%'
OR LOWER(respchartvaluelabel) LIKE '%niv%'
OR LOWER(respchartvaluelabel) LIKE '%epap%'
OR LOWER(respchartvaluelabel) LIKE '%mask leak%'
THEN 3

WHEN -- Either invasive or noninvasive ventilation:
LOWER(respchartvaluelabel) IN (
'flowtrigger',
'peep',
'tidal volume (set)',
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
'minute ventilation set(l/min)',
'a1: high exhaled vt',
'set fraction of inspired oxygen (fio2)',
'insp flow (l/min)',
'adult con setting spont exp vt',
'spont tv',
'pulse ox results vt',
'vt spontaneous (ml)',
'peak pressure'
)
OR LOWER(respchartvaluelabel) LIKE '%vent%'
OR LOWER(respchartvaluelabel) LIKE '%tidal%'
OR LOWER(respchartvaluelabel) LIKE '%flow rate%'
OR LOWER(respchartvaluelabel) LIKE '%minute volume%'
OR LOWER(respchartvaluelabel) LIKE '%leak%'
THEN 2

WHEN -- Oxygen therapy but unknown what type:
LOWER(respchartvaluelabel) IN (
  'pressure support',
'rr spont',
'ps',
'insp cycle off (%)',
'lpm o2'
)
OR LOWER(respchartvaluelabel) LIKE '%spontaneous%'
    OR ( -- fraction of inspired oxygen is outside of [.2, .22] and [20, 22]
      LOWER(respchartvaluelabel) IN ('fio2', 'fio2 (%)')
      AND (
          SAFE_CAST(respchartvalue as FLOAT64) < .2
          OR (SAFE_CAST(respchartvalue as FLOAT64) > .22 AND SAFE_CAST(respchartvalue as FLOAT64) < 20)
          OR SAFE_CAST(respchartvalue as FLOAT64) > 22
      )
    )
THEN 0

ELSE NULL
  END) AS type
   FROM `oxygenators-209612.eicu.respiratorycharting`
  WHERE respchartoffset >= -60 AND
(
-- Invasive ventilation
LOWER(respchartvaluelabel) IN (
'plateau pressure',
'endotracheal tube placement',
'secured at-ett',
'tube size',
'endotracheal position at lip',
'postion at lip',
'chest tube size',
'position at lip',
'trachestomy tube size',
'chest tube position',
'et tube repositioned',
'chest tube insertion status',
'ett sedation vacation',
'pressure control'
)
OR LOWER(respchartvaluelabel) LIKE '%set vt%'
OR LOWER(respchartvaluelabel) LIKE '%sputum%'
OR LOWER(respchartvaluelabel) LIKE '%rsbi%'
OR LOWER(respchartvaluelabel) LIKE '%tube%'
OR LOWER(respchartvaluelabel) LIKE '%ett%'
OR LOWER(respchartvaluelabel) LIKE '%endotracheal%'

OR
-- Noninvasive ventilation
LOWER(respchartvaluelabel) IN (
'bipap delivery mode',
'non-invasive ventilation mode',
'cpap',
'peep/cpap'
)
OR LOWER(respchartvaluelabel) LIKE '%ipap%'
OR LOWER(respchartvaluelabel) LIKE '%niv%'
OR LOWER(respchartvaluelabel) LIKE '%epap%'
OR LOWER(respchartvaluelabel) LIKE '%mask leak%'

OR
-- Either invasive or noninvasive ventilation:
LOWER(respchartvaluelabel) IN (
'flowtrigger',
'peep',
'tidal volume (set)',
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
'minute ventilation set(l/min)',
'a1: high exhaled vt',
'set fraction of inspired oxygen (fio2)',
'insp flow (l/min)',
'adult con setting spont exp vt',
'spont tv',
'pulse ox results vt',
'vt spontaneous (ml)',
'peak pressure'
)
OR LOWER(respchartvaluelabel) LIKE '%vent%'
OR LOWER(respchartvaluelabel) LIKE '%tidal%'
OR LOWER(respchartvaluelabel) LIKE '%flow rate%'
OR LOWER(respchartvaluelabel) LIKE '%minute volume%'
OR LOWER(respchartvaluelabel) LIKE '%leak%'

OR
-- Oxygen therapy but unknown what type:
LOWER(respchartvaluelabel) IN (
  'pressure support',
'rr spont',
'ps',
'insp cycle off (%)',
'lpm o2'
)
OR LOWER(respchartvaluelabel) LIKE '%spontaneous%'
    OR ( -- fraction of inspired oxygen is outside of [.2, .22] and [20, 22]
      LOWER(respchartvaluelabel) IN ('fio2', 'fio2 (%)')
      AND (
          SAFE_CAST(respchartvalue as FLOAT64) < .2
          OR (SAFE_CAST(respchartvalue as FLOAT64) > .22 AND SAFE_CAST(respchartvalue as FLOAT64) < 20)
          OR SAFE_CAST(respchartvalue as FLOAT64) > 22
      )
    )
)
GROUP BY patientunitstayid, respchartoffset
)



SELECT * FROM nursechart
UNION DISTINCT
SELECT * FROM respchart_device
UNION DISTINCT
SELECT * FROM respchart
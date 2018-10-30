SELECT patientunitstayid as icustay_id,
	treatmentoffset as time,
	activeUponDischarge,
      max(CASE
    
WHEN -- Invasive ventilation
LOWER(treatmentstring) LIKE '%tracheal suctioning%'
OR LOWER(treatmentstring) LIKE '%tube%'
OR LOWER(treatmentstring) LIKE '%tracheostomy%'
OR LOWER(treatmentstring) LIKE '%reintubation%'
OR LOWER(treatmentstring) LIKE '%assist controlled%'
OR LOWER(treatmentstring) LIKE '%volume controlled%'
OR LOWER(treatmentstring) LIKE '%pressure controlled%'
OR LOWER(treatmentstring) LIKE '%trach collar%'
THEN 4

WHEN -- Noninvasive ventilation
LOWER(treatmentstring) LIKE '%volume assured%'
OR LOWER(treatmentstring) LIKE '%non-invasive ventilation%'
OR LOWER(treatmentstring) LIKE '%cpap%'
THEN 3

WHEN -- Either invasive or noninvasive ventilation:
LOWER(treatmentstring) LIKE '%mechanical ventil%'
OR LOWER(treatmentstring) LIKE '%pressure support%'
OR LOWER(treatmentstring) LIKE '%peep%'
OR LOWER(treatmentstring) LIKE '%ventilator%'
OR LOWER(treatmentstring) LIKE '%tidal volume%'
THEN 2

WHEN -- Supplemental oxygen:
LOWER(treatmentstring) LIKE '%nasal mask%'
OR LOWER(treatmentstring) LIKE '%nasal cannula%'
OR LOWER(treatmentstring) LIKE '%non-rebreather mask%'
OR LOWER(treatmentstring) LIKE '%face tent%'
THEN 1

WHEN -- Oxygen therapy but unknown what type:
( LOWER(treatmentstring) LIKE '%ventilat%' AND NOT LOWER(treatmentstring) LIKE '%hyperventilat%' )
OR LOWER(treatmentstring) LIKE '%oxygen therapy%'
THEN 0

ELSE NULL
  END) AS type
   FROM `oxygenators-209612.eicu.treatment`
  WHERE treatmentoffset >= -720 AND
(
-- Invasive ventilation
LOWER(treatmentstring) LIKE '%tracheal suctioning%'
OR LOWER(treatmentstring) LIKE '%tube%'
OR LOWER(treatmentstring) LIKE '%tracheostomy%'
OR LOWER(treatmentstring) LIKE '%reintubation%'
OR LOWER(treatmentstring) LIKE '%assist controlled%'
OR LOWER(treatmentstring) LIKE '%volume controlled%'
OR LOWER(treatmentstring) LIKE '%pressure controlled%'
OR LOWER(treatmentstring) LIKE '%trach collar%'

OR
-- Noninvasive ventilation
LOWER(treatmentstring) LIKE '%volume assured%'
OR LOWER(treatmentstring) LIKE '%non-invasive ventilation%'
OR LOWER(treatmentstring) LIKE '%cpap%'

OR
-- Either invasive or noninvasive ventilation:
LOWER(treatmentstring) LIKE '%mechanical ventil%'
OR LOWER(treatmentstring) LIKE '%pressure support%'
OR LOWER(treatmentstring) LIKE '%peep%'
OR LOWER(treatmentstring) LIKE '%ventilator%'
OR LOWER(treatmentstring) LIKE '%tidal volume%'

OR
-- Supplemental oxygen:
LOWER(treatmentstring) LIKE '%nasal mask%'
OR LOWER(treatmentstring) LIKE '%nasal cannula%'
OR LOWER(treatmentstring) LIKE '%non-rebreather mask%'
OR LOWER(treatmentstring) LIKE '%face tent%'

OR
-- Oxygen therapy but unknown what type:
( LOWER(treatmentstring) LIKE '%ventilat%' AND NOT LOWER(treatmentstring) LIKE '%hyperventilat%' )
OR LOWER(treatmentstring) LIKE '%oxygen therapy%'
)
GROUP BY patientunitstayid, treatmentoffset, activeUponDischarge
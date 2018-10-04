# Extraction notes

This document provides an overview of where which variables can be found in the eICU tables. Also, notes, or links to notes, are added at the end on how to extract and construct variables.
This file aims to fullfill a similar function as [this Google doc](https://docs.google.com/document/d/1vgtQv0d8sVcbkghpmpTmzZ3wYnDZFzUPNshq2KLEiaU/edit) did for MIMIC.


## Overview of relevant tables

Source table | Variables of interest | Remarks
--- | --- | ---
nursecharting | nursingChartValue<br>nursingchartcelltypevallabel | Whenever `nursingchartcelltypevallabel = 'O2 L/%'`, `nursingChartValue` gives the oxygen flow, whose existence indicates that the patient is under oxygen therapy.<br>Whenever `nursingchartcelltypevallabel = 'O2 Admin Device'`, `nursingChartValue` gives the oxygen administration device.
respiratorycare | 		ventstartoffset, ventendoffset |  Start and end times of ventilation, but they are [currently not transcoded correctly from the raw ICU data](https://github.com/MIT-LCP/eicu-code/issues/49)
respiratorycharting | respchartvalue | Sometimes contains a string that indicates oxygen therapy.
treatment | treatmentstring | Sometimes contains a string that indicates oxygen therapy.




## Extraction notes

[Ventilation times](https://github.com/nus-mornin-lab/oxygenation_kc/issues/12)

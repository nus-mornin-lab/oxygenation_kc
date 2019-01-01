-- fluid intake in table ‘inputevents_mv’

WITH intake_im AS (

  SELECT afc.*

         , im.starttime

         , im.endtime

        -- convert the unit to ml

         , CASE WHEN im.totalamountuom like 'uL' THEN im.totalamount/1000

                WHEN im.totalamountuom like 'ounces' THEN im.totalamount*29.27

                ELSE im.totalamount END AS amount

    FROM `oxygenators-209612.mimiciii_clinical.icustay_detail` AS afc

         LEFT JOIN `oxygenators-209612.mimiciii_clinical.inputevents_mv` AS im

          ON im.icustay_id = afc.icustay_id

          WHERE (im.totalamountuom like 'ml' or im.totalamountuom like 'uL' or im.totalamountuom like 'ounces')

   AND im.starttime BETWEEN afc.intime AND DATETIME_ADD(afc.intime, INTERVAL 72 HOUR)

     AND amount IS NOT NULL

)





--fluid intake in table ‘inputevents_cv’

-- inputevents_cv only has charttime

, intake_ic AS (

  SELECT afc.*

         , ic.charttime

         -- convert the unit to ml

         , CASE WHEN ic.amountuom like 'tsp' THEN amount/5

                              ELSE ic.amount END AS amount

    FROM `oxygenators-209612.mimiciii_clinical.icustay_detail` afc

         LEFT JOIN `oxygenators-209612.mimiciii_clinical.inputevents_cv` ic

           ON ic.icustay_id = afc.icustay_id

          WHERE (ic.amountuom like 'cc' or ic.amountuom like 'ml' or ic.amountuom like 'tsp')

   AND ic.charttime BETWEEN afc.intime AND DATETIME_ADD(afc.intime, INTERVAL 72 HOUR)

)



--fluid output in table ‘outputevents’

  , output AS (

  SELECT afc.icustay_id

       --, value

       --, oe.itemid

       --, di.label

       , sum(value) AS output_fluid

  FROM `oxygenators-209612.mimiciii_clinical.icustay_detail` afc

       LEFT JOIN `oxygenators-209612.mimiciii_clinical.outputevents` oe

       ON afc.icustay_id = oe.icustay_id

       LEFT JOIN `oxygenators-209612.mimiciii_clinical.d_items` di

       ON di.itemid = oe.itemid

 WHERE oe.charttime BETWEEN afc.intime AND DATETIME_ADD(afc.intime, INTERVAL 72 HOUR)

 GROUP BY afc.icustay_id

)



-- sum of fluid input in 72 hours

  , input AS (

  SELECT intake.icustay_id

       , sum(intake.amount) AS intake_fluid

  FROM (SELECT icustay_id

               , amount

          from intake_im

        UNION DISTINCT

        SELECT icustay_id

               , amount

          from intake_ic) intake

 GROUP BY intake.icustay_id

)



SELECT DISTINCT input.icustay_id

       --, output.output_fluid

       , input.intake_fluid - output.output_fluid AS fluid_balance

  FROM input

       LEFT JOIN output

       ON output.icustay_id = input.icustay_id

--Delete one wrong record

 WHERE output_fluid <> 150400

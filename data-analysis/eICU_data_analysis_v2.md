Oxygen project using eICU data
================
Willem van den Boom
August 10, 2018

``` r
if(!require(bigrquery)) {
  install.packages("bigrquery")
  library("bigrquery")
}
```

    ## Loading required package: bigrquery

``` r
# Project ID from Google Cloud
project_id <- "oxygenators-209612"
options(httr_oauth_cache=FALSE)

# Wrapper for running BigQuery queries.
run_query <- function(query){
    data <- query_exec(query, project=project_id, use_legacy_sql = FALSE, max_pages = Inf)
    return(data)
}

# Library for fitting generalized additive models (GAMs)
library(mgcv)
```

    ## Loading required package: nlme

    ## This is mgcv 1.8-24. For overview type 'help("mgcv-package")'.

``` r
if(!require(mgcv)) {
  install.packages("mgcv")
  library("mgcv")
}
```

Read in data from eICU
======================

``` r
patient <- run_query('
SELECT * FROM eicu.final_patient_results
')

O2measurement <- run_query('
SELECT * FROM eicu.final_measurement_results
')
```

Data preprocessing
==================

Gender
------

Transform gender to a factor rather than string Set genders that are neither male nor female as missing, effectively excluding these from the analysis

``` r
if(is.character(patient$gender)) patient$gender_string <- patient$gender
summary(as.factor(patient$gender_string))
```

    ##          Female    Male   Other Unknown 
    ##       5   25010   29757       4       4

``` r
patient$gender <- NA
patient$gender[patient$gender_string == "Female"] = "F"
patient$gender[patient$gender_string == "Male"] = "M"

patient$gender = as.factor(patient$gender)
```

ICU type
--------

Consolidate the various ICU types such that only general, cardiac, and neuro ICU remain.

### From Slack

*Mornin Feng* The followings are my suggestions: 1/ Just exclude Neuro ICUS 2/ Merge “Cardiac ICU” “CCU-CTICU”: Coronary Care Unit / Cardiothoracic ICU “CTICU”: Cardiothoracic ICU as CCUs, BUT keep “CSICU”: Cardiac Surgery ICU separately as CSICU 3/ MICU and SICU should not be merged 4/ Med-Surg ICU, KC See what do you think? (edited)

*KC See* I largely agree with Mornin. The Neuro ICU is unclear what it is - Medical Neuro vs Neurosurgical. For CSICU, I think it is like CTICU. Can we do analysis with and without it, and see if there is a difference? MICU, MSICU, and SICU should be separate. Then if all shows similar results, we can pool everything too

``` r
patient$unit_type = as.factor(patient$unittype)

#levels(patient$unit_type)[levels(patient$unit_type) %in% c("Med-Surg ICU", "MICU", "SICU")] = "General ICU"
levels(patient$unit_type)[levels(patient$unit_type) %in% c("CCU-CTICU", "CSICU", "CTICU")] = "Cardiac ICU"
```

Oxygen measurements
===================

We remove oxygen measurements that are outside of the range \[10, 100\]

``` r
O2measurement <- O2measurement[O2measurement$spO2_Value <= 100 & O2measurement$spO2_Value >= 10,]
```

Count the number of oxygen measurements per patient

``` r
tmp <- unique(O2measurement$patient_ID)
tmp <- tmp[!(tmp %in% patient$patient_ID)]
tmp <- table(O2measurement$patient_ID, exclude = tmp)
patient$nOxy <- as.numeric(tmp[match(patient$patient_ID, names(tmp))])
patient$nOxy[is.na(patient$nOxy)] <- 0
mean(patient$nOxy >= 72)
```

    ## [1] 0.3529025

Subset selection
================

The following code selects cases of interest while also providing the info required for a flow diagram: That is, how many patients did not meet the inclusion criteria.

``` r
cat("Total number of patients:", nrow(patient))
```

    ## Total number of patients: 54780

``` r
# Ages above 89 are recorded as "> 89" in the eICU data
# The current SQL code translates "> 89" to "89" such that we cannot distinguish between 89 and >89.
# As we use age as a confounder, we remove those with age 89.
# We only consider "adults" (age >= 16).
tmp <- patient$age < 16 | patient$age == 89
cat("\nPatients outside age range:", sum(tmp))
```

    ## 
    ## Patients outside age range: 2773

``` r
# `delete` records which cases to delete from patient
delete <- tmp

# Delete those with fewer than 72 oxygen measurements
tmp <- patient$nOxy < 72
cat("\nPatients with too few measurements:", sum(tmp))
```

    ## 
    ## Patients with too few measurements: 35448

``` r
delete <- delete | tmp

# Delete those whose gender is unknown or other
tmp <- is.na(patient$gender)
cat("\nPatients with missing or 'other' gender:", sum(tmp))
```

    ## 
    ## Patients with missing or 'other' gender: 13

``` r
delete <- delete | tmp

patient_subset <- patient[!delete,]
cat("\nPatients selected:", nrow(patient_subset))
```

    ## 
    ## Patients selected: 18583

We only keep hospitals with at least 100 cases

``` r
cat("\n Number of hospitals in current subset:", length(unique(patient_subset$hospitalid)))
```

    ## 
    ##  Number of hospitals in current subset: 109

``` r
tmp <- table(patient_subset$hospitalid)
cat("\n Number of hospitals with at least 100 patients:", sum(tmp >= 100))
```

    ## 
    ##  Number of hospitals with at least 100 patients: 41

``` r
delete <- patient_subset$hospitalid %in% as.numeric(names(tmp[tmp < 100]))
patient_subset <- patient_subset[!delete,]
patient_subset$hospital_id = as.factor(patient_subset$hospitalid)

cat("\n Number of patients in selected subset:", nrow(patient_subset))
```

    ## 
    ##  Number of patients in selected subset: 17340

Demographics
------------

Let us compare the demographics before and after the subset selection.

``` r
# Variables of which we like summaries
tmp <- c('age', 'gender', 'unit_type', 'nOxy', 'mortality_in_ICU')

cat("Mortality in 'patient':", sum(patient$mortality_in_ICU), "\n")
```

    ## Mortality in 'patient': 3413

``` r
summary(patient[patient$age >= 16,tmp])
```

    ##       age         gender             unit_type          nOxy        
    ##  Min.   :16.00   F   :24997   Cardiac ICU :13211   Min.   :    0.0  
    ##  1st Qu.:54.00   M   :29743   Med-Surg ICU:27099   1st Qu.:   17.0  
    ##  Median :66.00   NA's:   13   MICU        : 4722   Median :   45.0  
    ##  Mean   :64.26                Neuro ICU   : 4937   Mean   :   93.7  
    ##  3rd Qu.:77.00                SICU        : 4784   3rd Qu.:  102.0  
    ##  Max.   :89.00                                     Max.   :19484.0  
    ##  mortality_in_ICU 
    ##  Min.   :0.00000  
    ##  1st Qu.:0.00000  
    ##  Median :0.00000  
    ##  Mean   :0.06232  
    ##  3rd Qu.:0.00000  
    ##  Max.   :1.00000

``` r
cat("Mortality in 'patient_subset':", sum(patient_subset$mortality_in_ICU), "\n")
```

    ## Mortality in 'patient_subset': 1370

``` r
summary(patient_subset[,tmp])
```

    ##       age        gender          unit_type         nOxy       
    ##  Min.   :16.00   F:7718   Cardiac ICU :4358   Min.   :  72.0  
    ##  1st Qu.:54.00   M:9622   Med-Surg ICU:6963   1st Qu.:  97.0  
    ##  Median :65.00            MICU        :1851   Median : 141.0  
    ##  Mean   :62.88            Neuro ICU   :2095   Mean   : 217.9  
    ##  3rd Qu.:75.00            SICU        :2073   3rd Qu.: 244.0  
    ##  Max.   :88.00                                Max.   :4059.0  
    ##  mortality_in_ICU 
    ##  Min.   :0.00000  
    ##  1st Qu.:0.00000  
    ##  Median :0.00000  
    ##  Mean   :0.07901  
    ##  3rd Qu.:0.00000  
    ##  Max.   :1.00000

Compute summaries of oxygen measurements
========================================

We compute the median oxygen level and the proportion of measurements within 94% to 97% oxygen saturation. We do this after subset selection as it is much faster to compute these only for the subset of interest.

We currently ignore the time aspect of the measurements. However, one should probably take into account that certain measurements are less spread out than others.

``` r
patient_subset$median <- NA
patient_subset$prop <- NA
n <- nrow(patient_subset)
pb <- txtProgressBar(max = n, style = 3)
for(i in 1:n) {
  tmp <- O2measurement$spO2_Value[O2measurement$patient_ID == patient_subset$patient_ID[i]]
  
  patient_subset$median[i] <- median(tmp)
  patient_subset$prop[i] <- mean(tmp >= 94 & tmp <= 97)
  
  setTxtProgressBar(pb, i)
}
close(pb)
```

``` r
summary(patient_subset$median)
```

    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##   67.00   96.00   97.00   97.09   99.00  100.00

``` r
summary(patient_subset$prop)
```

    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##  0.0000  0.2417  0.4080  0.3961  0.5459  0.9750

Plot some basic comparison of the two outcome groups.

``` r
boxplot(patient_subset$median ~ patient_subset$mortality_in_ICU)
```

![](eICU_data_analysis_v2_files/figure-markdown_github/unnamed-chunk-11-1.png)

``` r
boxplot(patient_subset$prop ~ patient_subset$mortality_in_ICU)
```

![](eICU_data_analysis_v2_files/figure-markdown_github/unnamed-chunk-11-2.png)

Model fitting
=============

Median of measurements
----------------------

We fit a generalized additive model (GAM) to check for the effect of the median oxygen saturation. GAMs are regression models that allow for nonlinear effects of the predictors. We add gender and age as predictors to control for them. We also control for hospital but since there are so many hospitals, we add it as a random effect.

``` r
logistic <- function(x) 1/(1+exp(-x))
```

``` r
gamfitMed <- gamm(mortality_in_ICU ~ s(median)+gender+s(age), data = patient_subset, family = binomial, random = list(hospital_id = ~ 1))$gam
```

    ## 
    ##  Maximum number of PQL iterations:  20

    ## iteration 1

    ## iteration 2

    ## iteration 3

    ## iteration 4

    ## iteration 5

    ## iteration 6

    ## iteration 7

    ## iteration 8

``` r
summary(gamfitMed)
```

    ## 
    ## Family: binomial 
    ## Link function: logit 
    ## 
    ## Formula:
    ## mortality_in_ICU ~ s(median) + gender + s(age)
    ## 
    ## Parametric coefficients:
    ##             Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept) -2.64709    0.09222  -28.70  < 2e-16 ***
    ## genderM      0.15571    0.05854    2.66  0.00783 ** 
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Approximate significance of smooth terms:
    ##             edf Ref.df     F  p-value    
    ## s(median) 5.029  5.029 34.54  < 2e-16 ***
    ## s(age)    1.000  1.000 65.75 5.46e-16 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## R-sq.(adj) =  0.0169   
    ##   Scale est. = 1         n = 17340

``` r
xRange = c(92, 100)
yRange = c(0, .2)

xlab <- "Median oxygen saturation (SpO2)"
ylab <- "Probability of ICU mortality" 

xName <- "median"

main <- "Median of measurements"

# Color for dotted line
colD <- "Black"

    plot(1, type = 'n', xlim = xRange, ylim = yRange,
         ylab = ylab,
         xlab = xlab, main = main, yaxs = 'i', xaxs = 'i', yaxt = 'n', xaxt = 'n')
    
    att <- pretty(yRange)
if(!isTRUE(all.equal(att, round(att, digits = 2)))) {
  axis(2, at = att, lab = paste0(sprintf('%.1f', att*100), '%'), las = TRUE)
} else axis(2, at = att, lab = paste0(att*100, '%'), las = TRUE)
    
    att <- pretty(xRange)
    axis(1, at = att, lab = paste0(att, '%'), las = TRUE)

    
    eval(parse(text = paste(c('predictionsPlusCI <- predict(gamfitMed, newdata = data.frame(',
                              xName, ' = gamfitMed$model$', xName, ", gender = 'F', age = median(gamfitMed$model$age), hospital_id = 264), type = 'link', se.fit = T)"), collapse = "")))

  
  # We have to use the data on which GAM was fit for confidence region as the GAM does not provide standard errors for 'new' input
  eval(parse(text = paste0('xx <- gamfitMed$model$', xName)))
  ord.index <- order(xx)
  xx <- xx[ord.index]
  
  if(gamfitMed$family$link == 'logit') {
    lcl <- logistic(predictionsPlusCI$fit[ord.index] - 1.96*predictionsPlusCI$se.fit[ord.index])
    ucl <- logistic(predictionsPlusCI$fit[ord.index] + 1.96*predictionsPlusCI$se.fit[ord.index])
    
    lines(x = xx, y = lcl, lty = 2, lwd = 2, col = colD)
    lines(x = xx, y = ucl, lty = 2, lwd = 2, col = colD)
    lines(xx, logistic(predictionsPlusCI$fit[ord.index]), lwd = 3)
  } else {
    lcl <- predictionsPlusCI$fit[ord.index] - 1.96*predictionsPlusCI$se.fit[ord.index]
    ucl <- predictionsPlusCI$fit[ord.index] + 1.96*predictionsPlusCI$se.fit[ord.index]
    
    lines(x = xx, y = lcl, lty = 2, lwd = 2)
    lines(x = xx, y = ucl, lty = 2, lwd = 2)
    lines(xx, predictionsPlusCI$fit[ord.index], lwd = 3)
  }
```

![](eICU_data_analysis_v2_files/figure-markdown_github/gamfitMed-1.png)

Proportion of measurements within range
---------------------------------------

We now fit a GAM with the proportion of measurements within a range instead of the median of the measurements.

``` r
gamfitProp <- gamm(mortality_in_ICU ~ s(prop)+gender+s(age), data = patient_subset, family = binomial, random = list(hospital_id = ~ 1))$gam
```

    ## 
    ##  Maximum number of PQL iterations:  20

    ## iteration 1

    ## iteration 2

    ## iteration 3

    ## iteration 4

``` r
summary(gamfitProp)
```

    ## 
    ## Family: binomial 
    ## Link function: logit 
    ## 
    ## Formula:
    ## mortality_in_ICU ~ s(prop) + gender + s(age)
    ## 
    ## Parametric coefficients:
    ##             Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept) -2.72451    0.08906 -30.593  < 2e-16 ***
    ## genderM      0.19492    0.05849   3.333 0.000862 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Approximate significance of smooth terms:
    ##           edf Ref.df     F p-value    
    ## s(prop) 4.001  4.001 50.00  <2e-16 ***
    ## s(age)  1.000  1.000 70.92  <2e-16 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## R-sq.(adj) =  0.017   
    ##   Scale est. = 1         n = 17340

``` r
logistic <- function(x) 1/(1+exp(-x))
xRange = c(0, max(patient_subset$prop, na.rm= TRUE))
yRange = c(0, .2)

xlab <- "Proportion of time with an SpO2 within 94 to 97"
ylab <- "Probability of ICU mortality" 

xName <- "prop"

main <- "Effect of treatment regime"

    plot(1, type = 'n', xlim = xRange, ylim = yRange,
         ylab = ylab,
         xlab = xlab, main = main, yaxs = 'i', xaxs = 'i', yaxt = 'n', xaxt = 'n')
    
    att <- pretty(yRange)
if(!isTRUE(all.equal(att, round(att, digits = 2)))) {
  axis(2, at = att, lab = paste0(sprintf('%.1f', att*100), '%'), las = TRUE)
} else axis(2, at = att, lab = paste0(att*100, '%'), las = TRUE)
    
    att <- pretty(xRange)
    axis(1, at = att, lab = paste0(att*100, '%'), las = TRUE)

    
    eval(parse(text = paste(c('predictionsPlusCI <- predict(gamfitProp, newdata = data.frame(',
                              xName, ' = gamfitProp$model$', xName, ", gender = 'F', age = median(gamfitProp$model$age)), type = 'link', se.fit = T)"), collapse = "")))

  
  # We have to use the data on which GAM was fit for confidence region as the GAM does not provide standard errors for 'new' input
  eval(parse(text = paste0('xx <- gamfitProp$model$', xName)))
  ord.index <- order(xx)
  xx <- xx[ord.index]
  
  if(gamfitProp$family$link == 'logit') {
    lcl <- logistic(predictionsPlusCI$fit[ord.index] - 1.96*predictionsPlusCI$se.fit[ord.index])
    ucl <- logistic(predictionsPlusCI$fit[ord.index] + 1.96*predictionsPlusCI$se.fit[ord.index])
    
    lines(x = xx, y = lcl, lty = 2, lwd = 2)
    lines(x = xx, y = ucl, lty = 2, lwd = 2)
    lines(xx, logistic(predictionsPlusCI$fit[ord.index]), lwd = 3)
  } else {
    lcl <- predictionsPlusCI$fit[ord.index] - 1.96*predictionsPlusCI$se.fit[ord.index]
    ucl <- predictionsPlusCI$fit[ord.index] + 1.96*predictionsPlusCI$se.fit[ord.index]
    
    lines(x = xx, y = lcl, lty = 2, lwd = 2)
    lines(x = xx, y = ucl, lty = 2, lwd = 2)
    lines(xx, predictionsPlusCI$fit[ord.index], lwd = 3)
  }
```

![](eICU_data_analysis_v2_files/figure-markdown_github/gamfitProp-1.png)

Odds ratios
-----------

Based on the model fits, we can estimate odds ratios, including 95% confidence intervals.

``` r
if(!require("oddsratio")) {
  install.packages("oddsratio")
  library(oddsratio)
}
```

    ## Loading required package: oddsratio

``` r
tmp <- or_gam(data = patient_subset, model = gamfitMed, pred = "median", values = c(96, 100))

cat(
  "The odds ratio of mortality for a median oxygen saturation at 100% versus 96% is ",
  tmp$oddsratio,
  " (95% CI ",
  tmp$`CI_high (97.5%)`,
  " to ",
  tmp$`CI_low (2.5%)`,
  ").",
  sep = ""
)
```

    ## The odds ratio of mortality for a median oxygen saturation at 100% versus 96% is 1.639637 (95% CI 1.607691 to 1.672218).

``` r
tmp <- or_gam(data = patient_subset, model = gamfitProp, pred = "prop", values = c(.8, .4))

cat(
  "The odds ratio of mortality for a proportion of measurements within the range at 40% versus 80% is ",
  tmp$oddsratio,
  " (95% CI ",
  tmp$`CI_low (2.5%)`,
  " to ",
  tmp$`CI_high (97.5%)`,
  ").",
  sep = ""
)
```

    ## The odds ratio of mortality for a proportion of measurements within the range at 40% versus 80% is 3.788172 (95% CI 2.960667 to 4.846965).

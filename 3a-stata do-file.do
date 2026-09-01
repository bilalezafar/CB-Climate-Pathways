/***********************************************************************

PROJECT DO-FILE

Manuscript:
Do Climate Risks Precede Climate Communication?
Global Evidence from Central Banks

DATA SOURCES AND PANEL STRUCTURE

Unit of analysis:
Country-year panel, 1996-2024.

Main sources:
- Central bank climate discourse:
  BIS Central Bank Speeches database; sentence-level climate
  classification using validated climate lexicon and ClimateBERT.

- Key explanatory variables:
  Climate vulnerability and readiness: ND-GAIN Country Index.
  Climate policy intensity: Climate Change Laws of the World (CCLW).

- Baseline controls:
  GDP per capita, private credit, CO2 emissions, and fuel exports:
  World Bank World Development Indicators (WDI).
  Inflation: IMF International Financial Statistics (IFS) / World Bank WDI.
  Institutional quality: World Bank Worldwide Governance Indicators (WGI).

- Central bank institutional controls:
  Central Bank Independence-Extended (CBIE) dataset
  (Romelli 2022, 2024).

- Total communication volume:
  Derived from the BIS Central Bank Speeches corpus.

ROOT-FOLDER SETUP

Place this do-file and the supplementary .dta file in the same root folder.
The do-file creates and updates the "results" folder automatically.

Expected structure:

    root/
      final_project.do
      3-climate_cb supplementary.dta
      results/

FINAL REPORTED OUTPUT STRUCTURE

Main paper:
  Table 2  Two-way fixed effects with lag structure
  Table 3  Distributional heterogeneity
  Table 4  Panel predictive tests
  Table 5  Corrected Paris DiD and event study
  Figure 1 Absolute Paris trends and event-study differential

Appendix:
  Figure A1 Descriptive communication trends
  Table A1  Year-level descriptives
  Table A2  Missing-covariate robustness
  Table A3  Poisson fixed-effects robustness
  Table A4  Correlation and within-panel diagnostics
  Table A5  Alternative and simultaneous specifications
  Table A6  CBI/reporting controls and CBI heterogeneity
  Table A7  Total communication-volume robustness
  Table A8  Paris robustness
  Table A9  Rambachan-Roth HonestDiD sensitivity
  Figure A2 Rambachan-Roth medium-run sensitivity

Diagnostics not intended as standalone manuscript exhibits:
  Paris treatment-classification verification
  Paris pre/post decomposition
  Raw-count Paris trend plot
  CBI within/between variation diagnostics
  CBI marginal-effects table and plot
  Cross-sectional-dependence diagnostic

***********************************************************************/

version 16.0
clear all
set more off
set linesize 255

capture log close _all


*============================================================*
* BLOCK 0. Load and validate the supplementary dataset
*============================================================*

local DATAFILE "3-climate_cb supplementary.dta"

capture confirm file "`DATAFILE'"

if _rc {
    local dtafiles : dir "." files "*.dta"
    local ndta : word count `dtafiles'

    if `ndta' == 1 {
        local DATAFILE `dtafiles'
        di as text "Preferred data filename not found."
        di as result "Single .dta file detected and loaded: `DATAFILE'"
    }
    else {
        di as error "The supplementary dataset could not be uniquely identified."
        di as error "Place one .dta file in the root folder or edit local DATAFILE in Block 0."
        exit 601
    }
}

use `"`DATAFILE'"', clear

local REQUIRED ///
    id_iso3 year ///
    climate_sents_count climate_bert_score ///
    climate_vulnerability climate_readiness policy_count ///
    gdp_pc inflation_cpi credit_banks_gdp wgi_score co2_pc fuel_exports_share ///
    cbi_index cb_reporting ///
    total_speeches_count total_sents_count total_words_count ///
    climate_speeches_count climate_words_count

foreach v of local REQUIRED {
    capture confirm variable `v'
    if _rc {
        di as error "Required variable not found: `v'"
        exit 111
    }
}

order ///
    id_iso3 year ///
    climate_sents_count climate_bert_score ///
    climate_vulnerability climate_readiness ///
    policy_count ///
    gdp_pc inflation_cpi credit_banks_gdp wgi_score co2_pc fuel_exports_share ///
    cbi_index cb_reporting ///
    total_speeches_count total_sents_count total_words_count ///
    climate_speeches_count climate_words_count

sort id_iso3 year
isid id_iso3 year
xtset id_iso3 year

compress
describe


*============================================================*
* BLOCK 1. Variable labels
*============================================================*

label var id_iso3               "Country panel id"
label var year                  "Year"
label var climate_sents_count   "Climate discourse (sentence count)"
label var climate_bert_score    "Climate discourse intensity (ClimateBERT score)"
label var climate_vulnerability "Climate vulnerability (ND-GAIN)"
label var climate_readiness     "Climate readiness (ND-GAIN)"
label var policy_count          "Climate policy intensity (policy count)"
label var gdp_pc                "GDP per capita (constant 2015 USD)"
label var inflation_cpi         "Inflation (CPI, %)"
label var credit_banks_gdp      "Private credit (% of GDP)"
label var wgi_score             "Institutional quality (WGI government effectiveness)"
label var co2_pc                "CO2 emissions per capita"
label var fuel_exports_share    "Fuel exports (% of merchandise exports)"
label var cbi_index             "Central bank independence index"
label var cb_reporting          "Central bank reporting/disclosure index"
label var total_speeches_count  "Total central bank speeches"
label var total_sents_count     "Total central bank speech sentences"
label var total_words_count     "Total central bank speech words"
label var climate_speeches_count "Climate-related speeches"
label var climate_words_count    "Climate-related words"


*============================================================*
* BLOCK 2. Main-text and appendix variable construction
*============================================================*

sort id_iso3 year
xtset id_iso3 year

capture drop ln_climate_sents
gen double ln_climate_sents = ln(1 + climate_sents_count) ///
    if !missing(climate_sents_count)
label var ln_climate_sents "ln(1 + climate-related sentence count)"

capture drop ln_policy_count
gen double ln_policy_count = ln(1 + policy_count) ///
    if !missing(policy_count)
label var ln_policy_count "ln(1 + climate policy count)"

capture drop ln_gdp_pc
gen double ln_gdp_pc = ln(gdp_pc) if gdp_pc > 0
label var ln_gdp_pc "ln(GDP per capita, constant 2015 USD)"

capture drop asinh_inflation
gen double asinh_inflation = asinh(inflation_cpi) ///
    if !missing(inflation_cpi)
label var asinh_inflation "asinh(Inflation, CPI %)"

capture drop ln1p_co2_pc
gen double ln1p_co2_pc = ln(1 + co2_pc) ///
    if !missing(co2_pc)
label var ln1p_co2_pc "ln(1 + CO2 emissions per capita)"

capture drop vuln_100
gen double vuln_100 = 100 * climate_vulnerability ///
    if !missing(climate_vulnerability)
label var vuln_100 "Climate vulnerability (0-100 index points)"

capture drop ready_100
gen double ready_100 = 100 * climate_readiness ///
    if !missing(climate_readiness)
label var ready_100 "Climate readiness (0-100 index points)"

capture drop L1_DV
gen double L1_DV = L1.ln_climate_sents
label var L1_DV "Lagged climate discourse, t-1"


*============================================================*
* BLOCK 3. Global macros for regression variables
*============================================================*

global DV "ln_climate_sents"
global IVS "vuln_100 ready_100 ln_policy_count"
global CTRLS "ln_gdp_pc asinh_inflation credit_banks_gdp wgi_score ln1p_co2_pc fuel_exports_share"

di as text "Dependent variable: $DV"
di as text "Main explanatory variables: $IVS"
di as text "Controls: $CTRLS"


*============================================================*
* BLOCK 4. Results folders, output paths, and packages
*============================================================*

capture mkdir "results"
capture mkdir "results/main_paper"
capture mkdir "results/main_paper/tables"
capture mkdir "results/main_paper/figures"
capture mkdir "results/appendix"
capture mkdir "results/appendix/tables"
capture mkdir "results/appendix/figures"
capture mkdir "results/diagnostics"
capture mkdir "results/working"

global OUTROOT "results"
global MAINTAB "results/main_paper/tables"
global MAINFIG "results/main_paper/figures"
global APPTAB  "results/appendix/tables"
global APPFIG  "results/appendix/figures"
global DIAGDIR "results/diagnostics"
global WORKDIR "results/working"

global TABLE2 "$MAINTAB/Table_2_TWFE_lag_structure"
global TABLE3 "$MAINTAB/Table_3_quantile_regressions"
global TABLE4 "$MAINTAB/Table_4_panel_predictive_tests"
global TABLE5 "$MAINTAB/Table_5_revised_Paris_DiD_eventstudy"
global FIGURE1 "$MAINFIG/Figure_1_revised_Paris_absolute_and_eventstudy"

global FIGA1 "$APPFIG/Figure_A1_descriptive_communication_trends"
global FIGA2 "$APPFIG/Figure_A2_HonestDiD_mediumrun_sensitivity"

global TABLEA1 "$APPTAB/Table_A1_year_level_descriptives"
global TABLEA2 "$APPTAB/Table_A2_missing_covariates_MI"
global TABLEA3 "$APPTAB/Table_A3_poisson_FE_count_model"
global TABLEA4 "$APPTAB/Table_A4_main_explanatory_variable_correlations"
global TABLEA5 "$APPTAB/Table_A5_alternative_joint_specifications"
global TABLEA6 "$APPTAB/Table_A6_CBI_reporting_and_heterogeneity"
global TABLEA7 "$APPTAB/Table_A7_total_communication_volume"
global TABLEA8 "$APPTAB/Table_A8_Paris_robustness"
global TABLEA9 "$APPTAB/Table_A9_HonestDiD_sensitivity"

global TREATCHECK "$DIAGDIR/Paris_treatment_classification_check"
global PREPOST "$DIAGDIR/Paris_pre_post_decomposition"
global CBIDIAG "$DIAGDIR/CBI_within_between_diagnostics"
global CBIMARG "$DIAGDIR/CBI_marginal_effects_by_vulnerability"
global CBIFIG "$DIAGDIR/CBI_marginal_effects_by_vulnerability"

capture which esttab
if _rc ssc install estout, replace

capture which coefplot
if _rc ssc install coefplot, replace

log using "$DIAGDIR/final_project.log", text replace

di as result "Main-paper tables: $MAINTAB"
di as result "Main-paper figures: $MAINFIG"
di as result "Appendix tables: $APPTAB"
di as result "Appendix figures: $APPFIG"
di as result "Diagnostics: $DIAGDIR"

*============================================================*
* BLOCK 5. Main paper Table 2
* Climate risk exposure and discourse:
* Two-way fixed effects with lag structure
*
* Output:
*   results/main_paper/tables/Table_2_TWFE_lag_structure.rtf
*============================================================*

* Required packages are checked centrally in Block 4.


*------------------------------------------------------------*
* 5.1 Panel declaration
*------------------------------------------------------------*

xtset id_iso3 year


*------------------------------------------------------------*
* 5.2 Estimate Table 2 models
*------------------------------------------------------------*

eststo clear

* Model (1): Baseline contemporaneous FE
xtreg $DV $IVS $CTRLS i.year, fe vce(cluster id_iso3)

estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Country"
estadd local RegTiming "t"
estadd local LagDV "No"

eststo T2_M1


* Model (2): Lagged explanatory variables, t-1
xtreg $DV L1.($IVS) $CTRLS i.year, fe vce(cluster id_iso3)

estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Country"
estadd local RegTiming "t-1"
estadd local LagDV "No"

eststo T2_M2


* Model (3): Dynamic FE, persistence check
xtreg $DV L1_DV L1.($IVS) $CTRLS i.year, fe vce(cluster id_iso3)

estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Country"
estadd local RegTiming "t-1"
estadd local LagDV "Yes"

eststo T2_M3


* Model (4): Lagged explanatory variables, t-2
xtreg $DV L2.($IVS) $CTRLS i.year, fe vce(cluster id_iso3)

estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Country"
estadd local RegTiming "t-2"
estadd local LagDV "No"

eststo T2_M4


*------------------------------------------------------------*
* 5.3 Export Table 2
*------------------------------------------------------------*

esttab T2_M1 T2_M2 T2_M3 T2_M4 ///
    using "$TABLE2.rtf", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Baseline FE" "Lagged explanatory variables (t-1)" ///
            "Dynamic FE" "Lagged explanatory variables (t-2)") ///
    keep(vuln_100 ready_100 ln_policy_count ///
         L.vuln_100 L.ready_100 L.ln_policy_count ///
         L1_DV ///
         L2.vuln_100 L2.ready_100 L2.ln_policy_count ///
         ln_gdp_pc asinh_inflation credit_banks_gdp wgi_score ///
         ln1p_co2_pc fuel_exports_share _cons) ///
    order(vuln_100 L.vuln_100 L2.vuln_100 ///
          ready_100 L.ready_100 L2.ready_100 ///
          ln_policy_count L.ln_policy_count L2.ln_policy_count ///
          L1_DV ///
          ln_gdp_pc asinh_inflation credit_banks_gdp wgi_score ///
          ln1p_co2_pc fuel_exports_share _cons) ///
    coeflabels( ///
          vuln_100 "Climate vulnerability" ///
          L.vuln_100 "Climate vulnerability" ///
          L2.vuln_100 "Climate vulnerability" ///
          ready_100 "Climate readiness" ///
          L.ready_100 "Climate readiness" ///
          L2.ready_100 "Climate readiness" ///
          ln_policy_count "Climate policy intensity" ///
          L.ln_policy_count "Climate policy intensity" ///
          L2.ln_policy_count "Climate policy intensity" ///
          L1_DV "Lagged dependent variable" ///
          ln_gdp_pc "GDP per capita" ///
          asinh_inflation "Inflation" ///
          credit_banks_gdp "Private credit (% GDP)" ///
          wgi_score "Institutional quality" ///
          ln1p_co2_pc "CO2 emissions per capita" ///
          fuel_exports_share "Fuel exports (% exports)" ///
          _cons "Constant") ///
    stats(N N_g CountryFE YearFE ClusterSE RegTiming LagDV r2_w, ///
          labels("Observations" ///
                 "Countries" ///
                 "Country fixed effects" ///
                 "Year fixed effects" ///
                 "Clustered SE" ///
                 "Lagged explanatory variables timing" ///
                 "Lagged DV included" ///
                 "R-squared (within)") ///
          fmt(0 0 s s s s s 3)) ///
    addnotes("Robust standard errors clustered by country are in parentheses." ///
             "Model (1) reports the baseline contemporaneous specification." ///
             "Model (2) lags all main explanatory variables by one year." ///
             "Model (3) adds a lagged dependent variable as a persistence check and should be interpreted as a sensitivity specification rather than a causal estimate." ///
             "Model (4) introduces two-year lags of the main explanatory variables." ///
             "Because the dependent variable is ln(1 + climate-related sentence count), coefficients can be interpreted as semi-elasticities of one-plus climate-discourse volume." ///
             "*** p<0.01, ** p<0.05, * p<0.10.")


*------------------------------------------------------------*
* 5.4 Display completion message
*------------------------------------------------------------*

di as result "Table 2 saved to: $TABLE2.rtf"

*============================================================*
* BLOCK 6. Main paper Table 3
* Distributional heterogeneity in climate discourse:
* Quantile regression estimates
*
* Output:
*   results/main_paper/tables/Table_3_quantile_regressions.rtf
*============================================================*


*------------------------------------------------------------*
* 6.1 Estimate Table 3 models
*------------------------------------------------------------*

eststo clear

* Model (1): Median / q50
qreg $DV $IVS $CTRLS i.year, quantile(.50)

estadd local YearFE "Yes"

eststo T3_M1


* Model (2): q75
qreg $DV $IVS $CTRLS i.year, quantile(.75)

estadd local YearFE "Yes"

eststo T3_M2


* Model (3): q90
qreg $DV $IVS $CTRLS i.year, quantile(.90)

estadd local YearFE "Yes"

eststo T3_M3


*------------------------------------------------------------*
* 6.2 Export Table 3
*------------------------------------------------------------*

esttab T3_M1 T3_M2 T3_M3 ///
    using "$TABLE3.rtf", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("q50 (Median)" "q75" "q90") ///
    keep(vuln_100 ready_100 ln_policy_count ///
         ln_gdp_pc asinh_inflation credit_banks_gdp wgi_score ///
         ln1p_co2_pc fuel_exports_share _cons) ///
    order(vuln_100 ready_100 ln_policy_count ///
          ln_gdp_pc asinh_inflation credit_banks_gdp wgi_score ///
          ln1p_co2_pc fuel_exports_share _cons) ///
    coeflabels( ///
          vuln_100 "Climate vulnerability" ///
          ready_100 "Climate readiness" ///
          ln_policy_count "Climate policy intensity" ///
          ln_gdp_pc "GDP per capita" ///
          asinh_inflation "Inflation" ///
          credit_banks_gdp "Private credit (% GDP)" ///
          wgi_score "Institutional quality" ///
          ln1p_co2_pc "CO2 emissions per capita" ///
          fuel_exports_share "Fuel exports (% exports)" ///
          _cons "Constant") ///
    stats(YearFE N, ///
          labels("Year fixed effects" "Observations") ///
          fmt(s 0)) ///
    title("Table 3. Distributional heterogeneity in climate discourse: Quantile regression estimates") ///
    addnotes("Standard errors are in parentheses." ///
             "Quantile regressions include year fixed effects." ///
             "Unlike within estimators, standard quantile regression does not purge time-invariant country heterogeneity." ///
             "The estimates are therefore interpreted as distributional robustness evidence rather than substitutes for the baseline TWFE specifications." ///
             "*** p<0.01, ** p<0.05, * p<0.10.")


*------------------------------------------------------------*
* 6.3 Display completion message
*------------------------------------------------------------*

di as result "Table 3 saved to: $TABLE3.rtf"

*============================================================*
* BLOCK 7. Main paper Table 4
* Panel Granger-style predictive tests:
* Climate discourse, vulnerability, readiness, and policy intensity
*
* Output:
*   results/main_paper/tables/Table_4_panel_predictive_tests.rtf
*============================================================*

*------------------------------------------------------------*
* 7.1 Panel declaration
*------------------------------------------------------------*

xtset id_iso3 year


*------------------------------------------------------------*
* 7.2 Estimate Table 4 models
*------------------------------------------------------------*

eststo clear


*============================================================*
* Model (1): Explanatory variables -> Discourse
*============================================================*

xtreg $DV ///
    L1.vuln_100 L2.vuln_100 ///
    L1.ready_100 L2.ready_100 ///
    L1.ln_policy_count L2.ln_policy_count ///
    $CTRLS i.year, fe vce(cluster id_iso3)

estadd local Controls "Yes"
estadd local YearFE "Yes"
estadd local CountryFE "Yes"

test L1.vuln_100 L2.vuln_100
local p_vuln : display %6.3f r(p)

test L1.ready_100 L2.ready_100
local p_ready : display %6.3f r(p)

test L1.ln_policy_count L2.ln_policy_count
local p_policy : display %6.3f r(p)

test L1.vuln_100 L2.vuln_100 ///
     L1.ready_100 L2.ready_100 ///
     L1.ln_policy_count L2.ln_policy_count
local p_allx : display %6.3f r(p)

estadd local P_Vuln "`p_vuln'"
estadd local P_Ready "`p_ready'"
estadd local P_Policy "`p_policy'"
estadd local P_AllX "`p_allx'"
estadd local P_Discourse "-"

eststo T4_M1


*============================================================*
* Model (2): Discourse -> Policy
*============================================================*

xtreg ln_policy_count ///
    L1.$DV L2.$DV ///
    $CTRLS i.year, fe vce(cluster id_iso3)

estadd local Controls "Yes"
estadd local YearFE "Yes"
estadd local CountryFE "Yes"

test L1.$DV L2.$DV
local p_disc_policy : display %6.3f r(p)

estadd local P_Vuln "-"
estadd local P_Ready "-"
estadd local P_Policy "-"
estadd local P_AllX "-"
estadd local P_Discourse "`p_disc_policy'"

eststo T4_M2


*============================================================*
* Model (3): Discourse -> Readiness
*============================================================*

xtreg ready_100 ///
    L1.$DV L2.$DV ///
    $CTRLS i.year, fe vce(cluster id_iso3)

estadd local Controls "Yes"
estadd local YearFE "Yes"
estadd local CountryFE "Yes"

test L1.$DV L2.$DV
local p_disc_ready : display %6.3f r(p)

estadd local P_Vuln "-"
estadd local P_Ready "-"
estadd local P_Policy "-"
estadd local P_AllX "-"
estadd local P_Discourse "`p_disc_ready'"

eststo T4_M3


*============================================================*
* Model (4): Explanatory variables -> Discourse + L1(DV)
*============================================================*

xtreg $DV L1.$DV ///
    L1.vuln_100 L2.vuln_100 ///
    L1.ready_100 L2.ready_100 ///
    L1.ln_policy_count L2.ln_policy_count ///
    $CTRLS i.year, fe vce(cluster id_iso3)

estadd local Controls "Yes"
estadd local YearFE "Yes"
estadd local CountryFE "Yes"

test L1.vuln_100 L2.vuln_100
local p_vuln_dyn : display %6.3f r(p)

test L1.ready_100 L2.ready_100
local p_ready_dyn : display %6.3f r(p)

test L1.ln_policy_count L2.ln_policy_count
local p_policy_dyn : display %6.3f r(p)

test L1.vuln_100 L2.vuln_100 ///
     L1.ready_100 L2.ready_100 ///
     L1.ln_policy_count L2.ln_policy_count
local p_allx_dyn : display %6.3f r(p)

estadd local P_Vuln "`p_vuln_dyn'"
estadd local P_Ready "`p_ready_dyn'"
estadd local P_Policy "`p_policy_dyn'"
estadd local P_AllX "`p_allx_dyn'"
estadd local P_Discourse "-"

eststo T4_M4


*------------------------------------------------------------*
* 7.3 Export Table 4
*------------------------------------------------------------*

esttab T4_M1 T4_M2 T4_M3 T4_M4 ///
    using "$TABLE4.rtf", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Explanatory variables -> Discourse" ///
            "Discourse -> Policy" ///
            "Discourse -> Readiness" ///
            "Explanatory variables -> Discourse + L1(DV)") ///
    keep(L.vuln_100 L2.vuln_100 ///
         L.ready_100 L2.ready_100 ///
         L.ln_policy_count L2.ln_policy_count ///
         L.ln_climate_sents L2.ln_climate_sents) ///
    order(L.vuln_100 L2.vuln_100 ///
          L.ready_100 L2.ready_100 ///
          L.ln_policy_count L2.ln_policy_count ///
          L.ln_climate_sents L2.ln_climate_sents) ///
    coeflabels( ///
          L.vuln_100 "L1 Climate vulnerability" ///
          L2.vuln_100 "L2 Climate vulnerability" ///
          L.ready_100 "L1 Climate readiness" ///
          L2.ready_100 "L2 Climate readiness" ///
          L.ln_policy_count "L1 Climate policy intensity" ///
          L2.ln_policy_count "L2 Climate policy intensity" ///
          L.ln_climate_sents "L1 Climate discourse" ///
          L2.ln_climate_sents "L2 Climate discourse") ///
    stats(Controls YearFE CountryFE N N_g r2_w ///
          P_Vuln P_Ready P_Policy P_AllX P_Discourse, ///
          labels("Controls" ///
                 "Year FE" ///
                 "Country FE" ///
                 "Observations" ///
                 "Countries" ///
                 "Within R-squared" ///
                 "Panel B: Vulnerability lags jointly zero" ///
                 "Readiness lags jointly zero" ///
                 "Policy lags jointly zero" ///
                 "All explanatory-variable lags jointly zero" ///
                 "Discourse lags jointly zero") ///
          fmt(s s s 0 0 3 s s s s s)) ///
    title("Table 4. Panel Granger-style predictive tests: climate discourse, vulnerability, readiness, and policy intensity") ///
    addnotes("Country and year fixed effects are included in all models, and standard errors are clustered by country." ///
             "Lags cover one- and two-year horizons." ///
             "The dependent variable is climate discourse in Models (1) and (4), climate policy intensity in Model (2), and climate readiness in Model (3)." ///
             "Panel A reports fixed-effects estimates; Panel B reports joint Wald block-exogeneity test p-values." ///
             "Models (2) and (3) are interpreted as reverse-ordering diagnostics, not as evidence that central bank communication causes national climate policy or country-level readiness." ///
             "Model (4) adds L1(DV) to account for persistence." ///
             "The estimates are interpreted as Granger-style predictive associations rather than causal Granger tests." ///
             "*** p<0.01, ** p<0.05, * p<0.10.")


*------------------------------------------------------------*
* 7.4 Display completion message
*------------------------------------------------------------*

di as result "Table 4 saved to: $TABLE4.rtf"


*============================================================*
* BLOCK 8. Revised main-paper Table 5 and Figure 1
* Paris Agreement salience shock
*
* Main outputs:
*   Table 5: corrected collapsed DiD and event study
*   Figure 1:
*       Panel A. Absolute climate discourse by vulnerability group
*       Panel B. Differential event-study response
*
* Diagnostic outputs:
*   Treatment-classification verification
*   Pre/post descriptive decomposition
*   Raw-count group trends
*============================================================*

xtset id_iso3 year


*------------------------------------------------------------*
* 8.1 Reproduce submitted classification for diagnostics
*------------------------------------------------------------*

capture drop vuln_pre_old0 vuln_pre_old tercile_old high_vuln_old

bys id_iso3: egen double vuln_pre_old0 = ///
    mean(climate_vulnerability) if inrange(year, 2010, 2015)

bys id_iso3: egen double vuln_pre_old = max(vuln_pre_old0)

xtile tercile_old = vuln_pre_old, nq(3)

gen byte high_vuln_old = (tercile_old == 3)
label var high_vuln_old "Submitted high-vulnerability classification"


*------------------------------------------------------------*
* 8.2 Correct country-level pre-Paris vulnerability treatment
*
* Terciles are calculated using one observation per country.
* Missing treatment status remains missing.
*------------------------------------------------------------*

tempfile paris_groups

preserve

keep if inrange(year, 2010, 2015)
keep if !missing(climate_vulnerability)

collapse (mean) vuln_pre = climate_vulnerability, by(id_iso3)

xtile vuln_tercile = vuln_pre, nq(3)

gen byte high_vuln = (vuln_tercile == 3) if !missing(vuln_tercile)
gen double vuln_pre_100 = 100 * vuln_pre if !missing(vuln_pre)

capture label drop highv
label define highv 0 "Low/medium vulnerability" 1 "High vulnerability"
label values high_vuln highv

label var vuln_pre "Average climate vulnerability, 2010-2015"
label var vuln_pre_100 "Average climate vulnerability, 2010-2015, 0-100"
label var high_vuln "High vulnerability: top country tercile of 2010-2015 vulnerability"

save `paris_groups', replace

restore

merge m:1 id_iso3 using `paris_groups', keep(master match) nogen

capture drop post_paris did_paris
gen byte post_paris = (year >= 2016) if !missing(year)
gen byte did_paris = post_paris * high_vuln ///
    if !missing(post_paris, high_vuln)

label var post_paris "Post-Paris period, year >= 2016"
label var did_paris "Post-2016 x high vulnerability"


*------------------------------------------------------------*
* 8.3 Treatment-classification diagnostics
*------------------------------------------------------------*

egen byte tag_country = tag(id_iso3)

quietly count if tag_country & high_vuln == 1
local N_high_new = r(N)

quietly count if tag_country & high_vuln == 0
local N_comp_new = r(N)

quietly count if tag_country & missing(high_vuln)
local N_missing_new = r(N)

quietly count if tag_country & high_vuln_old == 1
local N_high_old = r(N)

quietly count if tag_country & high_vuln_old == 0
local N_comp_old = r(N)

quietly count if tag_country & !missing(high_vuln) ///
    & high_vuln_old != high_vuln
local N_changed = r(N)

putexcel set "$TREATCHECK.xlsx", replace sheet("Classification")
putexcel A1 = "Paris high-vulnerability classification verification", bold
putexcel A3 = "Diagnostic", bold
putexcel B3 = "Submitted coding", bold
putexcel C3 = "Corrected country-level coding", bold
putexcel A4 = "High-vulnerability countries"
putexcel B4 = `N_high_old'
putexcel C4 = `N_high_new'
putexcel A5 = "Low/medium-vulnerability countries"
putexcel B5 = `N_comp_old'
putexcel C5 = `N_comp_new'
putexcel A6 = "Countries with missing corrected treatment status"
putexcel C6 = `N_missing_new'
putexcel A7 = "Countries whose classification changes among valid corrected cases"
putexcel C7 = `N_changed'
putexcel A9 = "Note:", bold
putexcel B9 = "Corrected terciles are calculated on one observation per country using average 2010-2015 vulnerability; missing treatment status is preserved."

drop tag_country


*------------------------------------------------------------*
* 8.4 Event-time variables
*------------------------------------------------------------*

capture drop rel rel_shift

gen int rel = year - 2016
gen int rel_shift = rel + 10

capture label drop rel_lbl
label define rel_lbl ///
    4  "-6" ///
    5  "-5" ///
    6  "-4" ///
    7  "-3" ///
    8  "-2" ///
    9  "-1 baseline" ///
    10 "0" ///
    11 "+1" ///
    12 "+2" ///
    13 "+3" ///
    14 "+4" ///
    15 "+5" ///
    16 "+6" ///
    17 "+7" ///
    18 "+8"

label values rel_shift rel_lbl


*------------------------------------------------------------*
* 8.5 Corrected collapsed DiD and submitted-code comparison
*------------------------------------------------------------*

preserve

keep if inrange(rel, -6, 8)
keep if !missing(high_vuln)

xtreg $DV did_paris $CTRLS i.year, fe vce(cluster id_iso3)
estimates store PARIS_DID

gen byte paris_did_sample = e(sample)

local N_did  = e(N)
local Ng_did = e(N_g)
local r2_did : display %6.3f e(r2_w)

scalar b_did = _b[did_paris]
scalar se_did = _se[did_paris]
scalar p_did = 2 * ttail(e(df_r), abs(b_did / se_did))

local star_did ""
if p_did < 0.10 local star_did "*"
if p_did < 0.05 local star_did "**"
if p_did < 0.01 local star_did "***"

local b_did_s : display %9.3f b_did
local se_did_s : display %9.3f se_did
local did_cell "`b_did_s'`star_did' (`se_did_s')"

gen byte did_paris_old = post_paris * high_vuln_old if !missing(post_paris)

xtreg $DV did_paris_old $CTRLS i.year, fe vce(cluster id_iso3)
scalar b_did_old = _b[did_paris_old]
scalar se_did_old = _se[did_paris_old]
local N_did_old = e(N)
local Ng_did_old = e(N_g)

putexcel set "$TREATCHECK.xlsx", modify sheet("DiD comparison")
putexcel A1 = "Submitted versus corrected Paris collapsed DiD coding", bold
putexcel A3 = "Specification", bold
putexcel B3 = "Coefficient", bold
putexcel C3 = "SE", bold
putexcel D3 = "Observations", bold
putexcel E3 = "Countries", bold
putexcel A4 = "Submitted classification coding"
putexcel B4 = b_did_old
putexcel C4 = se_did_old
putexcel D4 = `N_did_old'
putexcel E4 = `Ng_did_old'
putexcel A5 = "Corrected country-level classification"
putexcel B5 = b_did
putexcel C5 = se_did
putexcel D5 = `N_did'
putexcel E5 = `Ng_did'
putexcel A7 = "Note:", bold
putexcel B7 = "The corrected specification determines vulnerability terciles on one observation per country and preserves missing treatment status."

estimates restore PARIS_DID

tempfile paris_sample_ids
keep id_iso3 year paris_did_sample
keep if paris_did_sample == 1
save `paris_sample_ids', replace

restore


*------------------------------------------------------------*
* 8.6 Corrected event study
*      Estimation window: t=-6 through t=+8
*      Reported coefficients: t=-6 through t=+7
*      Omitted period: t=-1
*------------------------------------------------------------*

preserve

keep if inrange(rel, -6, 8)
keep if !missing(high_vuln)

xtreg $DV ib9.rel_shift##i.high_vuln $CTRLS, ///
    fe vce(cluster id_iso3)

estimates store PARIS_ES

local N_es  = e(N)
local Ng_es = e(N_g)
local r2_es : display %6.3f e(r2_w)

testparm ///
    4.rel_shift#1.high_vuln ///
    5.rel_shift#1.high_vuln ///
    6.rel_shift#1.high_vuln ///
    7.rel_shift#1.high_vuln ///
    8.rel_shift#1.high_vuln

local pretrend_p : display %6.3f r(p)

di as result "Corrected Paris event-study joint pre-trends p-value = `pretrend_p'"

restore


*------------------------------------------------------------*
* 8.7 Export revised Table 5
*------------------------------------------------------------*

putexcel set "$TABLE5.xlsx", replace sheet("Table 5")

putexcel A1 = "Table 5. Paris Agreement and Climate Discourse: Event-Study and DiD", bold

putexcel A3 = "Panel A: Corrected collapsed DiD (Country FE + Year FE)", bold
putexcel A4 = "Variable", bold
putexcel B4 = "Model (1)", bold
putexcel A5 = "Post-2016 x High vulnerability"
putexcel B5 = "`did_cell'"
putexcel A7 = "Controls"
putexcel B7 = "Yes"
putexcel A8 = "Country FE"
putexcel B8 = "Yes"
putexcel A9 = "Year FE"
putexcel B9 = "Yes"
putexcel A10 = "Observations"
putexcel B10 = `N_did'
putexcel A11 = "Countries"
putexcel B11 = `Ng_did'
putexcel A12 = "Within R-squared"
putexcel B12 = "`r2_did'"
putexcel A13 = "SE clustering"
putexcel B13 = "Country"

putexcel A16 = "Panel B: Corrected event study", bold
putexcel A17 = "Event time (t)", bold
putexcel B17 = "High vulnerability x 1[t]", bold

local row = 18

estimates restore PARIS_ES

foreach r in -6 -5 -4 -3 -2 {

    local s = `r' + 10
    scalar b_es = _b[`s'.rel_shift#1.high_vuln]
    scalar se_es = _se[`s'.rel_shift#1.high_vuln]
    scalar p_es = 2 * ttail(e(df_r), abs(b_es / se_es))

    local star_es ""
    if p_es < 0.10 local star_es "*"
    if p_es < 0.05 local star_es "**"
    if p_es < 0.01 local star_es "***"

    local b_es_s : display %9.3f b_es
    local se_es_s : display %9.3f se_es
    local es_cell "`b_es_s'`star_es' (`se_es_s')"

    putexcel A`row' = "t = `r'"
    putexcel B`row' = "`es_cell'"

    local row = `row' + 1
}

putexcel A`row' = "t = -1 (baseline)"
putexcel B`row' = ""
local row = `row' + 1

foreach r in 0 1 2 3 4 5 6 7 {

    local s = `r' + 10
    scalar b_es = _b[`s'.rel_shift#1.high_vuln]
    scalar se_es = _se[`s'.rel_shift#1.high_vuln]
    scalar p_es = 2 * ttail(e(df_r), abs(b_es / se_es))

    local star_es ""
    if p_es < 0.10 local star_es "*"
    if p_es < 0.05 local star_es "**"
    if p_es < 0.01 local star_es "***"

    local b_es_s : display %9.3f b_es
    local se_es_s : display %9.3f se_es
    local es_cell "`b_es_s'`star_es' (`se_es_s')"

    if `r' == 0 {
        putexcel A`row' = "t = 0"
    }
    else {
        putexcel A`row' = "t = +`r'"
    }

    putexcel B`row' = "`es_cell'"
    local row = `row' + 1
}

local note_row = `row' + 2
putexcel A`note_row' = "Notes:", bold
putexcel B`note_row' = "High vulnerability is the top country tercile of average 2010-2015 vulnerability, calculated using one observation per country."

local note_row = `note_row' + 1
putexcel B`note_row' = "Panel A includes country and year fixed effects. Panel B uses country fixed effects and event-time effects, with t=-1 omitted."

local note_row = `note_row' + 1
putexcel B`note_row' = "All specifications include the baseline controls and country-clustered standard errors."

local note_row = `note_row' + 1
putexcel B`note_row' = "Joint pre-trends p-value = `pretrend_p'. *** p<0.01, ** p<0.05, * p<0.10."


*------------------------------------------------------------*
* 8.8 Figure 1, Panel A: absolute group trends
*------------------------------------------------------------*

preserve

merge 1:1 id_iso3 year using `paris_sample_ids', keep(match) nogen

keep if paris_did_sample == 1
keep if inrange(year, 2010, 2024)

collapse ///
    (mean) mean_ln_climate = ln_climate_sents ///
           mean_raw_climate = climate_sents_count ///
    (count) N_country_year = ln_climate_sents, ///
    by(year high_vuln)

export excel using "$WORKDIR/Paris_absolute_group_means.xlsx", ///
    firstrow(variables) replace

twoway ///
    (line mean_ln_climate year if high_vuln == 1, ///
        lpattern(solid) lwidth(medthick)) ///
    (line mean_ln_climate year if high_vuln == 0, ///
        lpattern(dash) lwidth(medthick)), ///
    xline(2016, lpattern(shortdash)) ///
    xlabel(2010(2)2024) ///
    xtitle("Year") ///
    ytitle("Mean ln(1 + climate-related sentences)") ///
    title("Panel A. Absolute climate discourse by vulnerability group") ///
    legend(order(1 "High vulnerability" 2 "Low/medium vulnerability") ///
           position(6) rows(1)) ///
    note("Group status is based on country-level average vulnerability during 2010-2015. The sample matches the corrected collapsed DiD estimation sample.") ///
    graphregion(color(white)) ///
    name(FIG1A_GRAPH, replace)

graph save "$WORKDIR/Figure_1A.gph", replace

restore


*------------------------------------------------------------*
* 8.9 Figure 1, Panel B: event-study differential
*------------------------------------------------------------*

preserve

clear
set obs 14

gen int rel = .
replace rel = -6 in 1
replace rel = -5 in 2
replace rel = -4 in 3
replace rel = -3 in 4
replace rel = -2 in 5
replace rel = -1 in 6
replace rel =  0 in 7
replace rel =  1 in 8
replace rel =  2 in 9
replace rel =  3 in 10
replace rel =  4 in 11
replace rel =  5 in 12
replace rel =  6 in 13
replace rel =  7 in 14

gen double coef = .
gen double se = .

estimates restore PARIS_ES

foreach r in -6 -5 -4 -3 -2 0 1 2 3 4 5 6 7 {

    local s = `r' + 10

    scalar b_plot = _b[`s'.rel_shift#1.high_vuln]
    scalar se_plot = _se[`s'.rel_shift#1.high_vuln]

    replace coef = b_plot if rel == `r'
    replace se = se_plot if rel == `r'
}

replace coef = 0 if rel == -1
replace se = 0 if rel == -1

gen double lb = coef - 1.96 * se
gen double ub = coef + 1.96 * se

twoway ///
    (rcap ub lb rel) ///
    (connected coef rel, msymbol(O)), ///
    xline(0, lpattern(shortdash)) ///
    yline(0, lpattern(shortdash)) ///
    xlabel(-6(1)7) ///
    xtitle("Event time relative to Paris Agreement, 2016") ///
    ytitle("High vulnerability x event-time coefficient") ///
    title("Panel B. Differential climate-discourse response") ///
    legend(order(2 "Estimate" 1 "95% confidence interval") ///
           position(6) rows(1)) ///
    note("Base period is t=-1. Whiskers report 95% confidence intervals.") ///
    graphregion(color(white)) ///
    name(FIG1B_GRAPH, replace)

graph save "$WORKDIR/Figure_1B.gph", replace

restore


*------------------------------------------------------------*
* 8.10 Combine revised Figure 1
*------------------------------------------------------------*

capture graph drop FIG1A_RELOAD
capture graph drop FIG1B_RELOAD

graph use "$WORKDIR/Figure_1A.gph", name(FIG1A_RELOAD, replace)
graph use "$WORKDIR/Figure_1B.gph", name(FIG1B_RELOAD, replace)

graph combine FIG1A_RELOAD FIG1B_RELOAD, ///
    cols(2) ///
    imargin(small) ///
    graphregion(color(white)) ///
    title("Climate discourse around the Paris Agreement")

graph export "$FIGURE1.png", replace width(2800)
graph export "$FIGURE1.pdf", replace
graph save "$FIGURE1.gph", replace


*------------------------------------------------------------*
* 8.11 Diagnostic raw-count plot
*------------------------------------------------------------*

preserve

merge 1:1 id_iso3 year using `paris_sample_ids', keep(match) nogen
keep if paris_did_sample == 1
keep if inrange(year, 2010, 2024)

collapse (mean) mean_raw_climate = climate_sents_count, ///
    by(year high_vuln)

twoway ///
    (line mean_raw_climate year if high_vuln == 1, ///
        lpattern(solid) lwidth(medthick)) ///
    (line mean_raw_climate year if high_vuln == 0, ///
        lpattern(dash) lwidth(medthick)), ///
    xline(2016, lpattern(shortdash)) ///
    xlabel(2010(2)2024) ///
    xtitle("Year") ///
    ytitle("Mean climate-related sentence count") ///
    title("Absolute climate discourse by vulnerability group: raw count") ///
    legend(order(1 "High vulnerability" 2 "Low/medium vulnerability") ///
           position(6) rows(1)) ///
    graphregion(color(white))

graph export "$DIAGDIR/Paris_absolute_group_trends_raw_count.png", ///
    replace width(2400)

restore


*------------------------------------------------------------*
* 8.12 Diagnostic pre/post decomposition
*------------------------------------------------------------*

preserve

merge 1:1 id_iso3 year using `paris_sample_ids', keep(match) nogen

keep if paris_did_sample == 1
keep if inrange(year, 2010, 2024)

quietly summarize ln_climate_sents if high_vuln == 1 & post_paris == 0
scalar H_pre_log = r(mean)
local H_pre_n = r(N)

quietly summarize ln_climate_sents if high_vuln == 1 & post_paris == 1
scalar H_post_log = r(mean)
local H_post_n = r(N)

quietly summarize ln_climate_sents if high_vuln == 0 & post_paris == 0
scalar C_pre_log = r(mean)
local C_pre_n = r(N)

quietly summarize ln_climate_sents if high_vuln == 0 & post_paris == 1
scalar C_post_log = r(mean)
local C_post_n = r(N)

scalar H_change_log = H_post_log - H_pre_log
scalar C_change_log = C_post_log - C_pre_log
scalar DD_desc_log = H_change_log - C_change_log

quietly summarize climate_sents_count if high_vuln == 1 & post_paris == 0
scalar H_pre_raw = r(mean)

quietly summarize climate_sents_count if high_vuln == 1 & post_paris == 1
scalar H_post_raw = r(mean)

quietly summarize climate_sents_count if high_vuln == 0 & post_paris == 0
scalar C_pre_raw = r(mean)

quietly summarize climate_sents_count if high_vuln == 0 & post_paris == 1
scalar C_post_raw = r(mean)

scalar H_change_raw = H_post_raw - H_pre_raw
scalar C_change_raw = C_post_raw - C_pre_raw
scalar DD_desc_raw = H_change_raw - C_change_raw

putexcel set "$PREPOST.xlsx", replace sheet("Decomposition")
putexcel A1 = "Paris Agreement: descriptive pre/post decomposition by vulnerability group", bold

putexcel A3 = "Panel A. ln(1 + climate-related sentences)", bold
putexcel A4 = "Group", bold
putexcel B4 = "Pre-Paris mean", bold
putexcel C4 = "Post-Paris mean", bold
putexcel D4 = "Within-group change", bold
putexcel E4 = "Pre N", bold
putexcel F4 = "Post N", bold

putexcel A5 = "High vulnerability"
putexcel B5 = H_pre_log
putexcel C5 = H_post_log
putexcel D5 = H_change_log
putexcel E5 = `H_pre_n'
putexcel F5 = `H_post_n'

putexcel A6 = "Low/medium vulnerability"
putexcel B6 = C_pre_log
putexcel C6 = C_post_log
putexcel D6 = C_change_log
putexcel E6 = `C_pre_n'
putexcel F6 = `C_post_n'

putexcel A7 = "Difference in changes: high minus low/medium"
putexcel D7 = DD_desc_log

putexcel A10 = "Panel B. Raw climate-related sentence count", bold
putexcel A11 = "Group", bold
putexcel B11 = "Pre-Paris mean", bold
putexcel C11 = "Post-Paris mean", bold
putexcel D11 = "Within-group change", bold

putexcel A12 = "High vulnerability"
putexcel B12 = H_pre_raw
putexcel C12 = H_post_raw
putexcel D12 = H_change_raw

putexcel A13 = "Low/medium vulnerability"
putexcel B13 = C_pre_raw
putexcel C13 = C_post_raw
putexcel D13 = C_change_raw

putexcel A14 = "Difference in changes: high minus low/medium"
putexcel D14 = DD_desc_raw

putexcel A17 = "Note:", bold
putexcel B17 = "These are unadjusted group means on the corrected collapsed DiD estimation sample; the regression-adjusted DiD remains the inferential specification."

restore

di as result "Revised Table 5 saved to: $TABLE5.xlsx"
di as result "Revised Figure 1 saved to: $FIGURE1.png and $FIGURE1.pdf"

*============================================================*
* BLOCK 9. Appendix Figure A1
* Total central bank communication and climate-related discourse
*
* Combined outputs:
*   results/appendix/figures/Figure_A1_descriptive_communication_trends.png
*   results/appendix/figures/Figure_A1_descriptive_communication_trends.svg
*   results/appendix/figures/Figure_A1_descriptive_communication_trends.gph
*============================================================*

*------------------------------------------------------------*
* 9.0 Graph settings
*------------------------------------------------------------*

set scheme s1color

capture graph drop FigA1_Panel_A FigA1_Panel_B FigA1_Panel_C FigA1_Panel_D Figure_A1


*============================================================*
* Panel A. Annual total speeches and climate-related speeches
*============================================================*

preserve

keep if inrange(year, 1996, 2024)

collapse ///
    (sum) total_speeches_count climate_speeches_count, ///
    by(year)

sort year

twoway ///
    (line total_speeches_count year, ///
        yaxis(1) lcolor(dkgreen) lwidth(medthin)) ///
    (line climate_speeches_count year, ///
        yaxis(2) lcolor(orange_red) lwidth(medthin)), ///
    title("Annual Central Bank Speeches and Climate-Related Speeches", size(small)) ///
    xtitle("Year", size(vsmall)) ///
    ytitle("Total speeches", axis(1) size(vsmall)) ///
    ytitle("Climate-related speeches", axis(2) size(vsmall)) ///
    xlabel(1996(4)2024, angle(45) labsize(vsmall)) ///
    ylabel(, axis(1) labsize(vsmall)) ///
    ylabel(, axis(2) labsize(vsmall)) ///
    xscale(range(1996 2024) noextend) ///
    legend(order(1 "Total speeches" 2 "Climate-related speeches") ///
           position(6) rows(1) size(tiny)) ///
    caption("{bf:Panel A}", size(medsmall)) ///
    graphregion(color(white) lcolor(black) lwidth(vthin)) ///
    plotregion(color(white)) ///
    name(FigA1_Panel_A, replace) ///
    nodraw

restore


*============================================================*
* Panel B. Annual total sentences and climate-related sentences
*============================================================*

preserve

keep if inrange(year, 1996, 2024)

collapse ///
    (sum) total_sents_count climate_sents_count, ///
    by(year)

sort year

twoway ///
    (line total_sents_count year, ///
        yaxis(1) lcolor(dkgreen) lwidth(medthin)) ///
    (line climate_sents_count year, ///
        yaxis(2) lcolor(orange_red) lwidth(medthin)), ///
    title("Annual Total Sentences and Climate-Related Sentences", size(small)) ///
    xtitle("Year", size(vsmall)) ///
    ytitle("Total speech sentences", axis(1) size(vsmall)) ///
    ytitle("Climate-related sentences", axis(2) size(vsmall)) ///
    xlabel(1996(4)2024, angle(45) labsize(vsmall)) ///
    ylabel(, axis(1) labsize(vsmall)) ///
    ylabel(, axis(2) labsize(vsmall)) ///
    xscale(range(1996 2024) noextend) ///
    legend(order(1 "Total sentences" 2 "Climate-related sentences") ///
           position(6) rows(1) size(tiny)) ///
    caption("{bf:Panel B}", size(medsmall)) ///
    graphregion(color(white) lcolor(black) lwidth(vthin)) ///
    plotregion(color(white)) ///
    name(FigA1_Panel_B, replace) ///
    nodraw

restore


*============================================================*
* Panel C. Annual climate share of central bank communication
*============================================================*

preserve

keep if inrange(year, 1996, 2024)

collapse ///
    (sum) total_sents_count climate_sents_count ///
          total_speeches_count climate_speeches_count, ///
    by(year)

gen climate_sentence_share_annual = 100 * climate_sents_count / total_sents_count ///
    if total_sents_count > 0

gen climate_speech_share_annual = 100 * climate_speeches_count / total_speeches_count ///
    if total_speeches_count > 0

sort year

twoway ///
    (line climate_sentence_share_annual year, ///
        lcolor(dkgreen) lwidth(medthin)) ///
    (line climate_speech_share_annual year, ///
        lcolor(orange_red) lwidth(medthin)), ///
    title("Annual Climate Share of Central Bank Communication", size(small)) ///
    xtitle("Year", size(vsmall)) ///
    ytitle("Percent", size(vsmall)) ///
    xlabel(1996(4)2024, angle(45) labsize(vsmall)) ///
    ylabel(, labsize(vsmall)) ///
    xscale(range(1996 2024) noextend) ///
    legend(order(1 "Climate sentences / total sentences" ///
                 2 "Climate speeches / total speeches") ///
           position(6) rows(2) size(tiny)) ///
    caption("{bf:Panel C}", size(medsmall)) ///
    graphregion(color(white) lcolor(black) lwidth(vthin)) ///
    plotregion(color(white)) ///
    name(FigA1_Panel_C, replace) ///
    nodraw

restore


*============================================================*
* Panel D. Climate discourse and total communication volume
*============================================================*

preserve

keep if inrange(year, 1996, 2024)

capture drop ln_total_sents
gen ln_total_sents = ln(1 + total_sents_count) if !missing(total_sents_count)

label var ln_total_sents "ln(1 + total speech sentences)"

twoway ///
    (scatter ln_climate_sents ln_total_sents, ///
        msize(vsmall) mcolor(dkgreen)) ///
    (lfit ln_climate_sents ln_total_sents, ///
        lcolor(orange_red) lwidth(medthin)), ///
    title("Climate Discourse and Total Communication Volume", size(small)) ///
    xtitle("ln(1 + total speech sentences)", size(vsmall)) ///
    ytitle("ln(1 + climate-related sentences)", size(vsmall)) ///
    xlabel(, labsize(vsmall)) ///
    ylabel(, labsize(vsmall)) ///
    legend(order(1 "Country-year observations" 2 "Linear fit") ///
           position(6) rows(1) size(tiny)) ///
    caption("{bf:Panel D}", size(medsmall)) ///
    graphregion(color(white) lcolor(black) lwidth(vthin)) ///
    plotregion(color(white)) ///
    name(FigA1_Panel_D, replace) ///
    nodraw

restore


*============================================================*
* 9.1 Combine four panels into one appendix figure
*============================================================*

graph combine ///
    FigA1_Panel_A FigA1_Panel_B ///
    FigA1_Panel_C FigA1_Panel_D, ///
    cols(2) ///
    imargin(tiny) ///
    graphregion(color(white) lcolor(black) lwidth(vthin)) ///
    xsize(8.5) ///
    ysize(6.8) ///
    iscale(0.85) ///
    name(Figure_A1, replace)

graph save   "${FIGA1}.gph", replace
graph export "${FIGA1}.png", replace width(4800)
graph export "${FIGA1}.svg", replace

di as result "Appendix Figure A1 saved as PNG, SVG, and Stata GPH in: ${APPFIG}"

*============================================================*
* BLOCK 10. Appendix Table A1
* Year-level central bank communication and climate-related discourse
*
* Period:
*   1996-2024
*
* Outputs:
*   results/appendix/tables/Table_A1_year_level_descriptives.xlsx
*   results/appendix/tables/Table_A1_year_level_descriptives.csv
*============================================================*

*------------------------------------------------------------*
* 10.0 Create annual descriptive table
*------------------------------------------------------------*

preserve

keep if inrange(year, 1996, 2024)

collapse ///
    (sum) total_speeches_count ///
          climate_speeches_count ///
          climate_sents_count ///
          total_sents_count, ///
    by(year)

gen climate_speech_share = 100 * climate_speeches_count / total_speeches_count ///
    if total_speeches_count > 0

gen climate_sentence_share = 100 * climate_sents_count / total_sents_count ///
    if total_sents_count > 0

gen year_label = string(year)

tempfile annual_table
save `annual_table', replace

restore


*------------------------------------------------------------*
* 10.1 Create total row
*------------------------------------------------------------*

preserve

keep if inrange(year, 1996, 2024)

collapse ///
    (sum) total_speeches_count ///
          climate_speeches_count ///
          climate_sents_count ///
          total_sents_count

gen climate_speech_share = 100 * climate_speeches_count / total_speeches_count ///
    if total_speeches_count > 0

gen climate_sentence_share = 100 * climate_sents_count / total_sents_count ///
    if total_sents_count > 0

gen year = .
gen year_label = "Total"

tempfile total_row
save `total_row', replace

restore


*------------------------------------------------------------*
* 10.2 Combine annual table and total row
*------------------------------------------------------------*

preserve

use `annual_table', clear
append using `total_row'

gen sort_order = year
replace sort_order = 9999 if year_label == "Total"

sort sort_order

drop sort_order

label variable year_label              "Year"
label variable total_speeches_count    "Total speeches"
label variable climate_speeches_count  "Climate-related speeches"
label variable climate_sents_count     "Climate-related sentences"
label variable climate_speech_share    "Climate speech share (%)"
label variable climate_sentence_share  "Climate sentence share (%)"

format total_speeches_count climate_speeches_count climate_sents_count %12.0fc
format climate_speech_share climate_sentence_share %9.2f

order year_label total_speeches_count climate_speeches_count ///
      climate_sents_count climate_speech_share climate_sentence_share


*------------------------------------------------------------*
* 10.3 Display table in Stata
*------------------------------------------------------------*

list year_label total_speeches_count climate_speeches_count ///
     climate_sents_count climate_speech_share climate_sentence_share, ///
     noobs abbreviate(24)


*------------------------------------------------------------*
* 10.4 Save as CSV
*------------------------------------------------------------*

export delimited ///
    year_label total_speeches_count climate_speeches_count ///
    climate_sents_count climate_speech_share climate_sentence_share ///
    using "${TABLEA1}.csv", ///
    replace


*------------------------------------------------------------*
* 10.5 Save as formatted Excel table
*------------------------------------------------------------*

putexcel set "${TABLEA1}.xlsx", replace sheet("Table A1")

putexcel A1 = "Table A1. Year-level central bank communication and climate-related discourse, 1996-2024", bold

putexcel A3 = "Year", bold
putexcel B3 = "Total speeches", bold
putexcel C3 = "Climate-related speeches", bold
putexcel D3 = "Climate-related sentences", bold
putexcel E3 = "Climate speech share (%)", bold
putexcel F3 = "Climate sentence share (%)", bold

local n = _N

forvalues i = 1/`n' {
    
    local r = `i' + 3
    
    local yr = year_label[`i']
    
    putexcel A`r' = ("`yr'")
    putexcel B`r' = (total_speeches_count[`i']), nformat("#,##0")
    putexcel C`r' = (climate_speeches_count[`i']), nformat("#,##0")
    putexcel D`r' = (climate_sents_count[`i']), nformat("#,##0")
    putexcel E`r' = (climate_speech_share[`i']), nformat("0.00")
    putexcel F`r' = (climate_sentence_share[`i']), nformat("0.00")
}

local note_row = `n' + 6

putexcel A`note_row' = "Note:", bold
putexcel B`note_row' = "The table reports annual totals over 1996-2024. Climate-related speeches are speeches containing at least one climate-related sentence. Climate speech share is calculated as climate-related speeches divided by total speeches. Climate sentence share is calculated as climate-related sentences divided by total speech sentences. The final row reports totals over the full sample period; percentage shares in the total row are calculated from aggregate totals."


*------------------------------------------------------------*
* 10.6 Restore main dataset and completion message
*------------------------------------------------------------*

restore

di as result "Appendix Table A1 saved to: ${TABLEA1}.xlsx"
di as result "Appendix Table A1 CSV saved to: ${TABLEA1}.csv"

*============================================================*
* BLOCK 11. Appendix Table A2
* Robustness to missing covariates:
* TWFE and Poisson FE with MI-RHS
*
* Output:
*   results/appendix/tables/Table_A2_missing_covariates_MI.rtf
*
* Notes:
*   - RHS covariates only are multiply imputed.
*   - Dependent variables are not imputed.
*   - MI uses chained equations with predictive mean matching.
*   - 20 imputations, k = 5 nearest neighbours.
*============================================================*

* Required packages are checked centrally in Block 4.


*------------------------------------------------------------*
* 11.1 Safety reset before MI
*------------------------------------------------------------*

capture restore
capture stset, clear
capture mi unset


*------------------------------------------------------------*
* 11.2 Preserve clean non-MI dataset
*------------------------------------------------------------*

preserve

xtset id_iso3 year

capture stset, clear
capture mi unset


*------------------------------------------------------------*
* 11.3 Count countries for table reporting
*------------------------------------------------------------*

quietly levelsof id_iso3, local(country_ids)
local N_countries : word count `country_ids'


*------------------------------------------------------------*
* 11.4 MI setup: impute RHS variables only
*------------------------------------------------------------*

mi set mlong

mi register regular ///
    id_iso3 year ///
    ln_climate_sents climate_sents_count

mi register imputed ///
    vuln_100 ready_100 ln_policy_count ///
    ln_gdp_pc asinh_inflation credit_banks_gdp ///
    wgi_score ln1p_co2_pc fuel_exports_share


*------------------------------------------------------------*
* 11.5 Imputation model
*      DV included as predictor but not imputed
*------------------------------------------------------------*

mi impute chained ///
    (pmm, knn(5)) vuln_100 ready_100 ln_policy_count ///
                  ln_gdp_pc asinh_inflation credit_banks_gdp ///
                  wgi_score ln1p_co2_pc fuel_exports_share ///
    = ln_climate_sents i.year i.id_iso3, ///
    add(20) rseed(12345)


*------------------------------------------------------------*
* 11.6 Estimate MI robustness models
*------------------------------------------------------------*

eststo clear


* Model (1): TWFE linear model on log-transformed outcome
mi estimate, post vceok: ///
    xtreg ln_climate_sents ///
        vuln_100 ready_100 ln_policy_count ///
        ln_gdp_pc asinh_inflation credit_banks_gdp ///
        wgi_score ln1p_co2_pc fuel_exports_share ///
        i.year, fe vce(cluster id_iso3)

estadd scalar Countries = `N_countries'
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local Estimator "Within (linear FE)"
estadd local Imputation "MI (20), PMM"

eststo A2_M1_TWFE_MI


* Model (2): Conditional FE Poisson model on sentence-count outcome
mi estimate, post vceok: ///
    xtpoisson climate_sents_count ///
        vuln_100 ready_100 ln_policy_count ///
        ln_gdp_pc asinh_inflation credit_banks_gdp ///
        wgi_score ln1p_co2_pc fuel_exports_share ///
        i.year, fe vce(robust)

estadd scalar Countries = `N_countries'
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local Estimator "Conditional FE Poisson"
estadd local Imputation "MI (20), PMM"

eststo A2_M2_Poisson_MI


*------------------------------------------------------------*
* 11.7 Export Appendix Table A2
*------------------------------------------------------------*

esttab A2_M1_TWFE_MI A2_M2_Poisson_MI ///
    using "$TABLEA2.rtf", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("TWFE (Linear FE)" "Poisson FE") ///
    drop(*.year) ///
    order(vuln_100 ready_100 ln_policy_count ///
          ln_gdp_pc asinh_inflation credit_banks_gdp ///
          wgi_score ln1p_co2_pc fuel_exports_share _cons) ///
    coeflabels( ///
          vuln_100 "Climate vulnerability" ///
          ready_100 "Climate readiness" ///
          ln_policy_count "Climate policy intensity" ///
          ln_gdp_pc "GDP per capita" ///
          asinh_inflation "Inflation" ///
          credit_banks_gdp "Private credit (% GDP)" ///
          wgi_score "Institutional quality" ///
          ln1p_co2_pc "CO2 emissions per capita" ///
          fuel_exports_share "Fuel exports (% exports)" ///
          _cons "Constant") ///
    stats(N Countries CountryFE YearFE Estimator Imputation, ///
          labels("Observations" ///
                 "Countries" ///
                 "Country fixed effects" ///
                 "Year fixed effects" ///
                 "Estimator" ///
                 "Imputation") ///
          fmt(0 0 s s s s)) ///
    title("Table A2. Robustness to missing covariates: TWFE and Poisson FE with MI-RHS") ///
    addnotes("Standard errors are in parentheses." ///
             "RHS covariates are multiply imputed using chained equations with predictive mean matching, k = 5, and 20 imputations." ///
             "The dependent variable is not imputed." ///
             "The imputation model includes country and year indicators and the observed dependent variable." ///
             "Model (1) estimates a two-way fixed-effects model using the log-transformed climate-discourse outcome." ///
             "Model (2) estimates a conditional fixed-effects Poisson model using the climate sentence-count outcome." ///
             "Both specifications include country and year fixed effects." ///
             "*** p<0.01, ** p<0.05, * p<0.10.")


*------------------------------------------------------------*
* 11.8 Restore original non-MI dataset
*------------------------------------------------------------*

restore

xtset id_iso3 year

di as result "Appendix Table A2 saved to: $TABLEA2.rtf"

*============================================================*
* BLOCK 12. Appendix Table A3
* Count-model robustness:
* Poisson fixed-effects estimates
*
* Outputs:
*   results/appendix/tables/Table_A3_poisson_FE_count_model.rtf
*============================================================*



*------------------------------------------------------------*
* 12.1 Panel declaration
*------------------------------------------------------------*

xtset id_iso3 year


*------------------------------------------------------------*
* 12.2 Estimate Poisson FE models
*------------------------------------------------------------*


xtset id_iso3 year

eststo clear

* Model (1): Poisson FE with contemporaneous explanatory variables
xtpoisson climate_sents_count $IVS $CTRLS i.year, fe

estadd local YearFE "Yes"
estadd local CountryFE "Yes"
estadd local LaggedX "No"

eststo A3_M1_Poisson_FE


* Model (2): Poisson FE with lagged explanatory variables, t-1
xtpoisson climate_sents_count L1.($IVS) $CTRLS i.year, fe

estadd local YearFE "Yes"
estadd local CountryFE "Yes"
estadd local LaggedX "Included"

eststo A3_M2_Poisson_FE_L1


*------------------------------------------------------------*
* 12.3 Export Appendix Table A3
*------------------------------------------------------------*

esttab A3_M1_Poisson_FE A3_M2_Poisson_FE_L1 ///
    using "$TABLEA3.rtf", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Poisson FE + Year FE" ///
            "Poisson FE + Year FE, lagged explanatory variables (t-1)") ///
    keep(vuln_100 ready_100 ln_policy_count ///
         L.vuln_100 L.ready_100 L.ln_policy_count ///
         ln_gdp_pc asinh_inflation credit_banks_gdp wgi_score ///
         ln1p_co2_pc fuel_exports_share) ///
    order(vuln_100 L.vuln_100 ///
          ready_100 L.ready_100 ///
          ln_policy_count L.ln_policy_count ///
          ln_gdp_pc asinh_inflation credit_banks_gdp wgi_score ///
          ln1p_co2_pc fuel_exports_share) ///
    coeflabels( ///
          vuln_100 "Climate vulnerability" ///
          L.vuln_100 "Climate vulnerability" ///
          ready_100 "Climate readiness" ///
          L.ready_100 "Climate readiness" ///
          ln_policy_count "Climate policy intensity" ///
          L.ln_policy_count "Climate policy intensity" ///
          ln_gdp_pc "GDP per capita" ///
          asinh_inflation "Inflation" ///
          credit_banks_gdp "Private credit (% GDP)" ///
          wgi_score "Institutional quality (WGI)" ///
          ln1p_co2_pc "CO2 emissions per capita" ///
          fuel_exports_share "Fuel exports (% exports)") ///
    stats(LaggedX YearFE CountryFE N N_g, ///
          labels("Lagged climate vulnerability/readiness/policy intensity" ///
                 "Year fixed effects" ///
                 "Country fixed effects" ///
                 "Observations" ///
                 "Countries") ///
          fmt(s s s 0 0)) ///
    title("Table A3. Count-model robustness: Poisson fixed-effects estimates") ///
    addnotes("Robust standard errors are in parentheses." ///
             "The dependent variable is the climate discourse sentence count." ///
             "Poisson fixed-effects models include year fixed effects." ///
             "Model (2) lags the main explanatory variables by one year." ///
             "Coefficients are semi-elasticities in the conditional mean." ///
             "*** p<0.01, ** p<0.05, * p<0.10.")


*------------------------------------------------------------*
* 12.4 Display completion message
*------------------------------------------------------------*

di as result "Appendix Table A3 saved to: $TABLEA3.rtf"

*============================================================*
* BLOCK 13. Appendix Table A4
* Interrelations among the main explanatory variables
*
* Output:
*   results/appendix/tables/Table_A4_main_explanatory_variable_correlations.xlsx
*============================================================*

*------------------------------------------------------------*
* 13.0 Section-specific variables
*------------------------------------------------------------*

local MAINX "vuln_100 ready_100 ln_policy_count"

xtset id_iso3 year


*------------------------------------------------------------*
* 13.1 Pooled correlations
*      Complete-case estimation sample
*------------------------------------------------------------*

preserve

egen __miss_a4 = rowmiss($DV `MAINX' $CTRLS)
keep if __miss_a4 == 0
drop __miss_a4

quietly corr vuln_100 ready_100
scalar pooled_vr = r(rho)

quietly corr vuln_100 ln_policy_count
scalar pooled_vp = r(rho)

quietly corr ready_100 ln_policy_count
scalar pooled_rp = r(rho)

restore


*------------------------------------------------------------*
* 13.2 Between-country correlations
*      Country-level means
*------------------------------------------------------------*

preserve

egen __miss_a4 = rowmiss($DV `MAINX' $CTRLS)
keep if __miss_a4 == 0
drop __miss_a4

collapse ///
    (mean) vuln_100 ready_100 ln_policy_count, ///
    by(id_iso3)

quietly corr vuln_100 ready_100
scalar between_vr = r(rho)

quietly corr vuln_100 ln_policy_count
scalar between_vp = r(rho)

quietly corr ready_100 ln_policy_count
scalar between_rp = r(rho)

restore


*------------------------------------------------------------*
* 13.3 Within-panel correlations
*      Residualized after removing country and year effects
*------------------------------------------------------------*

preserve

egen __miss_a4 = rowmiss($DV `MAINX' $CTRLS)
keep if __miss_a4 == 0
drop __miss_a4

capture drop r_vuln_100 r_ready_100 r_ln_policy_count

foreach v of local MAINX {
    quietly regress `v' i.id_iso3 i.year
    predict double r_`v', resid
}

quietly corr r_vuln_100 r_ready_100
scalar within_vr = r(rho)

quietly corr r_vuln_100 r_ln_policy_count
scalar within_vp = r(rho)

quietly corr r_ready_100 r_ln_policy_count
scalar within_rp = r(rho)


*------------------------------------------------------------*
* 13.4 Residualized VIF
*      VIFs computed using within-residualized explanatory variables
*------------------------------------------------------------*

quietly regress r_vuln_100 r_ready_100 r_ln_policy_count
scalar vif_vuln = 1 / (1 - e(r2))

quietly regress r_ready_100 r_vuln_100 r_ln_policy_count
scalar vif_ready = 1 / (1 - e(r2))

quietly regress r_ln_policy_count r_vuln_100 r_ready_100
scalar vif_policy = 1 / (1 - e(r2))

scalar residualized_vif = max(vif_vuln, vif_ready, vif_policy)

restore


*------------------------------------------------------------*
* 13.5 Export Appendix Table A4
*------------------------------------------------------------*

putexcel set "$TABLEA4.xlsx", replace sheet("Table A4")

putexcel A1 = "Table A4. Interrelations among the main explanatory variables", bold

putexcel A3 = "Correlation type", bold
putexcel B3 = "Vulnerability-Readiness", bold
putexcel C3 = "Vulnerability-Policy intensity", bold
putexcel D3 = "Readiness-Policy intensity", bold

putexcel A4 = "Pooled correlation"
putexcel B4 = (pooled_vr), nformat("0.000")
putexcel C4 = (pooled_vp), nformat("0.000")
putexcel D4 = (pooled_rp), nformat("0.000")

putexcel A5 = "Between-country correlation"
putexcel B5 = (between_vr), nformat("0.000")
putexcel C5 = (between_vp), nformat("0.000")
putexcel D5 = (between_rp), nformat("0.000")

putexcel A6 = "Within-panel correlation"
putexcel B6 = (within_vr), nformat("0.000")
putexcel C6 = (within_vp), nformat("0.000")
putexcel D6 = (within_rp), nformat("0.000")

putexcel A9 = "Notes.", bold
putexcel B9 = "Pooled correlations are based on the complete-case estimation sample. Between-country correlations are calculated using country-level means. Within-panel correlations are calculated after removing country and year effects from each explanatory variable."

putexcel B10 = "The maximum residualized VIF is:"
putexcel C10 = (residualized_vif), nformat("0.00")

putexcel B11 = "A residualized VIF close to 1 indicates no meaningful multicollinearity in the within-panel identifying variation."

di as result "Appendix Table A4 saved to: $TABLEA4.xlsx"

*============================================================*
* BLOCK 14. Appendix Table A5
* Alternative and simultaneous specifications
* of the main explanatory variables
*
* Output:
*   results/appendix/tables/Table_A5_alternative_joint_specifications.rtf
*============================================================*

xtset id_iso3 year


*------------------------------------------------------------*
* 14.1 Estimate alternative and joint specifications
*------------------------------------------------------------*

eststo clear


* Model (1): Vulnerability only
xtreg $DV vuln_100 $CTRLS i.year, fe vce(cluster id_iso3)

estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"

eststo A5_M1_Vulnerability


* Model (2): Readiness only
xtreg $DV ready_100 $CTRLS i.year, fe vce(cluster id_iso3)

estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"

eststo A5_M2_Readiness


* Model (3): Policy only
xtreg $DV ln_policy_count $CTRLS i.year, fe vce(cluster id_iso3)

estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"

eststo A5_M3_Policy


* Model (4): Joint model
xtreg $DV vuln_100 ready_100 ln_policy_count $CTRLS i.year, fe vce(cluster id_iso3)

estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"

eststo A5_M4_Joint


*------------------------------------------------------------*
* 14.2 Export Appendix Table A5
*------------------------------------------------------------*

esttab A5_M1_Vulnerability A5_M2_Readiness A5_M3_Policy A5_M4_Joint ///
    using "$TABLEA5.rtf", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Vulnerability only" "Readiness only" "Policy only" "Joint model") ///
    keep(vuln_100 ready_100 ln_policy_count) ///
    order(vuln_100 ready_100 ln_policy_count) ///
    coeflabels( ///
          vuln_100 "Climate vulnerability" ///
          ready_100 "Climate readiness" ///
          ln_policy_count "Climate policy intensity") ///
    stats(Controls CountryFE YearFE ClusterSE N N_g r2_w, ///
          labels("Baseline controls" ///
                 "Country fixed effects" ///
                 "Year fixed effects" ///
                 "Country-clustered SE" ///
                 "Observations" ///
                 "Countries" ///
                 "Within R-squared") ///
          fmt(s s s s 0 0 3)) ///
    title("Table A5. Alternative and simultaneous specifications of the main explanatory variables") ///
    addnotes("The dependent variable is climate discourse, measured as ln(1 + climate-related central bank speech sentences)." ///
             "Baseline controls include GDP per capita, inflation, private credit, institutional quality, CO2 emissions per capita, and fuel exports." ///
             "Standard errors clustered by country are reported in parentheses." ///
             "*** p<0.01, ** p<0.05, * p<0.10.")

di as result "Appendix Table A5 saved to: $TABLEA5.rtf"


*============================================================*
* BLOCK 15. Revised Appendix Table A6
* Central bank independence, reporting/disclosure, and heterogeneity
*
* Panel A:
*   Existing CBI/reporting robustness on a common complete-case sample
*
* Panel B:
*   CBI x vulnerability
*   CBI x readiness
*   CBI x policy intensity
*   Lagged CBI sensitivity
*
* Diagnostic outputs:
*   CBI within/between variation
*   Marginal effect of CBI across vulnerability percentiles
*============================================================*

xtset id_iso3 year


*------------------------------------------------------------*
* 15.1 Common CBI/reporting sample and diagnostics
*------------------------------------------------------------*

preserve

egen __miss_cbi = rowmiss($DV $IVS $CTRLS cbi_index cb_reporting)
keep if __miss_cbi == 0
drop __miss_cbi

xtset id_iso3 year

quietly xtsum cbi_index

scalar CBI_mean = r(mean)
scalar CBI_sd_pooled = r(sd)
scalar CBI_sd_between = r(sd_b)
scalar CBI_sd_within = r(sd_w)
scalar CBI_min = r(min)
scalar CBI_max = r(max)

bys id_iso3: egen double cbi_min_country = min(cbi_index)
bys id_iso3: egen double cbi_max_country = max(cbi_index)
egen byte tag_cbi_country = tag(id_iso3)

quietly count if tag_cbi_country
local CBI_countries = r(N)

quietly count if tag_cbi_country ///
    & cbi_max_country > cbi_min_country + 1e-10
local CBI_countries_change = r(N)

sort id_iso3 year
capture drop cbi_change
gen byte cbi_change = ///
    abs(cbi_index - L.cbi_index) > 1e-10 ///
    if id_iso3 == L.id_iso3 ///
    & !missing(cbi_index, L.cbi_index)

quietly count if cbi_change == 1
local CBI_change_obs = r(N)

putexcel set "$CBIDIAG.xlsx", replace sheet("CBI diagnostics")
putexcel A1 = "Central bank independence: within/between variation diagnostics", bold
putexcel A3 = "Statistic", bold
putexcel B3 = "Value", bold
putexcel A4 = "Mean"
putexcel B4 = CBI_mean
putexcel A5 = "Pooled standard deviation"
putexcel B5 = CBI_sd_pooled
putexcel A6 = "Between-country standard deviation"
putexcel B6 = CBI_sd_between
putexcel A7 = "Within-country standard deviation"
putexcel B7 = CBI_sd_within
putexcel A8 = "Minimum"
putexcel B8 = CBI_min
putexcel A9 = "Maximum"
putexcel B9 = CBI_max
putexcel A10 = "Countries in common CBI/reporting sample"
putexcel B10 = `CBI_countries'
putexcel A11 = "Countries with within-country CBI variation"
putexcel B11 = `CBI_countries_change'
putexcel A12 = "Country-year CBI changes relative to prior observed year"
putexcel B12 = `CBI_change_obs'
putexcel A14 = "Interpretation note:", bold
putexcel B14 = "With country fixed effects, the CBI coefficient is identified from within-country changes in the de jure independence index rather than persistent cross-country differences."

restore


*------------------------------------------------------------*
* 15.2 Table A6, Panel A: existing institutional controls
*------------------------------------------------------------*

preserve

egen __miss_a6 = rowmiss($DV $IVS $CTRLS cbi_index cb_reporting)
keep if __miss_a6 == 0
drop __miss_a6

xtset id_iso3 year
eststo clear

xtreg $DV $IVS $CTRLS i.year, fe vce(cluster id_iso3)
estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"
eststo A6A_M1

xtreg $DV $IVS cbi_index $CTRLS i.year, fe vce(cluster id_iso3)
estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"
eststo A6A_M2

xtreg $DV $IVS cb_reporting $CTRLS i.year, fe vce(cluster id_iso3)
estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"
eststo A6A_M3

xtreg $DV $IVS cbi_index cb_reporting $CTRLS i.year, ///
    fe vce(cluster id_iso3)
estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"
eststo A6A_M4

esttab A6A_M1 A6A_M2 A6A_M3 A6A_M4 ///
    using "$TABLEA6.rtf", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Baseline same sample" ///
            "+ CBI index" ///
            "+ Reporting/disclosure" ///
            "+ Both controls") ///
    keep(vuln_100 ready_100 ln_policy_count cbi_index cb_reporting) ///
    order(vuln_100 ready_100 ln_policy_count cbi_index cb_reporting) ///
    coeflabels( ///
          vuln_100 "Climate vulnerability" ///
          ready_100 "Climate readiness" ///
          ln_policy_count "Climate policy intensity" ///
          cbi_index "Central bank independence index" ///
          cb_reporting "Reporting/disclosure index") ///
    stats(Controls CountryFE YearFE ClusterSE N N_g r2_w, ///
          labels("Baseline controls" ///
                 "Country fixed effects" ///
                 "Year fixed effects" ///
                 "Country-clustered SE" ///
                 "Observations" ///
                 "Countries" ///
                 "Within R-squared") ///
          fmt(s s s s 0 0 3)) ///
    title("Table A6, Panel A. Central bank independence and reporting/disclosure controls") ///
    addnotes("The dependent variable is ln(1 + climate-related central bank speech sentences)." ///
             "All four models use the same complete-case sample." ///
             "Country and year fixed effects are included; standard errors are clustered by country." ///
             "*** p<0.01, ** p<0.05, * p<0.10.")

restore


*------------------------------------------------------------*
* 15.3 Table A6, Panel B: CBI heterogeneity and lagged CBI
*------------------------------------------------------------*

preserve

egen __miss_a6b = rowmiss($DV $IVS $CTRLS cbi_index cb_reporting)
keep if __miss_a6b == 0
drop __miss_a6b

xtset id_iso3 year

quietly summarize cbi_index, meanonly
scalar mean_cbi = r(mean)
gen double cbi_c = cbi_index - mean_cbi
label var cbi_c "Central bank independence, mean centered"

quietly summarize vuln_100, meanonly
scalar mean_vuln = r(mean)
gen double vuln_c = vuln_100 - mean_vuln
label var vuln_c "Climate vulnerability, mean centered"

quietly summarize ready_100, meanonly
scalar mean_ready = r(mean)
gen double ready_c = ready_100 - mean_ready
label var ready_c "Climate readiness, mean centered"

quietly summarize ln_policy_count, meanonly
scalar mean_policy = r(mean)
gen double policy_c = ln_policy_count - mean_policy
label var policy_c "Climate policy intensity, mean centered"

eststo clear

xtreg $DV ///
    c.cbi_c##c.vuln_c ///
    ready_100 ln_policy_count cb_reporting ///
    $CTRLS i.year, ///
    fe vce(cluster id_iso3)
estadd local Controls "Yes"
estadd local Reporting "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"
eststo A6B_M1_Vuln

xtreg $DV ///
    c.cbi_c##c.ready_c ///
    vuln_100 ln_policy_count cb_reporting ///
    $CTRLS i.year, ///
    fe vce(cluster id_iso3)
estadd local Controls "Yes"
estadd local Reporting "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"
eststo A6B_M2_Ready

xtreg $DV ///
    c.cbi_c##c.policy_c ///
    vuln_100 ready_100 cb_reporting ///
    $CTRLS i.year, ///
    fe vce(cluster id_iso3)
estadd local Controls "Yes"
estadd local Reporting "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"
eststo A6B_M3_Policy

xtreg $DV ///
    vuln_100 ready_100 ln_policy_count ///
    L1.cbi_index cb_reporting ///
    $CTRLS i.year, ///
    fe vce(cluster id_iso3)
estadd local Controls "Yes"
estadd local Reporting "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"
eststo A6B_M4_LagCBI

esttab A6B_M1_Vuln A6B_M2_Ready ///
       A6B_M3_Policy A6B_M4_LagCBI ///
    using "$TABLEA6.rtf", append ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("CBI x Vulnerability" ///
            "CBI x Readiness" ///
            "CBI x Policy intensity" ///
            "Lagged CBI") ///
    keep(cbi_c vuln_c ready_c policy_c ///
         c.cbi_c#c.vuln_c ///
         c.cbi_c#c.ready_c ///
         c.cbi_c#c.policy_c ///
         L.cbi_index) ///
    order(cbi_c vuln_c ready_c policy_c ///
          c.cbi_c#c.vuln_c ///
          c.cbi_c#c.ready_c ///
          c.cbi_c#c.policy_c ///
          L.cbi_index) ///
    coeflabels( ///
          cbi_c "Central bank independence" ///
          vuln_c "Climate vulnerability" ///
          ready_c "Climate readiness" ///
          policy_c "Climate policy intensity" ///
          c.cbi_c#c.vuln_c "CBI x Climate vulnerability" ///
          c.cbi_c#c.ready_c "CBI x Climate readiness" ///
          c.cbi_c#c.policy_c "CBI x Climate policy intensity" ///
          L.cbi_index "Central bank independence, t-1") ///
    stats(Controls Reporting CountryFE YearFE ClusterSE N N_g r2_w, ///
          labels("Baseline controls" ///
                 "Reporting/disclosure control" ///
                 "Country fixed effects" ///
                 "Year fixed effects" ///
                 "Country-clustered SE" ///
                 "Observations" ///
                 "Countries" ///
                 "Within R-squared") ///
          fmt(s s s s s 0 0 3)) ///
    title("Table A6, Panel B. Heterogeneity in the central bank independence association") ///
    addnotes("Continuous variables in Models (1)-(3) are mean centered before constructing interactions." ///
             "Each interaction is estimated separately while retaining the other main explanatory variables and the reporting/disclosure control." ///
             "Model (4) replaces contemporaneous CBI with its one-year lag." ///
             "Country and year fixed effects are included; standard errors are clustered by country." ///
             "*** p<0.01, ** p<0.05, * p<0.10.")


*------------------------------------------------------------*
* 15.4 Diagnostic marginal effects of CBI across vulnerability
*------------------------------------------------------------*

estimates restore A6B_M1_Vuln

quietly summarize vuln_100, detail

scalar v10 = r(p10)
scalar v25 = r(p25)
scalar v50 = r(p50)
scalar v75 = r(p75)
scalar v90 = r(p90)

scalar v10c = v10 - mean_vuln
scalar v25c = v25 - mean_vuln
scalar v50c = v50 - mean_vuln
scalar v75c = v75 - mean_vuln
scalar v90c = v90 - mean_vuln

local atvals ///
    `=v10c' ///
    `=v25c' ///
    `=v50c' ///
    `=v75c' ///
    `=v90c'

margins, dydx(cbi_c) at(vuln_c=(`atvals'))

matrix CBI_MARGINS = r(table)'

putexcel set "$CBIMARG.xlsx", replace sheet("Margins")
putexcel A1 = "Marginal effect of central bank independence across climate vulnerability", bold
putexcel A3 = matrix(CBI_MARGINS), names

putexcel J3 = "Vulnerability percentile", bold
putexcel J4 = "P10"
putexcel J5 = "P25"
putexcel J6 = "P50"
putexcel J7 = "P75"
putexcel J8 = "P90"

putexcel K3 = "Vulnerability level", bold
putexcel K4 = v10
putexcel K5 = v25
putexcel K6 = v50
putexcel K7 = v75
putexcel K8 = v90

putexcel J10 = "Note:", bold
putexcel K10 = "Marginal effects are diagnostic because the CBI x vulnerability interaction is the formal heterogeneity test."

marginsplot, ///
    recast(line) ///
    recastci(rarea) ///
    xlabel(`=v10c' "P10" ///
           `=v25c' "P25" ///
           `=v50c' "P50" ///
           `=v75c' "P75" ///
           `=v90c' "P90") ///
    yline(0, lpattern(shortdash)) ///
    xtitle("Climate vulnerability percentile") ///
    ytitle("Marginal effect of central bank independence") ///
    title("Central bank independence and climate discourse across vulnerability") ///
    legend(off) ///
    note("Marginal effects from the country and year fixed-effects interaction model.") ///
    graphregion(color(white))

graph export "$CBIFIG.png", replace width(2400)
graph export "$CBIFIG.pdf", replace

restore

xtset id_iso3 year

di as result "Revised Appendix Table A6 saved to: $TABLEA6.rtf"

*============================================================*
* BLOCK 16. Appendix Table A7
* Robustness to total central bank communication volume
*
* Output:
*   results/appendix/tables/Table_A7_total_communication_volume.rtf
*
* Notes:
*   - Communication-volume variables are created inside this block only.
*============================================================*

* Required packages are checked centrally in Block 4.

xtset id_iso3 year


*------------------------------------------------------------*
* 16.1 Create section-specific communication-volume controls
*------------------------------------------------------------*

capture drop ln_total_sents ln_total_words ln_total_speeches

gen ln_total_sents = ln(1 + total_sents_count) ///
    if !missing(total_sents_count)
label var ln_total_sents "Log total sentences"

gen ln_total_words = ln(1 + total_words_count) ///
    if !missing(total_words_count)
label var ln_total_words "Log total words"

gen ln_total_speeches = ln(1 + total_speeches_count) ///
    if !missing(total_speeches_count)
label var ln_total_speeches "Log total speeches"


*------------------------------------------------------------*
* 16.2 Use common complete-case sample for all A7 models
*------------------------------------------------------------*

preserve

egen __miss_a7 = rowmiss($DV $IVS $CTRLS ///
                         ln_total_sents ln_total_words ln_total_speeches)

keep if __miss_a7 == 0
drop __miss_a7

xtset id_iso3 year


*------------------------------------------------------------*
* 16.3 Estimate robustness models
*------------------------------------------------------------*

eststo clear


* Model (1): Baseline
xtreg $DV $IVS $CTRLS i.year, fe vce(cluster id_iso3)

estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"

eststo A7_M1_Baseline


* Model (2): Add total sentence volume
xtreg $DV $IVS $CTRLS ln_total_sents i.year, fe vce(cluster id_iso3)

estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"

eststo A7_M2_Total_Sents


* Model (3): Add total word volume
xtreg $DV $IVS $CTRLS ln_total_words i.year, fe vce(cluster id_iso3)

estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"

eststo A7_M3_Total_Words


* Model (4): Add total speech volume
xtreg $DV $IVS $CTRLS ln_total_speeches i.year, fe vce(cluster id_iso3)

estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"

eststo A7_M4_Total_Speeches


*------------------------------------------------------------*
* 16.4 Export Appendix Table A7
*------------------------------------------------------------*

esttab A7_M1_Baseline ///
       A7_M2_Total_Sents ///
       A7_M3_Total_Words ///
       A7_M4_Total_Speeches ///
    using "$TABLEA7.rtf", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Baseline" "+ Total sentences" "+ Total words" "+ Total speeches") ///
    keep(vuln_100 ready_100 ln_policy_count ///
         ln_total_sents ln_total_words ln_total_speeches) ///
    order(vuln_100 ready_100 ln_policy_count ///
          ln_total_sents ln_total_words ln_total_speeches) ///
    coeflabels( ///
          vuln_100 "Climate vulnerability" ///
          ready_100 "Climate readiness" ///
          ln_policy_count "Climate policy intensity" ///
          ln_total_sents "Log total sentences" ///
          ln_total_words "Log total words" ///
          ln_total_speeches "Log total speeches") ///
    stats(Controls CountryFE YearFE ClusterSE N N_g r2_w, ///
          labels("Baseline controls" ///
                 "Country fixed effects" ///
                 "Year fixed effects" ///
                 "Country-clustered standard errors" ///
                 "Observations" ///
                 "Countries" ///
                 "Within R-squared") ///
          fmt(s s s s 0 0 3)) ///
    title("Table A7. Robustness to total central bank communication volume") ///
    addnotes("The dependent variable is ln(1 + climate-related central bank speech sentences)." ///
             "Baseline controls include GDP per capita, inflation, private credit, institutional quality, CO2 emissions per capita, and fuel exports." ///
             "Robust standard errors clustered by country are reported in parentheses." ///
             "Models (2)-(4) control separately for total central bank communication volume using total sentences, total words, and total speeches." ///
             "The results indicate whether the baseline findings are driven by overall communication volume." ///
             "*** p<0.01, ** p<0.05, * p<0.10.")


*------------------------------------------------------------*
* 16.5 Restore full dataset and completion message
*------------------------------------------------------------*

restore

xtset id_iso3 year

di as result "Appendix Table A7 saved to: $TABLEA7.rtf"

*============================================================*
* BLOCK 17. Additional panel diagnostic
* Cross-sectional dependence after two-way fixed effects
*
* Diagnostic:
*   Pesaran CD test after baseline TWFE regression
*
* H0:
*   Cross-sectional independence
*
* Diagnostic window:
*   2010-2023
*
* Output:
*   results/diagnostics/Cross_sectional_dependence_diagnostic.xlsx
*============================================================*

*------------------------------------------------------------*
* 17.0 Safety checks
*------------------------------------------------------------*

if "${DV}" == "" {
    di as error "Global DV is not defined. Define global DV before running this block."
    exit 198
}

if "${IVS}" == "" {
    di as error "Global IVS is not defined. Define global IVS before running this block."
    exit 198
}

if "${CTRLS}" == "" {
    di as error "Global CTRLS is not defined. Define global CTRLS before running this block."
    exit 198
}

capture confirm variable id_iso3
if _rc {
    di as error "Variable id_iso3 not found."
    exit 111
}

capture confirm variable year
if _rc {
    di as error "Variable year not found."
    exit 111
}

foreach v of varlist $DV $IVS $CTRLS {
    capture confirm variable `v'
    if _rc {
        di as error "Required variable not found: `v'"
        exit 111
    }
}

if "${DIAGDIR}" == "" {
    capture mkdir "results"
    capture mkdir "results/diagnostics"
    global DIAGDIR "results/diagnostics"
}

capture mkdir "$DIAGDIR"


*------------------------------------------------------------*
* 17.1 Settings
*------------------------------------------------------------*

local DIAG_START = 2010
local DIAG_END   = 2023
local TREQ       = `DIAG_END' - `DIAG_START' + 1

local OUTFILE "$DIAGDIR/Cross_sectional_dependence_diagnostic"


*------------------------------------------------------------*
* 17.2 Construct balanced complete-case diagnostic sample
*------------------------------------------------------------*

preserve

keep if inrange(year, `DIAG_START', `DIAG_END')

egen __miss_cd = rowmiss($DV $IVS $CTRLS)
keep if __miss_cd == 0
drop __miss_cd

bys id_iso3: egen __nT    = count(year)
bys id_iso3: egen __minyr = min(year)
bys id_iso3: egen __maxyr = max(year)

keep if __nT == `TREQ' ///
    & __minyr == `DIAG_START' ///
    & __maxyr == `DIAG_END'

drop __nT __minyr __maxyr

count
local OBS_CD = r(N)

quietly levelsof id_iso3, local(__ids_cd)
local N_CD : word count `__ids_cd'

di as text "------------------------------------------------------------"
di as text "Cross-sectional dependence diagnostic"
di as text "Balanced complete-case sample: `DIAG_START'-`DIAG_END'"
di as text "Observations: `OBS_CD'"
di as text "Countries: `N_CD'"
di as text "Annual periods: `TREQ'"
di as text "------------------------------------------------------------"


*------------------------------------------------------------*
* 17.3 Estimate baseline TWFE model and obtain residuals
*------------------------------------------------------------*

if `OBS_CD' > 0 & `N_CD' >= 10 {

    xtset id_iso3 year

    xtreg $DV $IVS $CTRLS i.year, fe vce(cluster id_iso3)

    predict double __ehat_cd if e(sample), e

    keep if e(sample)
    keep id_iso3 year __ehat_cd

    isid id_iso3 year

    reshape wide __ehat_cd, i(year) j(id_iso3)

    ds __ehat_cd*
    local RESVARS `r(varlist)'

    local N_FINAL : word count `RESVARS'

    quietly count
    local T_FINAL = r(N)


    *--------------------------------------------------------*
    * 17.4 Manual Pesaran CD calculation
    *      CD = sqrt(2T / [N(N-1)]) * sum_{i<j} rho_ij
    *--------------------------------------------------------*

    scalar sumrho_cd    = 0
    scalar sumabsrho_cd = 0
    scalar paircount_cd = 0

    forvalues i = 1/`=`N_FINAL'-1' {
        
        local xi : word `i' of `RESVARS'
        
        forvalues j = `=`i'+1'/`N_FINAL' {
            
            local xj : word `j' of `RESVARS'
            
            quietly corr `xi' `xj'
            
            scalar rho_ij = r(rho)
            
            if !missing(rho_ij) {
                scalar sumrho_cd    = sumrho_cd + rho_ij
                scalar sumabsrho_cd = sumabsrho_cd + abs(rho_ij)
                scalar paircount_cd = paircount_cd + 1
            }
        }
    }

    scalar cd_stat = sqrt((2 * `T_FINAL') / (`N_FINAL' * (`N_FINAL' - 1))) * sumrho_cd
    scalar cd_p    = 2 * (1 - normal(abs(cd_stat)))
    scalar avg_abs_rho = sumabsrho_cd / paircount_cd

    local cd_s  : display %9.3f cd_stat
    local p_s   : display %9.4f cd_p
    local abs_s : display %9.3f avg_abs_rho

    local decision "Do not reject H0 of cross-sectional independence."
    if cd_p < 0.05 {
        local decision "Reject H0 of cross-sectional independence."
    }

    di as result "Pesaran CD statistic = `cd_s'"
    di as result "p-value = `p_s'"
    di as result "Average absolute residual correlation = `abs_s'"
    di as result "`decision'"


    *--------------------------------------------------------*
    * 17.5 Export diagnostic result
    *--------------------------------------------------------*

    putexcel set "`OUTFILE'.xlsx", replace sheet("CD diagnostic")

    putexcel A1 = "Additional panel diagnostic: Cross-sectional dependence", bold

    putexcel A3 = "Diagnostic", bold
    putexcel B3 = "Pesaran CD test after baseline TWFE regression"

    putexcel A4 = "Null hypothesis", bold
    putexcel B4 = "Cross-sectional independence"

    putexcel A6 = "Diagnostic window", bold
    putexcel B6 = "`DIAG_START'-`DIAG_END'"

    putexcel A7 = "Observations", bold
    putexcel B7 = `OBS_CD'

    putexcel A8 = "Countries", bold
    putexcel B8 = `N_FINAL'

    putexcel A9 = "Annual periods", bold
    putexcel B9 = `T_FINAL'

    putexcel A11 = "Pesaran CD statistic", bold
    putexcel B11 = (cd_stat), nformat("0.000")

    putexcel A12 = "p-value", bold
    putexcel B12 = (cd_p), nformat("0.0000")

    putexcel A13 = "Average absolute residual correlation", bold
    putexcel B13 = (avg_abs_rho), nformat("0.000")

    putexcel A14 = "Decision", bold
    putexcel B14 = "`decision'"

    putexcel A16 = "Text to report:", bold
    putexcel B16 = "Pesaran CD statistic = `cd_s'; p-value = `p_s'; average absolute residual correlation = `abs_s'. `decision'"

    putexcel A18 = "Notes:", bold
    putexcel B18 = "The diagnostic is computed after a two-way fixed-effects regression including the main explanatory variables, baseline controls, and year fixed effects."

    putexcel B19 = "The test uses a balanced complete-case country-year sample over `DIAG_START'-`DIAG_END'."

    putexcel B20 = "The result is interpreted as a panel diagnostic, not as a substitute for the country-clustered standard errors used in the main specifications."

    di as result "Cross-sectional dependence diagnostic saved to: `OUTFILE'.xlsx"
}

else {
    di as error "Insufficient balanced complete-case sample for Pesaran CD diagnostic."

    putexcel set "`OUTFILE'.xlsx", replace sheet("CD diagnostic")
    putexcel A1 = "Additional panel diagnostic: Cross-sectional dependence", bold
    putexcel A3 = "Result", bold
    putexcel B3 = "Insufficient balanced complete-case sample for Pesaran CD diagnostic."
    putexcel A4 = "Diagnostic window", bold
    putexcel B4 = "`DIAG_START'-`DIAG_END'"
    putexcel A5 = "Observations", bold
    putexcel B5 = `OBS_CD'
    putexcel A6 = "Countries", bold
    putexcel B6 = `N_CD'
}


*------------------------------------------------------------*
* 17.6 Restore full dataset
*------------------------------------------------------------*

restore

xtset id_iso3 year


*============================================================*
* BLOCK 18. Appendix Table A8
* Paris Agreement robustness
*
* Panel A:
*   Binary DiD
*   Binary DiD + total communication volume
*   Continuous pre-Paris vulnerability x Post-2016
*   Continuous interaction + total communication volume
*
* Panel B:
*   Event study without and with total communication volume
*============================================================*

xtset id_iso3 year

capture confirm variable ln_total_sents
if _rc {
    gen double ln_total_sents = ln(1 + total_sents_count) ///
        if !missing(total_sents_count)
    label var ln_total_sents "Log total sentences"
}

preserve

keep if inrange(rel, -6, 8)
keep if !missing(vuln_pre_100)

eststo clear


*------------------------------------------------------------*
* 18.1 Panel A: treatment definition and communication volume
*------------------------------------------------------------*

xtreg $DV did_paris $CTRLS i.year, ///
    fe vce(cluster id_iso3)
estadd local Controls "Yes"
estadd local CommunicationControl "No"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"
eststo A8_M1_Binary

xtreg $DV did_paris $CTRLS ln_total_sents i.year, ///
    fe vce(cluster id_iso3)
estadd local Controls "Yes"
estadd local CommunicationControl "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"
eststo A8_M2_BinaryVolume

xtreg $DV c.post_paris#c.vuln_pre_100 $CTRLS i.year, ///
    fe vce(cluster id_iso3)
estadd local Controls "Yes"
estadd local CommunicationControl "No"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"
eststo A8_M3_Continuous

xtreg $DV c.post_paris#c.vuln_pre_100 ///
    $CTRLS ln_total_sents i.year, ///
    fe vce(cluster id_iso3)
estadd local Controls "Yes"
estadd local CommunicationControl "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"
eststo A8_M4_ContinuousVolume

esttab A8_M1_Binary A8_M2_BinaryVolume ///
       A8_M3_Continuous A8_M4_ContinuousVolume ///
    using "$TABLEA8.rtf", replace ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Binary DiD" ///
            "Binary DiD + communication volume" ///
            "Continuous vulnerability x Post" ///
            "Continuous interaction + communication volume") ///
    keep(did_paris ///
         c.post_paris#c.vuln_pre_100 ///
         ln_total_sents) ///
    order(did_paris ///
          c.post_paris#c.vuln_pre_100 ///
          ln_total_sents) ///
    coeflabels( ///
          did_paris "Post-2016 x High vulnerability" ///
          c.post_paris#c.vuln_pre_100 "Post-2016 x Pre-Paris vulnerability" ///
          ln_total_sents "Log total central bank sentences") ///
    stats(Controls CommunicationControl CountryFE YearFE ClusterSE N N_g r2_w, ///
          labels("Baseline controls" ///
                 "Total communication control" ///
                 "Country fixed effects" ///
                 "Year fixed effects" ///
                 "Country-clustered SE" ///
                 "Observations" ///
                 "Countries" ///
                 "Within R-squared") ///
          fmt(s s s s s 0 0 3)) ///
    title("Table A8, Panel A. Paris robustness: treatment definition and communication volume") ///
    addnotes("The dependent variable is ln(1 + climate-related central bank speech sentences)." ///
             "High vulnerability is the top country tercile of average 2010-2015 vulnerability." ///
             "The continuous specification interacts Post-2016 with the country-level 2010-2015 average vulnerability index rescaled to 0-100." ///
             "Country and year fixed effects are included in all specifications; standard errors are clustered by country." ///
             "*** p<0.01, ** p<0.05, * p<0.10.")


*------------------------------------------------------------*
* 18.2 Panel B: event-study robustness to communication volume
*------------------------------------------------------------*

xtreg $DV ib9.rel_shift##i.high_vuln $CTRLS, ///
    fe vce(cluster id_iso3)

testparm ///
    4.rel_shift#1.high_vuln ///
    5.rel_shift#1.high_vuln ///
    6.rel_shift#1.high_vuln ///
    7.rel_shift#1.high_vuln ///
    8.rel_shift#1.high_vuln

estadd scalar Pretrend_p = r(p)
estadd local CommunicationControl "No"
estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local ClusterSE "Yes"
eststo A8_ES_Base

xtreg $DV ib9.rel_shift##i.high_vuln ///
    $CTRLS ln_total_sents, ///
    fe vce(cluster id_iso3)

testparm ///
    4.rel_shift#1.high_vuln ///
    5.rel_shift#1.high_vuln ///
    6.rel_shift#1.high_vuln ///
    7.rel_shift#1.high_vuln ///
    8.rel_shift#1.high_vuln

estadd scalar Pretrend_p = r(p)
estadd local CommunicationControl "Yes"
estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local ClusterSE "Yes"
eststo A8_ES_Volume

esttab A8_ES_Base A8_ES_Volume ///
    using "$TABLEA8.rtf", append ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Baseline event study" "+ Total sentence volume") ///
    keep( ///
        4.rel_shift#1.high_vuln ///
        5.rel_shift#1.high_vuln ///
        6.rel_shift#1.high_vuln ///
        7.rel_shift#1.high_vuln ///
        8.rel_shift#1.high_vuln ///
        10.rel_shift#1.high_vuln ///
        11.rel_shift#1.high_vuln ///
        12.rel_shift#1.high_vuln ///
        13.rel_shift#1.high_vuln ///
        14.rel_shift#1.high_vuln ///
        15.rel_shift#1.high_vuln ///
        16.rel_shift#1.high_vuln ///
        17.rel_shift#1.high_vuln ///
        ln_total_sents) ///
    order( ///
        4.rel_shift#1.high_vuln ///
        5.rel_shift#1.high_vuln ///
        6.rel_shift#1.high_vuln ///
        7.rel_shift#1.high_vuln ///
        8.rel_shift#1.high_vuln ///
        10.rel_shift#1.high_vuln ///
        11.rel_shift#1.high_vuln ///
        12.rel_shift#1.high_vuln ///
        13.rel_shift#1.high_vuln ///
        14.rel_shift#1.high_vuln ///
        15.rel_shift#1.high_vuln ///
        16.rel_shift#1.high_vuln ///
        17.rel_shift#1.high_vuln ///
        ln_total_sents) ///
    coeflabels( ///
        4.rel_shift#1.high_vuln  "t = -6" ///
        5.rel_shift#1.high_vuln  "t = -5" ///
        6.rel_shift#1.high_vuln  "t = -4" ///
        7.rel_shift#1.high_vuln  "t = -3" ///
        8.rel_shift#1.high_vuln  "t = -2" ///
        10.rel_shift#1.high_vuln "t = 0" ///
        11.rel_shift#1.high_vuln "t = +1" ///
        12.rel_shift#1.high_vuln "t = +2" ///
        13.rel_shift#1.high_vuln "t = +3" ///
        14.rel_shift#1.high_vuln "t = +4" ///
        15.rel_shift#1.high_vuln "t = +5" ///
        16.rel_shift#1.high_vuln "t = +6" ///
        17.rel_shift#1.high_vuln "t = +7" ///
        ln_total_sents "Log total central bank sentences") ///
    stats(Pretrend_p CommunicationControl Controls CountryFE ClusterSE N N_g r2_w, ///
          labels("Joint pre-trends p-value" ///
                 "Total communication control" ///
                 "Baseline controls" ///
                 "Country fixed effects" ///
                 "Country-clustered SE" ///
                 "Observations" ///
                 "Countries" ///
                 "Within R-squared") ///
          fmt(3 s s s s 0 0 3)) ///
    title("Table A8, Panel B. Paris event-study robustness to total communication volume") ///
    addnotes("The omitted event-time period is t=-1." ///
             "The communication-volume specification additionally controls for ln(1 + total central bank speech sentences)." ///
             "Standard errors are clustered by country." ///
             "*** p<0.01, ** p<0.05, * p<0.10.")

restore

xtset id_iso3 year

di as result "Appendix Table A8 saved to: $TABLEA8.rtf"


*============================================================*
* BLOCK 19. Appendix Table A9 and Figure A2
* Rambachan-Roth HonestDiD sensitivity analysis
*
* Table A9:
*   Average post-Paris and medium-run estimands under:
*   - Relative-magnitude restrictions
*   - Smoothness restrictions
*
* Figure A2:
*   Panel A. Medium-run relative-magnitude sensitivity
*   Panel B. Medium-run smoothness sensitivity
*============================================================*

capture which honestdid
if _rc {
    local github "https://raw.githubusercontent.com"
    net install honestdid, from(`github'/mcaceresb/stata-honestdid/main) replace
}

capture noisily honestdid _plugin_check

if _rc == 0 {

    preserve

    keep if inrange(rel, -6, 8)
    keep if !missing(high_vuln)

    xtreg $DV ib9.rel_shift##i.high_vuln $CTRLS, ///
        fe vce(cluster id_iso3)

    estimates store HONEST_ES

    matrix V_full = e(V)
    matrix b_honest = J(1, 13, .)
    matrix V_honest = J(13, 13, .)

    local events "-6 -5 -4 -3 -2 0 1 2 3 4 5 6 7"

    local ii = 1
    foreach r of local events {
        local s = `r' + 10
        local cname "`s'.rel_shift#1.high_vuln"

        scalar __btmp = _b[`cname']
        matrix b_honest[1,`ii'] = __btmp

        local ++ii
    }

    local ii = 1
    foreach ri of local events {

        local si = `ri' + 10
        local namei "`si'.rel_shift#1.high_vuln"
        local ci = colnumb(V_full, "`namei'")

        local jj = 1
        foreach rj of local events {

            local sj = `rj' + 10
            local namej "`sj'.rel_shift#1.high_vuln"
            local cj = colnumb(V_full, "`namej'")

            matrix V_honest[`ii',`jj'] = V_full[`ci',`cj']

            local ++jj
        }

        local ++ii
    }

    matrix colnames b_honest = ///
        pre6 pre5 pre4 pre3 pre2 ///
        post0 post1 post2 post3 post4 post5 post6 post7

    matrix rownames V_honest = ///
        pre6 pre5 pre4 pre3 pre2 ///
        post0 post1 post2 post3 post4 post5 post6 post7

    matrix colnames V_honest = ///
        pre6 pre5 pre4 pre3 pre2 ///
        post0 post1 post2 post3 post4 post5 post6 post7

    matrix l_avgpost = J(8, 1, 1/8)

    matrix l_medium = ///
        (0 \ ///
         0 \ ///
         0 \ ///
         0.2 \ ///
         0.2 \ ///
         0.2 \ ///
         0.2 \ ///
         0.2)


    *--------------------------------------------------------*
    * 19.1 Relative-magnitude restrictions
    *--------------------------------------------------------*

    honestdid, ///
        b(b_honest) vcov(V_honest) ///
        numpre(5) ///
        l_vec(l_avgpost) ///
        mvec(0 0.5 1 1.5 2) ///
        delta(rm)

    mata: st_matrix("HD_AVG_RM", HonestEventStudy.CI)

    honestdid, ///
        b(b_honest) vcov(V_honest) ///
        numpre(5) ///
        l_vec(l_medium) ///
        mvec(0 0.5 1 1.5 2) ///
        delta(rm) ///
        coefplot ///
        xtitle("Relative-magnitude bound, Mbar") ///
        ytitle("95% robust confidence interval") ///
        title("Panel A. Medium-run relative-magnitude sensitivity")

    mata: st_matrix("HD_MED_RM", HonestEventStudy.CI)

    graph save "$WORKDIR/HonestDiD_mediumrun_RM.gph", replace


    *--------------------------------------------------------*
    * 19.2 Smoothness restrictions
    *--------------------------------------------------------*

    honestdid, ///
        b(b_honest) vcov(V_honest) ///
        numpre(5) ///
        l_vec(l_avgpost) ///
        mvec(0 0.05 0.10 0.20 0.30 0.50) ///
        delta(sd)

    mata: st_matrix("HD_AVG_SD", HonestEventStudy.CI)

    honestdid, ///
        b(b_honest) vcov(V_honest) ///
        numpre(5) ///
        l_vec(l_medium) ///
        mvec(0 0.05 0.10 0.20 0.30 0.50) ///
        delta(sd) ///
        coefplot ///
        xtitle("Smoothness bound, M") ///
        ytitle("95% robust confidence interval") ///
        title("Panel B. Medium-run smoothness sensitivity")

    mata: st_matrix("HD_MED_SD", HonestEventStudy.CI)

    graph save "$WORKDIR/HonestDiD_mediumrun_SD.gph", replace


    *--------------------------------------------------------*
    * 19.3 Export Table A9
    *--------------------------------------------------------*

    putexcel set "$TABLEA9.xlsx", replace sheet("Average_RM")
    putexcel A1 = "Table A9. Rambachan-Roth sensitivity analysis", bold
    putexcel A3 = "Panel A. Average post-Paris differential, relative-magnitude restriction", bold
    putexcel A5 = matrix(HD_AVG_RM), names

    putexcel set "$TABLEA9.xlsx", modify sheet("Medium_RM")
    putexcel A1 = "Panel B. Medium-run differential, t=+3 through t=+7, relative-magnitude restriction", bold
    putexcel A3 = matrix(HD_MED_RM), names

    putexcel set "$TABLEA9.xlsx", modify sheet("Average_SD")
    putexcel A1 = "Panel C. Average post-Paris differential, smoothness restriction", bold
    putexcel A3 = matrix(HD_AVG_SD), names

    putexcel set "$TABLEA9.xlsx", modify sheet("Medium_SD")
    putexcel A1 = "Panel D. Medium-run differential, t=+3 through t=+7, smoothness restriction", bold
    putexcel A3 = matrix(HD_MED_SD), names
    putexcel A12 = "Notes:", bold
    putexcel B12 = "The event-study coefficient vector contains t=-6 through t=-2 and t=0 through t=+7, with t=-1 normalized to zero."
    putexcel B13 = "The average post-Paris estimand assigns equal weight to t=0 through t=+7."
    putexcel B14 = "The medium-run estimand assigns equal weight to t=+3 through t=+7."
    putexcel B15 = "Relative-magnitude and smoothness restrictions follow the Rambachan-Roth sensitivity framework implemented by honestdid."


    *--------------------------------------------------------*
    * 19.4 Combine Figure A2
    *--------------------------------------------------------*

    capture graph drop HONEST_RM_RELOAD
    capture graph drop HONEST_SD_RELOAD

    graph use "$WORKDIR/HonestDiD_mediumrun_RM.gph", ///
        name(HONEST_RM_RELOAD, replace)

    graph use "$WORKDIR/HonestDiD_mediumrun_SD.gph", ///
        name(HONEST_SD_RELOAD, replace)

    graph combine HONEST_RM_RELOAD HONEST_SD_RELOAD, ///
        cols(2) ///
        imargin(small) ///
        graphregion(color(white)) ///
        title("Rambachan-Roth sensitivity of the medium-run Paris differential")

    graph export "$FIGA2.png", replace width(2800)
    graph export "$FIGA2.pdf", replace
    graph save "$FIGA2.gph", replace

    restore

    di as result "Appendix Table A9 saved to: $TABLEA9.xlsx"
    di as result "Appendix Figure A2 saved to: $FIGA2.png and $FIGA2.pdf"
}
else {
    di as error "HonestDiD plugin check failed; Block 19 was skipped."
    di as error "All other project analyses remain unaffected."
}


*============================================================*
* BLOCK 20. Final completion summary
*============================================================*

xtset id_iso3 year

di as result "============================================================"
di as result "FINAL PROJECT DO-FILE COMPLETED"
di as result "============================================================"
di as result "Main-paper tables:  $MAINTAB"
di as result "Main-paper figures: $MAINFIG"
di as result "Appendix tables:    $APPTAB"
di as result "Appendix figures:   $APPFIG"
di as result "Diagnostics:        $DIAGDIR"
di as result "Working files:      $WORKDIR"

capture log close

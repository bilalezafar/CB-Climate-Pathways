/***********************************************************************

DATA SOURCES AND PANEL STRUCTURE

Unit of analysis:
Country-year panel, 1996-2024.

Main sources:
- Central bank climate discourse:
BIS Central Bank Speeches database; sentence-level climate
classification using validated climate lexicon and ClimateBERT.

- Key explanatory variables:
Climate vulnerability and readiness:
ND-GAIN Country Index

Climate policy intensity:
Climate Change Laws of the World (CCLW)

- Baseline controls:
GDP per capita, private credit, CO2 emissions, and fuel exports:
World Bank World Development Indicators (WDI).

Inflation:
IMF International Financial Statistics (IFS) / World Bank WDI.

Institutional quality:
World Bank Worldwide Governance Indicators (WGI).

- Central bank institutional controls:
Central Bank Independence-Extended (CBIE) dataset
(Romelli 2024, 2022);


- Total communication volume:
Derived from the same BIS Central Bank Speeches corpus;
variables include total speeches, sentences, words, and
climate-related speeches/words.

***********************************************************************/



*============================================================*
* BLOCK 0 Arrange dataset variables logically
*============================================================*

* keep ///
    id_iso3 year ///
    climate_sents_count climate_bert_score ///
    climate_vulnerability climate_readiness ///
    policy_count ///
    gdp_pc inflation_cpi credit_banks_gdp wgi_score co2_pc fuel_exports_share ///
    cbi_index cb_reporting ///
    total_speeches_count total_sents_count total_words_count ///
    climate_speeches_count climate_words_count


order ///
    id_iso3 year ///
    climate_sents_count climate_bert_score ///
    climate_vulnerability climate_readiness ///
    policy_count ///
    gdp_pc inflation_cpi credit_banks_gdp wgi_score co2_pc fuel_exports_share ///
    cbi_index cb_reporting ///
    total_speeches_count total_sents_count total_words_count ///
    climate_speeches_count climate_words_count

	
* sort id_iso3 year
* xtset id_iso3 year

* compress
* describe

* save "climate_cb original.dta", replace

********************
* Save de-identified supplementary dataset.
* Note:
*   Country-identifying value labels have been removed from id_iso3 for
*   de-identified replication. The numeric panel identifier id_iso3 is retained,
*   so all do-file analyses and results remain fully replicable. Researchers
*   requiring the country-code crosswalk may request it from the authors.
*********************

* label values id_iso3
* capture label drop id_iso3

* save "3-climate_cb supplementary.dta", replace

sort id_iso3 year
xtset id_iso3 year

compress
describe

*============================================================*
* BLOCK 1. Variable labels
*============================================================*

label var id_iso3              "Country panel id"
label var year                 "Year"

label var climate_sents_count  "Climate discourse (sentence count)"
label var climate_bert_score   "Climate discourse intensity (ClimateBERT score)"

label var climate_vulnerability "Climate vulnerability (ND-GAIN)"
label var climate_readiness     "Climate readiness (ND-GAIN)"
label var policy_count          "Climate policy intensity (policy count)"

label var gdp_pc               "GDP per capita (constant 2015 USD)"
label var inflation_cpi        "Inflation (CPI, %)"
label var credit_banks_gdp     "Private credit (% of GDP)"
label var wgi_score            "Institutional quality (WGI government effectiveness)"
label var co2_pc               "CO2 emissions per capita"
label var fuel_exports_share   "Fuel exports (% of merchandise exports)"

label var cbi_index            "Central bank independence index"
label var cb_reporting         "Central bank reporting/disclosure index"

label var total_speeches_count "Total central bank speeches"
label var total_sents_count    "Total central bank speech sentences"
label var total_words_count    "Total central bank speech words"
label var climate_speeches_count "Climate-related speeches"
label var climate_words_count    "Climate-related words"



*============================================================*
* BLOCK 2. Main-text and appendix variable construction
*============================================================*

*----------------------------*
* 2.1 Panel declaration
*----------------------------*

sort id_iso3 year
xtset id_iso3 year


*----------------------------*
* 2.2 Core outcome and explanatory-variable transformations
*----------------------------*

gen ln_climate_sents = ln(1 + climate_sents_count) if !missing(climate_sents_count)
label var ln_climate_sents "ln(1 + climate-related sentence count)"

gen ln_policy_count = ln(1 + policy_count) if !missing(policy_count)
label var ln_policy_count "ln(1 + climate policy count)"

gen ln_gdp_pc = ln(gdp_pc) if gdp_pc > 0
label var ln_gdp_pc "ln(GDP per capita, constant 2015 USD)"

gen asinh_inflation = asinh(inflation_cpi) if !missing(inflation_cpi)
label var asinh_inflation "asinh(Inflation, CPI %)"

gen ln1p_co2_pc = ln(1 + co2_pc) if !missing(co2_pc)
label var ln1p_co2_pc "ln(1 + CO2 emissions per capita)"

gen vuln_100 = 100 * climate_vulnerability if !missing(climate_vulnerability)
label var vuln_100 "Climate vulnerability (0-100 index points)"

gen ready_100 = 100 * climate_readiness if !missing(climate_readiness)
label var ready_100 "Climate readiness (0-100 index points)"


*----------------------------*
* 2.3 Lagged dependent variable for dynamic FE model
*----------------------------*

capture drop L1_DV
gen L1_DV = L1.ln_climate_sents
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
* BLOCK 4. Results folder structure and output paths
*============================================================*

*----------------------------*
* 4.1 Main folders
*----------------------------*

capture mkdir "results"
capture mkdir "results/main_paper"
capture mkdir "results/main_paper/tables"
capture mkdir "results/main_paper/figures"

capture mkdir "results/appendix"
capture mkdir "results/appendix/tables"
capture mkdir "results/appendix/figures"

capture mkdir "results/diagnostics"
capture mkdir "results/working"


*----------------------------*
* 4.2 Global output folders
*----------------------------*

global OUTROOT "results"

global MAINTAB "results/main_paper/tables"
global MAINFIG "results/main_paper/figures"

global APPTAB  "results/appendix/tables"
global APPFIG  "results/appendix/figures"

global DIAGDIR "results/diagnostics"
global WORKDIR "results/working"


*----------------------------*
* 4.3 Main-paper output files
*----------------------------*

global TABLE2 "$MAINTAB/Table_2_TWFE_lag_structure"
global TABLE3 "$MAINTAB/Table_3_quantile_regressions"
global TABLE4 "$MAINTAB/Table_4_panel_predictive_tests"
global TABLE5 "$MAINTAB/Table_5_paris_did_eventstudy"

global FIGURE1 "$MAINFIG/Figure_1_paris_eventstudy"


*----------------------------*
* 4.4 Appendix output files
*----------------------------*

global FIGA1 "$APPFIG/Figure_A1_descriptive_communication_trends"

global TABLEA1 "$APPTAB/Table_A1_year_level_descriptives"
global TABLEA2 "$APPTAB/Table_A2_missing_covariates_MI"
global TABLEA3 "$APPTAB/Table_A3_poisson_FE_count_model"
global TABLEA4 "$APPTAB/Table_A4_main_explanatory_variable_correlations"
global TABLEA5 "$APPTAB/Table_A5_alternative_joint_specifications"
global TABLEA6 "$APPTAB/Table_A6_cbi_reporting_controls"
global TABLEA7 "$APPTAB/Table_A7_total_communication_volume"


*----------------------------*
* 4.5 Display structure
*----------------------------*

di as result "Main-paper tables folder: $MAINTAB"
di as result "Main-paper figures folder: $MAINFIG"
di as result "Appendix tables folder: $APPTAB"
di as result "Appendix figures folder: $APPFIG"


*============================================================*
* BLOCK 5. Main paper Table 2
* Climate risk exposure and discourse:
* Two-way fixed effects with lag structure
*
* Output:
*   results/main_paper/tables/Table_2_TWFE_lag_structure.rtf
*============================================================*

*------------------------------------------------------------*
* 5.0 Required package
*------------------------------------------------------------*

cap which esttab
if _rc ssc install estout, replace


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
* BLOCK 8. Main paper Table 5 and Figure 1
* Paris Agreement and Climate Discourse:
* Event-study and collapsed DiD
*
* Outputs:
*   results/main_paper/tables/Table_5_paris_did_eventstudy.xlsx
*   results/main_paper/figures/Figure_1_paris_eventstudy.png
*   results/main_paper/figures/Figure_1_paris_eventstudy.pdf
*============================================================*

*------------------------------------------------------------*
* 8.0 Panel declaration
*------------------------------------------------------------*

xtset id_iso3 year

*------------------------------------------------------------*
* 8.1 Create high-vulnerability treatment group
*      This reproduces the original Table 5 coding exactly
*      High vulnerability = top tercile of average pre-2016 vulnerability
*      Baseline period: 2010-2015
*------------------------------------------------------------*

capture drop vuln_pre vuln_pre2 high_vuln post_paris did_paris

bys id_iso3: egen vuln_pre = mean(climate_vulnerability) if inrange(year, 2010, 2015)
bys id_iso3: egen vuln_pre2 = max(vuln_pre)

drop vuln_pre
rename vuln_pre2 vuln_pre

label var vuln_pre "Average pre-2016 climate vulnerability, 2010-2015"

xtile high_vuln = vuln_pre, n(3)
replace high_vuln = (high_vuln == 3)

label define highv 0 "Low/medium vulnerability" 1 "High vulnerability", replace
label values high_vuln highv
label var high_vuln "High vulnerability group, top tercile of pre-2016 vulnerability"

gen post_paris = (year >= 2016) if !missing(year)
label var post_paris "Post-Paris period, year >= 2016"

gen did_paris = post_paris * high_vuln
label var did_paris "Post-2016 x high vulnerability"

tab high_vuln, missing


*------------------------------------------------------------*
* 8.2 Restrict to Paris event window
*      Event window: t = -6 to t = +8
*      Reported coefficients: t = -6 to t = +7
*------------------------------------------------------------*

preserve

capture drop rel rel_shift

gen rel = year - 2016
keep if inrange(rel, -6, 8)

gen rel_shift = rel + 10
label var rel_shift "Event time shifted, Paris 2016"

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
    18 "+8", replace

label values rel_shift rel_lbl


*------------------------------------------------------------*
* 8.3 Panel A: Collapsed DiD
*      Country FE + year FE
*------------------------------------------------------------*

xtreg $DV did_paris $CTRLS i.year, fe vce(cluster id_iso3)

estimates store PARIS_DID

local N_did  = e(N)
local Ng_did = e(N_g)
local r2_did : display %6.3f e(r2_w)

scalar b_did  = _b[did_paris]
scalar se_did = _se[did_paris]
scalar p_did  = 2 * ttail(e(df_r), abs(b_did / se_did))

local star_did ""
if p_did < 0.10 local star_did "*"
if p_did < 0.05 local star_did "**"
if p_did < 0.01 local star_did "***"

local b_did_s  : display %9.3f b_did
local se_did_s : display %9.3f se_did
local did_cell "`b_did_s'`star_did' (`se_did_s')"


*------------------------------------------------------------*
* 8.4 Panel B: Event-study
*      Country FE + event-time effects
*      Base period: t = -1
*------------------------------------------------------------*

xtreg $DV ib9.rel_shift##i.high_vuln $CTRLS, fe vce(cluster id_iso3)

estimates store PARIS_ES

local N_es  = e(N)
local Ng_es = e(N_g)
local r2_es : display %6.3f e(r2_w)

testparm 4.rel_shift#1.high_vuln ///
         5.rel_shift#1.high_vuln ///
         6.rel_shift#1.high_vuln ///
         7.rel_shift#1.high_vuln ///
         8.rel_shift#1.high_vuln

local pretrend_p : display %6.3f r(p)

di as result "Paris event-study pre-trends joint p-value = `pretrend_p'"


*------------------------------------------------------------*
* 8.5 Export Table 5 to Excel
*------------------------------------------------------------*

putexcel set "$TABLE5.xlsx", replace sheet("Table 5")

putexcel A1 = "Table 5. Paris Agreement and Climate Discourse: Event-Study and DiD", bold

putexcel A3 = "Panel A: Collapsed DiD (Country FE + Year FE)", bold
putexcel A4 = "Variable", bold
putexcel B4 = "Model (1)", bold

putexcel A5 = "Post-2016 x High vulnerability"
putexcel B5 = "`did_cell'"

putexcel A7  = "Controls"
putexcel B7  = "Yes"
putexcel A8  = "Country FE"
putexcel B8  = "Yes"
putexcel A9  = "Year FE"
putexcel B9  = "Yes"
putexcel A10 = "Observations"
putexcel B10 = `N_did'
putexcel A11 = "Countries"
putexcel B11 = `Ng_did'
putexcel A12 = "Within R-squared"
putexcel B12 = `r2_did'
putexcel A13 = "SE clustering"
putexcel B13 = "Country"

putexcel A16 = "Panel B: Event-study (Country FE + Event-time effects)", bold
putexcel A17 = "Event time (t)", bold
putexcel B17 = "High vulnerability x 1[t]", bold

local row = 18

estimates restore PARIS_ES

foreach r in -6 -5 -4 -3 -2 {
    
    local s = `r' + 10
    
    capture scalar b_es  = _b[`s'.rel_shift#1.high_vuln]
    capture scalar se_es = _se[`s'.rel_shift#1.high_vuln]
    
    scalar p_es = 2 * ttail(e(df_r), abs(b_es / se_es))
    
    local star_es ""
    if p_es < 0.10 local star_es "*"
    if p_es < 0.05 local star_es "**"
    if p_es < 0.01 local star_es "***"
    
    local b_es_s  : display %9.3f b_es
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
    
    capture scalar b_es  = _b[`s'.rel_shift#1.high_vuln]
    capture scalar se_es = _se[`s'.rel_shift#1.high_vuln]
    
    scalar p_es = 2 * ttail(e(df_r), abs(b_es / se_es))
    
    local star_es ""
    if p_es < 0.10 local star_es "*"
    if p_es < 0.05 local star_es "**"
    if p_es < 0.01 local star_es "***"
    
    local b_es_s  : display %9.3f b_es
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
putexcel B`note_row' = "The dependent variable is climate discourse. High vulnerability is defined using the pre-2016 vulnerability index and therefore captures pre-existing physical exposure rather than a post-Paris change in vulnerability."

local note_row = `note_row' + 1
putexcel B`note_row' = "Panel A estimates a collapsed DiD with country and year fixed effects. Panel B reports an event-study with country fixed effects and event-time indicators, with t = -1 as the omitted baseline period."

local note_row = `note_row' + 1
putexcel B`note_row' = "All models include the baseline controls, and standard errors are clustered by country. The Paris Agreement is interpreted as a global climate-policy salience shock."

local note_row = `note_row' + 1
putexcel B`note_row' = "Joint pre-trends p-value = `pretrend_p'. *** p<0.01, ** p<0.05, * p<0.10."


*------------------------------------------------------------*
* 8.6 Build event-study plot dataset
*------------------------------------------------------------*

clear
set obs 14

gen rel = .
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

gen coef = .
gen se   = .

estimates restore PARIS_ES

foreach r in -6 -5 -4 -3 -2 0 1 2 3 4 5 6 7 {
    
    local s = `r' + 10
    
    capture scalar b_plot  = _b[`s'.rel_shift#1.high_vuln]
    capture scalar se_plot = _se[`s'.rel_shift#1.high_vuln]
    
    replace coef = b_plot  if rel == `r'
    replace se   = se_plot if rel == `r'
}

replace coef = 0 if rel == -1
replace se   = 0 if rel == -1

gen lb = coef - 1.96 * se
gen ub = coef + 1.96 * se


*------------------------------------------------------------*
* 8.7 Export Figure 1
*------------------------------------------------------------*

twoway ///
    (rcap ub lb rel) ///
    (connected coef rel, msymbol(O)), ///
    xline(0, lpattern(dash)) ///
    yline(0, lpattern(dash)) ///
    xlabel(-6(1)7) ///
    xtitle("Event time relative to Paris Agreement, 2016") ///
    ytitle("High vulnerability x event-time coefficient") ///
    title("Paris Agreement event-study") ///
    note("Base period is t = -1. Whiskers show 95% confidence intervals.") ///
    graphregion(color(white))

graph export "$FIGURE1.png", replace width(2400)
graph export "$FIGURE1.pdf", replace


*------------------------------------------------------------*
* 8.8 Restore full dataset and completion message
*------------------------------------------------------------*

restore

di as result "Table 5 saved to: $TABLE5.xlsx"
di as result "Figure 1 saved to: $FIGURE1.png and $FIGURE1.pdf"





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
* 9.0 Graph settings and output paths
*------------------------------------------------------------*

set scheme s1color

capture mkdir "results"
capture mkdir "results/appendix"
capture mkdir "results/appendix/figures"

global APPFIG "results/appendix/figures"
global FIGA1  "${APPFIG}/Figure_A1_descriptive_communication_trends"

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

*------------------------------------------------------------*
* 11.0 Required package
*------------------------------------------------------------*

cap which esttab
if _rc ssc install estout, replace


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
* BLOCK 15. Appendix Table A6
* Robustness to central bank independence and
* reporting/disclosure controls
*
* Output:
*   results/appendix/tables/Table_A6_cbi_reporting_controls.rtf
*============================================================*

*------------------------------------------------------------*
* 15.0 Required package
*------------------------------------------------------------*

cap which esttab
if _rc ssc install estout, replace

xtset id_iso3 year


*------------------------------------------------------------*
* 15.1 Estimate models on common CBI/reporting sample
*------------------------------------------------------------*

preserve

egen __miss_a6 = rowmiss($DV $IVS $CTRLS cbi_index cb_reporting)
keep if __miss_a6 == 0
drop __miss_a6

eststo clear


* Model (1): Baseline on same sample
xtreg $DV $IVS $CTRLS i.year, fe vce(cluster id_iso3)

estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"

eststo A6_M1_Baseline


* Model (2): Add central bank independence index
xtreg $DV $IVS cbi_index $CTRLS i.year, fe vce(cluster id_iso3)

estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"

eststo A6_M2_CBI


* Model (3): Add reporting/disclosure index
xtreg $DV $IVS cb_reporting $CTRLS i.year, fe vce(cluster id_iso3)

estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"

eststo A6_M3_Reporting


* Model (4): Add both controls
xtreg $DV $IVS cbi_index cb_reporting $CTRLS i.year, fe vce(cluster id_iso3)

estadd local Controls "Yes"
estadd local CountryFE "Yes"
estadd local YearFE "Yes"
estadd local ClusterSE "Yes"

eststo A6_M4_Both


*------------------------------------------------------------*
* 15.2 Export Appendix Table A6
*------------------------------------------------------------*

esttab A6_M1_Baseline A6_M2_CBI A6_M3_Reporting A6_M4_Both ///
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
    title("Table A6. Robustness to central bank independence and reporting/disclosure controls") ///
    addnotes("The dependent variable is climate discourse, measured as ln(1 + climate-related central bank speech sentences)." ///
             "Baseline controls include GDP per capita, inflation, private credit, institutional quality, CO2 emissions per capita, and fuel exports." ///
             "The central bank independence index and reporting/disclosure index are taken from the Central Bank Independence-Extended dataset." ///
             "Standard errors clustered by country are reported in parentheses." ///
             "*** p<0.01, ** p<0.05, * p<0.10.")

restore

xtset id_iso3 year

di as result "Appendix Table A6 saved to: $TABLEA6.rtf"


*============================================================*
* BLOCK 16. Appendix Table A7
* Robustness to total central bank communication volume
*
* Output:
*   results/appendix/tables/Table_A7_total_communication_volume.rtf
*
* Notes:
*   - Communication-volume variables are created inside this block only.
*   - No merge is needed because total communication variables are already
*     retained in the clean main dataset.
*============================================================*

*------------------------------------------------------------*
* 16.0 Required package
*------------------------------------------------------------*

cap which esttab
if _rc ssc install estout, replace

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





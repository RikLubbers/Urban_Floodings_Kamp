<div align="center">
    <h1>Geospatial modelling reveals flood-driven inequities in healthcare accessibility among populations vulnerable to undernutrition in Kampala, Uganda</h1>
</div>

This repository contains the analytical codebase for a study quantifying how urban pluvial floods alter walking access to public and private not-for-profit (PNFP) healthcare facilities in Kampala, Uganda. The analysis estimates population-weighted changes in travel time across 15 rainfall × duration scenarios, separately for all public/PNFP facilities and for hospitals only, and examines how accessibility losses are distributed across a nutrition-sensitive composite vulnerability index. Under the most intense modelled storm (100 mm, 1 hr), population-weighted mean travel time increases from 11.5 to 19.3 minutes for all facilities and from 23.4 to 56.3 minutes for hospitals; in the highest vulnerability quartile, hospital delays reach a mean of 72.4 minutes.

**Manuscript:** Lubbers R.U., Weitkamp G., Hierink F., Ray N., Oporia F., Businge O., Biesma R. *Geospatial modelling reveals flood-driven inequities in healthcare accessibility among populations vulnerable to undernutrition in Kampala, Uganda.* Under review at *Communications Medicine* (COMMSMED-25-2757, Revision 1).

---

## Authors

| Name | Affiliation |
|---|---|
| Rik U. Lubbers (MSc) ✉ | Global Health Unit, Dept. of Health Sciences, UMCG, Groningen, NL; Dept. of Cultural Geography, University of Groningen, NL |
| Gerd Weitkamp (PhD) | Dept. of Cultural Geography, University of Groningen, NL |
| Fleur Hierink (PhD) | GeoHealth Group, Institute of Global Health, University of Geneva, CH; Institute for Environmental Sciences, University of Geneva, CH |
| Nicolas Ray (PhD) | GeoHealth Group, Institute of Global Health, University of Geneva, CH; Institute for Environmental Sciences, University of Geneva, CH |
| Frederick Oporia (PhD) | Dept. of Disease Control and Environmental Health, Makerere University School of Public Health, UG |
| Otto Businge (MSc) | Dept. of Disease Control and Environmental Health, Makerere University School of Public Health, UG |
| Regien Biesma (PhD) | Global Health Unit, Dept. of Health Sciences, UMCG, Groningen, NL; Dept. of Global Public Health and Bioethics, Julius Center, UMC Utrecht, NL |

✉ Corresponding author: r.u.lubbers@rug.nl

---

## 1. Project structure

```
Urban_Floodings_Kamp/
├── Code/
│   ├── 00_scenario_definitions.R          # Factorial design of 15 flood scenarios
│   ├── run_analysis.qmd                   # Master runner (executes all analysis scripts)
│   ├── utils/                             # Shared utility functions
│   │   ├── loading_utils.R                #   Data ingestion and environment setup
│   │   ├── export_utils.R                 #   Figure/table export wrappers
│   │   └── impact_utils.R                 #   Population-weighted impact functions
│   ├── 0_Accessmod_prep/                  # Step 0: Spatial pre-processing & AccessMod inputs
│   │   ├── 01.1_Aligning_cleaning_data.qmd
│   │   ├── 01.2_InAccessmod.qmd
│   │   ├── 01.3_Pop_raster_correction.qmd
│   │   └── 01.4_Merged_landcovers.qmd
│   ├── 1_Data_loading_baseline/           # Step 1: Baseline geography (Fig. 1)
│   │   └── 02_Baseline_geography.qmd
│   ├── 2_delta_travel_time/               # Step 2: Baseline accessibility maps (Fig. 2)
│   │   ├── 02.1_Baseline_Accessibility_Main.qmd
│   │   └── 02.1S_Baseline_Accessibility_Supp.qmd
│   ├── 3_Pop_impact/                      # Step 3: Population-weighted delta travel time
│   │   ├── 03.1_Pop_Impact_Main.qmd       #   Table 2 & Figs. 3–4
│   │   ├── 03.1S_Pop_Impact_Supp.qmd
│   │   └── 03.3S_Pop_Impact_Summary_Supp.qmd
│   └── 4_Vulnerability_index_impact/      # Step 4: Vulnerability overlays
│       ├── 04.1_Index_equal_weight.qmd    #   Equal-weight vulnerability index
│       ├── 04.1B_PCA_and_Comparison.qmd   #   PCA-based index & sensitivity analysis
│       ├── 04.2_Vulnerability_Impact_Main.qmd   # Table 3 & Figs. 5–6
│       └── 04.2S_Vulnerability_Impact_Supp.qmd
├── Data/                                  # Not distributed (see §4)
├── AccessMod/                             # AccessMod project files (not distributed)
├── Figures/                               # Generated outputs
├── Tables/                                # Generated outputs
├── renv.lock                              # Pinned R package versions
├── .Rprofile                              # Activates renv on session start
├── CITATION.cff
├── LICENSE.txt
├── CONTRIBUTING.md
└── CODE_OF_CONDUCT.md
```

Scripts within `Code/` are prefixed numerically and designed to be executed in order (0 → 1 → 2 → 3 → 4). Scripts suffixed `_Main` produce manuscript figures and tables; those suffixed `_Supp` or `S` produce supplementary materials.

---

## 2. Reproducibility

### Software requirements

| Software         | Version   | Purpose                                  |
|------------------|-----------|------------------------------------------|
| R                | ≥ 4.4.0   | Statistical computing                    |
| Quarto           | ≥ 1.4     | Rendering `.qmd` analysis documents      |
| AccessMod        | 5.8.0     | Travel time surface modelling            |

Spatial pre-processing of input layers was performed using the [`inAccessMod`](https://github.com/unige-geohealth/inAccessMod) R package. AccessMod batch execution across the 15 flood scenarios was implemented via a forked and adapted version of [`AMRemote`](https://github.com/RikLubbers/AMRemote_looped_MLC).

### R package environment

This project uses [`renv`](https://rstudio.github.io/renv/) for reproducible package management. Exact package versions are recorded in `renv.lock`.

```r
# 1. Open the project (the .Rprofile activates renv automatically)
# 2. Restore the package library:
renv::restore()
```

### Running the analysis

**Pre-processing (Step 0)** must be run once before the main analysis. These scripts prepare spatial inputs and require AccessMod 5.8.0 for travel time surface generation:

1. `Code/0_Accessmod_prep/01.1_Aligning_cleaning_data.qmd`
2. `Code/0_Accessmod_prep/01.2_InAccessmod.qmd`
3. `Code/0_Accessmod_prep/01.3_Pop_raster_correction.qmd`
4. `Code/0_Accessmod_prep/01.4_Merged_landcovers.qmd`
5. Run AccessMod 5.8.0 travel time analyses (baseline + 15 flood scenarios × 2 facility tiers) using the `AMRemote_looped_MLC` batch workflow

**Main analysis (Steps 1–4)** can then be executed via the master runner:

```r
# Renders all main and supplementary scripts in sequence
quarto::quarto_render("Code/run_analysis.qmd")
```

Or render individual scripts in the order listed in the project structure above.

---

## 3. Scenario design

The study evaluates a full factorial design of **15 pluvial flood scenarios**: 5 rainfall intensities (20, 40, 60, 80, 100 mm) × 3 storm durations (1, 3, 6 hr). Flood extents are derived from the hydrodynamic model of [McClean et al. (2021)](https://doi.org/10.5285/E53DEA2E-CB25-4F0F-B5F9-937EECF15AFF). Water depths ≥ 0.20 m are modelled as barriers to pedestrian movement; depths of 0.10 m are traversable at a reduced walking speed.

A subset of **6 main scenarios** (20, 60, 100 mm at 1 hr and 6 hr) is used for the primary manuscript analysis. Scenario definitions are centralised in `Code/00_scenario_definitions.R`.

### Key results (main scenarios)

| Scenario | All facilities — mean increase (min) | Hospitals — mean increase (min) |
|---|---|---|
| 20 mm, 6 hr | 11.5 | 23.4 |
| 20 mm, 1 hr | 13.0 | 29.3 |
| 60 mm, 6 hr | 13.2 | 34.2 |
| 60 mm, 1 hr | 17.5 | 48.2 |
| 100 mm, 6 hr | 14.1 | 37.3 |
| 100 mm, 1 hr | 19.3 | 56.3 |

In the highest vulnerability quartile (Q4) under the 100 mm, 1 hr scenario, the mean hospital delay reaches **72.4 minutes** (parish-level maxima > 200 minutes).

Travel speeds were validated at expert travel scenario workshops held in Kampala (December 2024) with representatives from the Ministry of Health, UNFPA, KCCA, and Ugandan universities.

---

## 4. Data availability

All input datasets are publicly available; sources and access links are described in Supplementary Table 1 of the manuscript. Raw data are not distributed in this repository.

A minimum analysis-ready dataset sufficient to reproduce the reported results — including derived model outputs and scenario-specific travel time surfaces — is publicly archived on Zenodo:

> Lubbers R.U. et al. (2025). *Minimum dataset for "Geospatial modelling reveals flood-driven inequities in healthcare accessibility among populations vulnerable to undernutrition in Kampala, Uganda"*. Zenodo. https://doi.org/10.5281/zenodo.17531074

Source data underlying all main figures are provided in `Source_Data.xlsx`. Full statistical summaries across all 15 modelled scenarios are provided in Supplementary Data files 1 and 2.

---

## 5. Contributing

Methodological improvements, issue reports, and pull requests are welcome. Please read `CONTRIBUTING.md`, follow the code of conduct in `CODE_OF_CONDUCT.md`, and open an issue to discuss substantial changes.

**Contact:** Rik U. Lubbers — r.u.lubbers@rug.nl, r.u.lubbers@umcg.nl

---

## 6. License

This project is licensed under [CC-BY-SA-4.0](LICENSE.txt).

---

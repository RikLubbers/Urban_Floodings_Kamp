<div align="center">
    <h1>Geospatial modelling of pluvial flood scenarios and their effects on physical access to maternal and child healthcare facilities</h1>
</div>

This repository contains the analytical codebase for a study examining how urban pluvial floods alter walking access to healthcare facilities in Kampala, Uganda. The analysis estimates population-weighted changes in travel time across 15 rainfall × duration scenarios, separately for all public and PNFP facilities and for hospitals, and quantifies inequities by intersecting flood impact with a composite vulnerability index.

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
│   │   └── 02.1S_Baseline_Accessibility_Supp.qmd # Internal raster generation (QC)
│   ├── 3_Pop_impact/                      # Step 3: Population-weighted delta travel time
│   │   ├── 03.1_Pop_Impact_Main.qmd       #   Fig. 3 & Table 1
│   │   ├── 03.1S_Pop_Impact_Supp.qmd
│   │   └── 03.3S_Pop_Impact_Summary_Supp.qmd
│   └── 4_Vulnerability_index_impact/      # Step 4: Vulnerability overlays
│       ├── 04.1_Index_equal_weight.qmd    #   Equal-weight vulnerability index
│       ├── 04.1B_PCA_and_Comparison.qmd   #   PCA-based index & sensitivity analysis
│       ├── 04.2_Vulnerability_Impact_Main.qmd   # Fig. 4 & Table 2
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

| Software         | Version  | Purpose                                  |
|------------------|----------|------------------------------------------|
| R                | ≥ 4.4    | Statistical computing                    |
| Quarto           | ≥ 1.4    | Rendering `.qmd` analysis documents      |
| AccessMod        | 5.x      | Travel time surface modelling            |

### R package environment

This project uses [`renv`](https://rstudio.github.io/renv/) for reproducible package management. Exact package versions are recorded in `renv.lock`.

```r
# 1. Open the project (the .Rprofile activates renv automatically)
# 2. Restore the package library:
renv::restore()
```

### Running the analysis

**Pre-processing (Step 0)** must be run once before the main analysis. These scripts prepare spatial inputs and require AccessMod 5.x for travel time surface generation:

1. `Code/0_Accessmod_prep/01.1_Aligning_cleaning_data.qmd`
2. `Code/0_Accessmod_prep/01.2_InAccessmod.qmd`
3. `Code/0_Accessmod_prep/01.3_Pop_raster_correction.qmd`
4. `Code/0_Accessmod_prep/01.4_Merged_landcovers.qmd`
5. Run AccessMod 5 travel time analyses (baseline + 15 flood scenarios × 2 facility tiers)

**Main analysis (Steps 1–4)** can then be executed via the master runner:

```r
# Renders all main and supplementary scripts in sequence
quarto::quarto_render("Code/run_analysis.qmd")
```

Or render individual scripts in the order listed in the project structure above.

---

## 3. Scenario design

The study evaluates a full factorial design of **15 pluvial flood scenarios**: 5 rainfall intensities (20, 40, 60, 80, 100 mm) × 3 storm durations (1, 3, 6 hr). A subset of **6 main scenarios** (20, 60, 100 mm at 1 hr and 6 hr) is used for the primary manuscript analysis. Scenario definitions are centralised in `Code/00_scenario_definitions.R`.

---

## 4. Data availability

The study relies on publicly available secondary datasets; an overview is provided in the supplementary materials. Raw data is not included in this repository. A minimal analysis-ready dataset sufficient to reproduce the reported results will be publicly archived on Zenodo upon publication.

---

## 5. Contributing

Methodological improvements, issue reports, and pull requests are welcome. Please read `CONTRIBUTING.md`, follow the code of conduct in `CODE_OF_CONDUCT.md`, and open an issue to discuss substantial changes.

**Contact:** Rik U. Lubbers — r.u.lubbers@rug.nl, r.u.lubbers@umcg.nl

---

## 6. License

This project is licensed under [CC-BY-SA-4.0](LICENSE.txt).

---

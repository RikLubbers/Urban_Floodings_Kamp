<div align="center">
    <h1>Geospatial modelling of pluvial flood scenarios and their effects on physical access to maternal and child healthcare facilities</h1>
</div>

This repository contains the analytical codebase for a study examining how urban pluvial floods alter walking access to healthcare facilities in Kampala, Uganda. The analysis estimates population-weighted changes in travel time for public and PNFP facilities and hospitals, and quantifies inequities by intersecting flood impact with a vulnerability index.

---

## 1. Overview

Climate-intensified urban floods disrupt essential primary and maternal and child health services leading to communities vulnerable to undernutrition. This repository documents the modelling pipeline, from preprocessing spatial inputs, to preparing AccessMod surfaces, to computing pre versus post flood travel times, to population-weighted impacts and vulnerability overlays. The goal is transparent, inspectable, and reusable analysis.

---

## 2. Project structure

    Urban_Floodings_Kamp/
    ├── code/                          # Quarto (.qmd) analysis scripts
    │   ├── 01_data_loading/           # baseline geography and data ingestion
    │   ├── 1_accessmod_prep/         # landcover merge, speed assignment, export to AccessMod
    │   ├── 2_delta_travel_time/      # post flood travel time vs baseline
    │   ├── 3_population_impact/      # population-weighted delta travel time
    │   └── 4_vulnerability/          # equal weight and PCA indices, inequity statistics


The `code/` directory is ordered to mirror the manuscript logic. Running scripts in numerical order reproduces figures and tables.

---

## 3. Reproducibility

### Software
- R, version 4.x or later  
- Quarto, for rendering `.qmd`  
- AccessMod 5.x, for travel time modelling

### Packages and environment
This project uses `renv` for exact package versions.

---

## 4. Data availability

The study relies on publicly available secondary datasets of which an overview can be found in the supplementary materials. The repository does not include raw data. A minimal, anonymized analysis-ready dataset made by us, the authors, sufficient to reproduce the reported results will be publicly archived on Zenodo upon publication.
---

## 5. Code availability

All Quarto `.qmd` files are in `code/`. Utility functions reside within the corresponding subfolders and are documented inline. Code is released to enable scrutiny, reuse, and extension in allied public health and urban planning research.

---

## 6. Good practice and safeguards

- `.gitignore` excludes sensitive files, large rasters, and licensed microdata.  
- Scripts avoid hardcoded machine specific paths where possible, rely on relative project paths.  

---

## 7. Contributing

Methodological improvements, issue reports, and pull requests are welcome. Please read `CONTRIBUTING.md`, follow the code of conduct, and open an issue to discuss substantial changes. Community contributions that enhance equity focused analysis are particularly encouraged.

Contact  
Rik U. Lubbers, r.u.lubbers@rug.nl, r.u.lubbers@umcg.nl

---

## 8. License

The project is licensed under [LICENSE.txt](https://github.com/RikLubbers/PhD-Code/blob/main/LICENSE.txt). Refer to this file for licensing details.

---

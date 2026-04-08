# loading_utils.R
# Environment setup, library loading, processed data ingestion, facility
# filtering, and shared raster alignment for the flood accessibility analysis.

# --- Environment & Package Initialisation ------------------------------------

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}
library(renv)
if (!renv::status()$synchronized) {
  renv::activate()
}
renv::restore()

# Core geospatial, data manipulation, and visualisation libraries
library(terra)
library(tidyterra)
library(here)
library(dplyr)
library(tidyr)
library(tibble)
library(purrr)
library(stringr)
library(ggplot2)
library(patchwork)
library(biscale)
library(sf)
library(ggnewscale)
library(readxl)
library(viridis)

# --- Processed Data Ingestion ------------------------------------------------

# Loads all processed geospatial datasets into the global environment.
# Scans subdirectories of Data/processed/ for vector (.shp, .geojson, .gpkg)
# and raster (.tif, .vrt, .img) files and assigns each to a global variable
# named after its parent folder. Also loads baseline travel time rasters
# from AccessMod output and creates standardised aliases.
load_processed_data <- function() {
  data_dir <- here("Data", "processed")
  
  folders <- c("Parish_boundaries", "DEM", "Flood_extents", 
               "Landcover", "OSM_roads", "Rainfall_estimation", 
               "water_lines", "Worldpop_density", "Worldpop_dev_indicators")
  
  for (folder in folders) {
    folder_path <- file.path(data_dir, folder)
    if (!dir.exists(folder_path)) next
    
    files <- list.files(folder_path, full.names = TRUE, recursive = TRUE)
    
    # Vector datasets
    vector_files <- files[grepl("\\.(shp|geojson|gpkg)$", files, ignore.case = TRUE)]
    if (length(vector_files) == 1) {
      assign(folder, terra::vect(vector_files[[1]]), envir = .GlobalEnv)
    } else if (length(vector_files) > 1) {
      assign(folder, lapply(vector_files, terra::vect), envir = .GlobalEnv)
    }
    
    # Raster datasets
    raster_files <- files[grepl("\\.(tif|vrt|img)$", files, ignore.case = TRUE)]
    if (length(raster_files) == 1) {
      assign(folder, terra::rast(raster_files[[1]]), envir = .GlobalEnv)
    } else if (length(raster_files) > 1) {
      assign(folder, lapply(raster_files, terra::rast), envir = .GlobalEnv)
    }
  }

  # Facility data: prefer processed vector; fall back to raw shapefiles
  processed_fac_path <- file.path(data_dir, "Facilities")
  processed_fac_files <- if (dir.exists(processed_fac_path)) {
    list.files(processed_fac_path, pattern = "\\.(shp|geojson|gpkg)$", full.names = TRUE, ignore.case = TRUE)
  } else {
    character(0)
  }

  if (length(processed_fac_files) > 0) {
    assign("Facilities", terra::vect(processed_fac_files[1]), envir = .GlobalEnv)
  } else {
    raw_fac_path <- here::here("Data", "raw", "Facilities")
    if (dir.exists(raw_fac_path)) {
      fac_files <- list.files(raw_fac_path, pattern = "\\.shp$", full.names = TRUE)
      if (length(fac_files) > 0) {
        f_list <- lapply(fac_files, terra::vect)
        names(f_list) <- tools::file_path_sans_ext(basename(fac_files))
        assign("Facilities", f_list, envir = .GlobalEnv)
      }
    }
  }
  
  # Top-level rasters (e.g., vulnerability index)
  top_files <- list.files(data_dir, pattern = "\\.tif$", full.names = TRUE, recursive = FALSE)
  for (f in top_files) {
    name <- tools::file_path_sans_ext(basename(f))
    assign(name, terra::rast(f), envir = .GlobalEnv)
  }
  # Standardised alias for vulnerability index
  if (exists("vuln_raster_index")) vuln_index <<- get("vuln_raster_index")
  
  # Standardised alias for population density
  if (exists("Worldpop_density")) Worldpop_density <<- get("Worldpop_density")

  # Baseline travel time rasters (AccessMod output)
  base_all_path <- here::here("AccessMod", "Output", "Base", "raster_travel_time_Base_all")
  if (dir.exists(base_all_path)) {
    f <- list.files(base_all_path, pattern = "\\.img$", full.names = TRUE)
    if (length(f) > 0) base_tt_all <<- terra::rast(f[1])
  }
  
  base_hosp_path <- here::here("AccessMod", "Output", "Base", "raster_travel_time_Base_hosp")
  if (dir.exists(base_hosp_path)) {
    f <- list.files(base_hosp_path, pattern = "\\.img$", full.names = TRUE)
    if (length(f) > 0) base_tt_hosp <<- terra::rast(f[1])
  }
}

# --- Facility Filtering & Contextual Layer Construction ----------------------

# Splits loaded facility data into hospitals and health centres (assigned
# globally). Loads the complete Sub-Saharan Africa facility dataset for
# contextual mapping, applies a coordinate shift to align the reference
# dataset with the study-area projection, and creates contextual layers
# for facilities outside the AOI.
filter_facilities <- function() {
  if (!exists("Facilities")) stop("Facilities data not loaded.")
  
  fac_vect <- if (inherits(Facilities, "list")) {
    idx <- which(names(Facilities) == "UG_HF_all")
    if (length(idx) > 0) Facilities[[idx]] else Facilities[[1]]
  } else {
    Facilities
  }
  
  # Normalise column names (handle both "." and " " separators)
  for (col in c("Facility_t", "Facility_n")) {
    old_dot <- sub("_", ".", col)
    old_space <- sub("_", " ", col)
    if (!(col %in% names(fac_vect))) {
      if (old_dot %in% names(fac_vect)) names(fac_vect)[names(fac_vect) == old_dot] <- col
      else if (old_space %in% names(fac_vect)) names(fac_vect)[names(fac_vect) == old_space] <- col
    }
  }
  
  hospitals_main <<- fac_vect[grepl("Hospital", fac_vect$Facility_t, ignore.case = TRUE), ]
  health_centres_main <<- fac_vect[grepl("Health Centre|Health Center", fac_vect$Facility_t, ignore.case = TRUE), ]
  
  # Build contextual facility layers from the full Sub-Saharan dataset
  raw_fac_path <- here::here("Data", "raw", "Facilities", "suhsharan_health_facilities", "sub-saharan_health_facilities.shp")
  if (file.exists(raw_fac_path)) {
    facilities_complete <- terra::vect(raw_fac_path)
    
    # Normalise column names (handle both "." and " " separators)
    for (col in c("Facility_t", "Facility_n", "LL_source")) {
      old_dot <- sub("_", ".", col)
      old_space <- sub("_", " ", col)
      if (!(col %in% names(facilities_complete))) {
        if (old_dot %in% names(facilities_complete)) names(facilities_complete)[names(facilities_complete) == old_dot] <- col
        else if (old_space %in% names(facilities_complete)) names(facilities_complete)[names(facilities_complete) == old_space] <- col
      }
    }
    
    # Project and crop to buffered study extent
    facilities_complete <- terra::project(facilities_complete, Landcover)
    margin_extent <- terra::ext(Landcover) + 10000 
    facilities_complete <- terra::crop(facilities_complete, margin_extent)
    
    message(paste0("Loaded ", nrow(facilities_complete), " reference facilities in the extended study region."))
    
    # Compute and apply coordinate shift to align reference facilities
    common_ids <- intersect(facilities_complete$Facility_n, fac_vect$Facility_n)
    if (length(common_ids) > 0) {
      coords_c <- terra::crds(facilities_complete[match(common_ids, facilities_complete$Facility_n), ])
      coords_s <- terra::crds(fac_vect[match(common_ids, fac_vect$Facility_n), ])
      dx <- mean(coords_s[, 1] - coords_c[, 1], na.rm = TRUE)
      dy <- mean(coords_s[, 2] - coords_c[, 2], na.rm = TRUE)
      facilities_complete <- terra::shift(facilities_complete, dx, dy)
    }
    
    hospitals_complete <<- facilities_complete[grepl("Hospital", facilities_complete$Facility_t, ignore.case = TRUE), ]
    health_centers_complete <<- facilities_complete[grepl("Health Centre|Health Center", facilities_complete$Facility_t, ignore.case = TRUE), ]
  } else {
    hospitals_complete <<- fac_vect[0, ]
    health_centers_complete <<- fac_vect[0, ]
  }
}

# --- Visual Parameters -------------------------------------------------------

# ESA WorldCover 10 m (2021) colour palette and class labels
landcover_colors_base <- c(
  "10" = "#006400", "20" = "#ffbb22", "30" = "#ffff4c", 
  "40" = "#f096ff", "50" = "#fa0000", "60" = "#b4b4b4", 
  "70" = "#f0f0f0", "80" = "#0064c8", "90" = "#0096a0", 
  "95" = "#00cf75", "100" = "#fae6a0", "0" = NA
)

landcover_classes_base <- c(
  "10" = "Tree cover", "20" = "Shrubland", "30" = "Grassland",
  "40" = "Cropland", "50" = "Built-up", "60" = "Bare/Sparse vegetation",
  "70" = "Snow and Ice", "80" = "Permanent water bodies",
  "90" = "Herbaceous wetland", "95" = "Mangroves",
  "100" = "Moss and lichen", "0" = "No data"
)

# Travel time colour ramp (green → red → black)
tt_colors <- c("#008000", "#ADFF2F", "#FFFF00", "#FFA500", "#FF4500", "#FF0000", "#8B0000", "#000000")

# Reprojects and masks a population raster to match the geometry of a
# travel time raster. If geometries already match, masking alone is applied.
align_pop_to_tt <- function(pop_raster, tt_raster) {
  if (inherits(pop_raster, "list")) {
    idx <- which(names(pop_raster) == "pop_total_10m")
    pop_raster <- if (length(idx) > 0) pop_raster[[idx]] else pop_raster[[1]]
  }
  
  if (!terra::compareGeom(pop_raster, tt_raster, stopOnError = FALSE)) {
    pop_aligned <- terra::project(pop_raster, tt_raster, method = "bilinear")
    pop_aligned <- terra::mask(pop_aligned, tt_raster)
    return(pop_aligned)
  }
  return(terra::mask(pop_raster, tt_raster))
}

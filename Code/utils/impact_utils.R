# impact_utils.R
# Shared utilities for scenario metadata extraction, population-weighted
# pixel extraction, parish-level impact aggregation, bivariate classification,
# and vulnerability-stratified analysis.

# --- Scenario Metadata Extraction -------------------------------------------

# Parses scenario name strings to extract rainfall intensity (mm) and
# storm duration (hr). Supports both compact ("20mm_1h") and underscore-
# separated ("flood_20_3600") naming conventions. Falls back to lookup
# in `scenarios_all` when pattern matching fails.
extract_scenario_info <- function(name) {
  if (grepl("^\\d+mm_\\d+h$", name)) {
    intensity <- as.numeric(sub("mm_.*", "", name))
    duration_hr <- as.numeric(sub(".*_(\\d+)h$", "\\1", name))
  } else if (grepl("^\\d+\\s*mm\\s*/\\s*\\d+\\s*hr$", name)) {
    # Handle label_plot format: "20 mm / 1 hr"
    intensity <- as.numeric(sub("\\s*mm.*", "", name))
    duration_hr <- as.numeric(sub(".*?/\\s*(\\d+)\\s*hr$", "\\1", name))
  } else {
    parts <- unlist(strsplit(name, "_"))
    nums <- as.numeric(parts[grep("^\\d+$", parts)])
    if (length(nums) >= 2) {
      intensity <- nums[1]
      duration_sec <- nums[2]
      # Values > 24 are assumed to be in seconds (e.g., 3600s = 1 hr)
      duration_hr <- if (duration_sec > 24) duration_sec / 3600 else duration_sec
    } else {
      s_match <- scenarios_all %>% dplyr::filter(label == name | label_plot == name | scenario_id == name)
      if (nrow(s_match) > 0) {
        intensity <- s_match$rainfall_mm[1]
        duration_hr <- s_match$duration_hr[1]
      } else {
        stop("Could not extract scenario info from: ", name)
      }
    }
  }
  
  return(data.frame(
    Intensity = intensity, 
    Duration_hr = duration_hr,
    Duration_label = paste0(duration_hr, " hr")
  ))
}

# Returns column names matching a prefix (e.g., "Average_Weighted_Delta_TT_"),
# sorted by rainfall intensity then storm duration.
get_scenario_cols <- function(df, prefix = "Average_Weighted_Delta_TT_") {
  cols <- grep(paste0("^", prefix), names(df), value = TRUE)
  meta <- purrr::map_dfr(cols, function(c) {
    label <- sub(prefix, "", c)
    info <- extract_scenario_info(label)
    data.frame(col = c, int = info$Intensity, dur = info$Duration_hr)
  })
  meta <- meta %>% arrange(int, dur)
  return(meta$col)
}

# --- Population-Weighted Pixel Extraction ------------------------------------

# Extracts per-pixel delta travel time values paired with population weights
# from a multi-layer delta raster stack, for a specified facility tier.
extract_weighted_pixels <- function(delta_stack, pop_raster, facility_label) {
  if (inherits(pop_raster, "list")) {
    idx <- which(names(pop_raster) == "pop_total_10m")
    pop_raster <- if (length(idx) > 0) pop_raster[[idx]] else pop_raster[[1]]
  }
  
  pop_aligned <- align_pop_to_tt(pop_raster, delta_stack)
  pop_vals <- terra::values(pop_aligned, mat = FALSE)
  
  out_list <- list()
  for (i in seq_along(terra::names(delta_stack))) {
    s_name <- terra::names(delta_stack)[i]
    d_vals <- terra::values(delta_stack[[i]], mat = FALSE)
    
    # Retain only cells with valid population (> 0) and non-NA delta values
    valid_idx <- which(!is.na(pop_vals) & pop_vals > 0 & !is.na(d_vals))
    if (length(valid_idx) == 0) next
    
    s_info <- extract_scenario_info(s_name)
    out_list[[i]] <- data.frame(
      delta_tt = d_vals[valid_idx],
      pop = pop_vals[valid_idx],
      Intensity = s_info$Intensity,
      Duration = s_info$Duration_label,
      FacilityType = facility_label,
      scenario = s_name
    )
  }
  dplyr::bind_rows(out_list)
}

# Memory-efficient alternative to extract_weighted_pixels(). Draws a
# population-weighted random sample (default n = 100,000) per scenario layer
# Performs population-weighted sampling of delta travel time values for a 
# given facility tier across a stack of flood scenarios.
# Uses pixel-level sampled summaries for manuscript-level impact estimates (Summary Tables).
sample_weighted_pixels_from_raster <- function(delta_stack, pop_raster, facility_label, n_sample = 100000) {
  if (inherits(pop_raster, "list")) {
    idx <- which(names(pop_raster) == "pop_total_10m")
    pop_raster <- if (length(idx) > 0) pop_raster[[idx]] else pop_raster[[1]]
  }
  
  out_list <- list()
  for (i in seq_along(terra::names(delta_stack))) {
    s_name <- terra::names(delta_stack)[i]
    # Use only the current layer for geometry alignment and masking
    current_layer <- delta_stack[[i]]
    
    pop_aligned <- align_pop_to_tt(pop_raster, current_layer)
    pop_vals <- terra::values(pop_aligned, mat = FALSE)
    d_vals <- terra::values(current_layer, mat = FALSE)
    
    # Valid indices based on single-layer universe
    valid_idx <- which(!is.na(pop_vals) & pop_vals > 0 & !is.na(d_vals))
    
    if (length(valid_idx) == 0) next
    
    s_info <- extract_scenario_info(s_name)
    layer_seed <- as.integer(834 + s_info$Intensity * 100 + round(s_info$Duration_hr))
    set.seed(layer_seed)
    
    n <- min(length(valid_idx), n_sample)
    s_idx <- sample(valid_idx, size = n, replace = TRUE, prob = pop_vals[valid_idx])
    
    out_list[[i]] <- data.frame(
      delta_tt = d_vals[s_idx],
      Intensity = s_info$Intensity,
      Duration = s_info$Duration_label,
      FacilityType = facility_label,
      scenario = s_name
    )
  }
  dplyr::bind_rows(out_list)
}


# --- Global Vulnerability Breaks ---------------------------------------------

# Computes global pixel-level vulnerability quartile breaks from a single-layer
# vulnerability index raster, using all non-NA values in the study area.
# These breaks ensure that 'high vulnerability' (Q4) represents the same
# population cohort across all scenarios and analytical units.
get_global_vuln_breaks <- function(vuln_raster) {
  if (inherits(vuln_raster, "list")) {
    idx <- which(names(vuln_raster) == "PCA_Index" | names(vuln_raster) == "vuln_raster_index")
    vuln_raster <- if (length(idx) > 0) vuln_raster[[idx]] else vuln_raster[[1]]
  }
  
  vals <- terra::values(vuln_raster, mat = FALSE)
  brks <- unique(quantile(vals, probs = seq(0, 1, 0.25), na.rm = TRUE))
  
  # Ensure exactly 5 breaks for Q1-Q4 if quantiles are tied
  if (length(brks) < 5) {
    full_range <- seq(min(vals, na.rm = TRUE), max(vals, na.rm = TRUE), length.out = 5)
    brks <- sort(unique(c(brks, full_range)))
    brks <- brks[seq(1, length(brks), length.out = 5)]
  }
  return(brks)
}

# --- Bivariate Classification -----------------------------------------------

# Assigns bivariate classes to two pre-binned columns using biscale::bi_class().
prepare_bivariate_data <- function(df, var1, var2, dim = 3) {
  df_bi <- bi_class(df, x = !!sym(var1), y = !!sym(var2), 
                    style = "quantile", dim = dim)
  return(df_bi)
}

# --- Parish Ranking ----------------------------------------------------------

# Identifies the top-n parishes by population-weighted delta travel time
# for each scenario column. Detects the parish name column dynamically,
# preferring "PName2016".
top_n_by_scenario <- function(df, cols, tier, scenarios_ref, n = 10) {
  parish_col <- if ("PName2016" %in% names(df)) {
    "PName2016"
  } else {
    chr_cols <- names(df)[sapply(df, is.character)]
    if (length(chr_cols) > 0) chr_cols[1] else stop("No parish name column found in df")
  }
  
  purrr::map_dfr(cols, function(col) {
    s_label <- sub("Average_Weighted_Delta_TT_", "", col)
    s_plot_match <- scenarios_ref$label_plot[scenarios_ref$label == s_label]
    s_plot <- if (length(s_plot_match) > 0) s_plot_match[1] else s_label
    
    df %>%
      dplyr::transmute(
        Scenario = s_plot,
        Parish = .data[[parish_col]],
        Avg_Weighted_Delta_TT = .data[[col]]
      ) %>%
      dplyr::arrange(dplyr::desc(Avg_Weighted_Delta_TT)) %>%
      dplyr::slice_head(n = n) %>%
      dplyr::mutate(Rank = dplyr::row_number(), Tier = tier)
  })
}

# --- Raster Data Loading & Delta Calculation ---------------------------------

# Loads all flood-scenario travel time rasters from the AccessMod output
# directory tree. Matches each subdirectory to its scenario definition via
# rainfall intensity (mm) and duration (s).
load_flood_scenarios <- function(type = c("all", "hosp")) {
  type <- match.arg(type)
  base_dir <- here::here("AccessMod", "Output", paste0("Flood_", type))
  
  if (!dir.exists(base_dir)) stop("Flood output directory not found: ", base_dir)
  
  mlc_dirs <- list.dirs(path = base_dir, full.names = TRUE, recursive = FALSE)
  img_list <- list()
  
  for (mlc_dir in mlc_dirs) {
    scenario_name <- basename(mlc_dir)
    raster_dir <- file.path(mlc_dir, "0-min", 
                            paste0("raster_travel_time_Floods_", type, "_config"))
    
    if (dir.exists(raster_dir)) {
      f <- list.files(path = raster_dir, pattern = "\\.img$", full.names = TRUE)
      if (length(f) > 0) {
        mm <- as.numeric(stringr::str_extract(scenario_name, "\\d+(?=_)"))
        sec <- as.numeric(stringr::str_extract(scenario_name, "\\d+$"))
        
        r <- terra::rast(f[1])
        s_match <- scenarios_all %>% dplyr::filter(rainfall_mm == mm, duration_s == sec)
        if (nrow(s_match) > 0) {
          img_list[[s_match$label]] <- r
        }
      }
    }
  }
  out <- terra::rast(img_list)
  names(out) <- names(img_list)
  return(out)
}

# Computes the cell-wise difference between flood and baseline travel time.
calculate_delta_stack <- function(flood_stack, base_raster) {
  delta_stack <- flood_stack - base_raster
  return(delta_stack)
}

# Persists individual delta travel time layers as GeoTIFF files.
save_delta_rasters <- function(raster_data, folder_name = "processed/delta_travel") {
  processed_dir <- here::here("Data", folder_name)
  if (!dir.exists(processed_dir)) dir.create(processed_dir, recursive = TRUE)
  
  sanitize_fn <- function(x) gsub("[^[:alnum:]\\._-]", "_", x)
  
  if (inherits(raster_data, "SpatRaster")) {
    for (i in 1:terra::nlyr(raster_data)) {
      layer_name <- names(raster_data)[i]
      file_name <- paste0(sanitize_fn(layer_name), ".tif")
      terra::writeRaster(raster_data[[i]], filename = file.path(processed_dir, file_name), overwrite = TRUE)
    }
  }
}

# --- Parish-Level Impact (Maps and Rankings) -----------------------------------

# Calculates the population-weighted mean delta travel time per administrative unit.
# Uses parish-level population-weighted mean impact for spatial aggregation (Maps/Rankings).
compute_parish_impact <- function(delta_stack, pop_raster, parish_vect) {
  if (inherits(pop_raster, "list")) {
    idx <- which(names(pop_raster) == "pop_total_10m")
    pop_raster <- if (length(idx) > 0) pop_raster[[idx]] else pop_raster[[1]]
  }
  
  pop_aligned <- align_pop_to_tt(pop_raster, delta_stack)
  
  # Numerator: zonal sum of (delta_TT × population)
  weighted_stack <- delta_stack * pop_aligned
  zonal_weighted_sum <- terra::zonal(weighted_stack, parish_vect, fun = "sum", na.rm = TRUE)
  
  # Denominator: zonal sum of population
  zonal_pop_sum <- terra::zonal(pop_aligned, parish_vect, fun = "sum", na.rm = TRUE)
  
  # Population-weighted mean; guard against division by zero
  # BUGFIX: Apply denominators per-layer, element-wise to handle stacks of varying size
  zonal_pop_sum[zonal_pop_sum == 0] <- NA
  
  avg_weighted_delta <- zonal_weighted_sum / zonal_pop_sum
  names(avg_weighted_delta) <- paste0("Average_Weighted_Delta_TT_", names(delta_stack))
  
  parish_sf <- sf::st_as_sf(parish_vect)
  parish_impact <- cbind(parish_sf, avg_weighted_delta)
  parish_impact$Population_Sum <- zonal_pop_sum[, 1]
  
  return(parish_impact)
}

# Stratified variant of compute_parish_impact(). Partitions pixels into
# vulnerability quartiles (based on provided global breaks or quantile defaults)
# and computes the population-weighted mean delta travel time within each
# quartile × parish combination.
compute_parish_impact_by_quartile <- function(delta_stack, pop_raster, vuln_raster, parish_vect, vuln_breaks = NULL) {
  if (inherits(pop_raster, "list")) {
    idx <- which(names(pop_raster) == "pop_total_10m")
    pop_raster <- if (length(idx) > 0) pop_raster[[idx]] else pop_raster[[1]]
  }
  
  pop_aligned  <- align_pop_to_tt(pop_raster, delta_stack)
  vuln_aligned <- terra::resample(vuln_raster, delta_stack, method = "near")
  vuln_aligned <- terra::mask(vuln_aligned, delta_stack)
  
  # Use provided global breaks or calculate locally from the aligned raster
  brks <- if (!is.null(vuln_breaks)) vuln_breaks else get_global_vuln_breaks(vuln_aligned)
  
  parish_ids <- 1:nrow(parish_vect)
  results_list <- list()
  
  for (q in 1:4) {
    # Binary mask selecting pixels in quartile q
    q_mask <- (vuln_aligned >= brks[q] & vuln_aligned <= brks[q+1])
    pop_q <- pop_aligned * q_mask
    
    weighted_stack_q <- delta_stack * pop_q
    zonal_weighted_sum_q <- terra::zonal(weighted_stack_q, parish_vect, fun = "sum", na.rm = TRUE)
    zonal_pop_sum_q <- terra::zonal(pop_q, parish_vect, fun = "sum", na.rm = TRUE)
    
    # BUGFIX: Apply denominators per-layer, element-wise to handle stacks of varying size
    zonal_pop_sum_q[zonal_pop_sum_q == 0] <- NA
    
    avg_weighted_delta_q <- zonal_weighted_sum_q / zonal_pop_sum_q
    names(avg_weighted_delta_q) <- paste0("Q", q, "_", names(delta_stack))
    
    results_list[[q]] <- avg_weighted_delta_q
  }
  
  all_quartiles_df <- do.call(cbind, results_list)
  parish_sf <- sf::st_as_sf(parish_vect)
  parish_impact_q <- cbind(parish_sf, all_quartiles_df)
  
  return(parish_impact_q)
}

# --- Distribution Analysis & Sampling ---------------------------------------

# Computes summary statistics (Mean, Min, Q25, Median, Q75, Max) of
# delta travel time, grouped by specified columns. Applies population
# weighting (via Hmisc::wtd.mean / wtd.quantile) if a "pop" column
# is present; otherwise computes unweighted statistics.
summarise_impact_metrics <- function(df, group_cols) {
  if ("pop" %in% names(df)) {
    library(Hmisc)
    df %>%
      dplyr::group_by(dplyr::across(dplyr::all_of(group_cols))) %>%
      dplyr::summarise(
        Mean   = round(Hmisc::wtd.mean(delta_tt, weights = pop, na.rm = TRUE), 1),
        Min    = round(min(delta_tt, na.rm = TRUE), 0),
        Q25    = round(Hmisc::wtd.quantile(delta_tt, weights = pop, probs = 0.25, na.rm = TRUE), 0),
        Median = round(Hmisc::wtd.quantile(delta_tt, weights = pop, probs = 0.50, na.rm = TRUE), 0),
        Q75    = round(Hmisc::wtd.quantile(delta_tt, weights = pop, probs = 0.75, na.rm = TRUE), 0),
        Max    = round(max(delta_tt, na.rm = TRUE), 0),
        .groups = "drop"
      )
  } else {
    df %>%
      dplyr::group_by(dplyr::across(dplyr::all_of(group_cols))) %>%
      dplyr::summarise(
        Mean   = round(mean(delta_tt, na.rm = TRUE), 1),
        Min    = round(min(delta_tt, na.rm = TRUE), 0),
        Q25    = round(quantile(delta_tt, 0.25, na.rm = TRUE), 0),
        Median = round(median(delta_tt, na.rm = TRUE), 0),
        Q75    = round(quantile(delta_tt, 0.75, na.rm = TRUE), 0),
        Max    = round(max(delta_tt, na.rm = TRUE), 0),
        .groups = "drop"
      )
  }
}

# Draws a stratified random sample from a pixel-level data frame,
# preserving the Duration × Intensity × FacilityType grouping.
# Seed is fixed at 834 for reproducibility.
sample_weighted_pixels <- function(df, n_sample = 100000) {
  df %>%
    dplyr::group_by(Duration, Intensity, FacilityType) %>%
    dplyr::group_modify(~ {
      dur_val <- as.numeric(gsub("[^0-9.]", "", .y$Duration))
      int_val <- as.numeric(as.character(.y$Intensity))
      grp_seed <- as.integer(834 + (int_val * 100) + round(dur_val))
      set.seed(grp_seed)
      
      if(nrow(.) <= n_sample) return(.)
      else dplyr::sample_n(., n_sample)
    }) %>%
    dplyr::ungroup()
}

# Extracts per-pixel delta travel time values stratified by vulnerability
# quartile. If sample_n is specified, draws a population-weighted random
# sample per scenario to reduce memory consumption; otherwise retains all
# valid pixels with their population weights. Uses precomputed global
# vulnerability breaks to ensure cohort stability across scenarios.
extract_pixels_by_vuln <- function(delta_stack, pop_raster, vuln_raster, facility_label, sample_n = NULL, vuln_breaks = NULL) {
  if (inherits(pop_raster, "list")) {
    idx <- which(names(pop_raster) == "pop_total_10m")
    pop_raster <- if (length(idx) > 0) pop_raster[[idx]] else pop_raster[[1]]
  }
  
  # Calculate global breaks if not provided
  brks <- if (!is.null(vuln_breaks)) vuln_breaks else get_global_vuln_breaks(vuln_raster)
  
  out_list <- list()
  for (i in 1:terra::nlyr(delta_stack)) {
    s_name <- terra::names(delta_stack)[i]
    current_layer <- delta_stack[[i]]
    
    # Perform alignment and masking per scenario to ensure structural parity
    pop_aligned  <- align_pop_to_tt(pop_raster, current_layer)
    vuln_aligned <- terra::resample(vuln_raster, current_layer, method = "near")
    vuln_aligned <- terra::mask(vuln_aligned, current_layer)
    
    pop_vals  <- terra::values(pop_aligned, mat = FALSE)
    vuln_vals <- terra::values(vuln_aligned, mat = FALSE)
    d_vals    <- terra::values(current_layer, mat = FALSE)
    
    valid_idx <- which(!is.na(pop_vals) & !is.na(vuln_vals) & pop_vals > 0 & !is.na(d_vals))
    if (length(valid_idx) == 0) next
    
    # Assign vulnerability quartiles using fixed global breaks
    vuln_q_vals_all <- cut(vuln_vals, breaks = brks, include.lowest = TRUE, labels = c("Q1", "Q2", "Q3", "Q4"))
    
    s_info    <- extract_scenario_info(s_name)
    sample_idx <- valid_idx
    
    if (!is.null(sample_n)) {
      layer_seed <- as.integer(834 + s_info$Intensity * 100 + round(s_info$Duration_hr))
      set.seed(layer_seed)
      
      n <- min(length(valid_idx), sample_n)
      sample_idx <- sample(valid_idx, size = n, replace = TRUE, prob = pop_vals[valid_idx])
    }
    
    out_list[[i]] <- data.frame(
      delta_tt = d_vals[sample_idx],
      pop = if (is.null(sample_n)) pop_vals[sample_idx] else 1,
      vuln_quartile = vuln_q_vals_all[sample_idx],
      Intensity = s_info$Intensity,
      Duration = s_info$Duration_label,
      FacilityType = facility_label,
      scenario = s_name
    )
  }
  dplyr::bind_rows(out_list)
}

# Computes the mean vulnerability index value per parish via zonal extraction.
compute_parish_vuln <- function(vuln_raster, parish_vect) {
  vuln_vals <- terra::extract(vuln_raster, parish_vect, fun = mean, na.rm = TRUE)
  parish_vect$vulnerability <- vuln_vals[, 2]
  return(st_as_sf(parish_vect))
}

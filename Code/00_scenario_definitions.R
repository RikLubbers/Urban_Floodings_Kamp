# 00_scenario_definitions.R
# Defines the full factorial design of 15 pluvial flood scenarios
# (5 rainfall intensities × 3 storm durations) and identifies the subset
# of 6 main scenarios used in the primary manuscript analysis.

library(dplyr)
library(tibble)

# Experimental design parameters
rainfall_levels <- c(20, 40, 60, 80, 100)
duration_levels <- c(1, 3, 6)

# Canonical scenario definitions table
scenario_definitions <- expand.grid(
  duration_hr = duration_levels,
  rainfall_mm = rainfall_levels
) %>%
  as_tibble() %>%
  arrange(rainfall_mm, duration_hr) %>%
  mutate(
    scenario_index = row_number(),
    duration_s    = duration_hr * 3600,
    label         = paste0(rainfall_mm, "mm_", duration_hr, "h"),
    label_plot    = paste0(rainfall_mm, " mm / ", duration_hr, " hr"),
    # Main scenarios: 20, 60, 100 mm at 1 hr and 6 hr durations
    is_main       = (rainfall_mm %in% c(20, 60, 100)) & (duration_hr %in% c(1, 6)),
    id_hours      = paste0(rainfall_mm, "_", duration_hr),
    id_sec        = paste0(rainfall_mm, "_", duration_s),
    scenario_id   = paste0("flood_", id_hours)
  ) %>%
  dplyr::select(
    scenario_index, rainfall_mm, duration_hr, duration_s, 
    label, label_plot, is_main, id_hours, id_sec, scenario_id
  )

# Convenience subsets
scenarios_all  <- scenario_definitions
scenarios_main <- scenario_definitions %>% filter(is_main)

message("Scenario definitions loaded: 15 total, 6 main.")

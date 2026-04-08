# 99_Consolidate_Source_Data.R
# Consolidates individual Figure Source Data Excel files into a single
# Source_Data.xlsx workbook with named worksheets for each figure.

source(here::here("Code/utils/loading_utils.R"))
library(readxl)
library(writexl)

# Define file paths for individual figure source data
sd_dir <- here::here("Data", "Source_Data")
message("Consolidating Source Data from: ", sd_dir)

sd_files <- list.files(sd_dir, pattern = "Source_Data_Figure.*\\.xlsx", full.names = TRUE)
message("Found ", length(sd_files), " individual Source Data files.")

if (length(sd_files) == 0) {
  warning("No individual Source Data files found in: ", sd_dir, ". Skipping consolidation until figures are rendered successfully.")
} else {
  # Load each file into a named list of dataframes
# Note: Figure 2 contains multiple sheets (Panel_a, Panel_b)
combined_data <- list()

for (f in sd_files) {
  fig_num <- gsub("Source_Data_Figure|\\.xlsx", "", basename(f))
  
  # Check if the file has multiple sheets
  sheets <- excel_sheets(f)
  
  if (length(sheets) > 1) {
    for (s in sheets) {
      sheet_name <- paste0("Figure ", fig_num, " (", s, ")")
      combined_data[[sheet_name]] <- read_excel(f, sheet = s)
    }
  } else {
    sheet_name <- paste0("Figure ", fig_num)
    combined_data[[sheet_name]] <- read_excel(f)
  }
}

  # Save consolidated workbook
  out_file <- here::here("Data", "Source_Data.xlsx")
  write_xlsx(combined_data, path = out_file)
  
  message("Source Data consolidated into: ", out_file)
}

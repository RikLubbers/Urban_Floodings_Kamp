library(officer)
library(magrittr)
library(dplyr)
library(stringr)
library(here)

# ------------------------------------------------------------------------------
# Script: 98_Export_Manuscript_Captions.R
# Purpose: Programmatically harvest Figure/Table titles and captions from QMD files
# and export them to a formatted Word document.
# ------------------------------------------------------------------------------

# Define the inventory of files to scan
# Ordered by manuscript appearance
inventory <- list(
  # Main Figures
  list(file = "Code/1_Data_loading_baseline/02_Baseline_geography.qmd", label = "Figure 1"),
  list(file = "Code/2_delta_travel_time/02.1_Baseline_Accessibility_Main.qmd", label = "Figure 2"),
  list(file = "Code/3_Pop_impact/03.1_Pop_Impact_Main.qmd", label = "Figure 3"),
  list(file = "Code/3_Pop_impact/03.1_Pop_Impact_Main.qmd", label = "Figure 4"),
  list(file = "Code/4_Vulnerability_index_impact/04.2_Vulnerability_Impact_Main.qmd", label = "Figure 5"),
  list(file = "Code/4_Vulnerability_index_impact/04.2_Vulnerability_Impact_Main.qmd", label = "Figure 6"),
  
  # Main Tables
  list(file = NA, label = "Table 1"),
  list(file = "Code/3_Pop_impact/03.1_Pop_Impact_Main.qmd", label = "Table 2"),
  list(file = "Code/4_Vulnerability_index_impact/04.2_Vulnerability_Impact_Main.qmd", label = "Table 3"),
  
  # Supplementary Materials
  list(file = NA, label = "Supplementary Table 1"),
  list(file = "Code/2_delta_travel_time/02.1S_Baseline_Accessibility_Supp.qmd", label = "Supplementary Table 2"),
  list(file = "Code/3_Pop_impact/03.1S_Pop_Impact_Supp.qmd", label = "Supplementary Data 1"),
  list(file = "Code/4_Vulnerability_index_impact/04.2S_Vulnerability_Impact_Supp.qmd", label = "Supplementary Data 2"),
  list(file = "Code/4_Vulnerability_index_impact/04.1_Index_equal_weight.qmd", label = "Supplementary Figure 1"),
  list(file = "Code/4_Vulnerability_index_impact/04.1B_PCA_and_Comparison.qmd", label = "Supplementary Figure 2"),
  list(file = "Code/3_Pop_impact/03.1S_Pop_Impact_Supp.qmd", label = "Supplementary Figure 3"),
  list(file = "Code/3_Pop_impact/03.1S_Pop_Impact_Supp.qmd", label = "Supplementary Figure 4"),
  list(file = "Code/4_Vulnerability_index_impact/04.2S_Vulnerability_Impact_Supp.qmd", label = "Supplementary Figure 5"),
  list(file = "Code/4_Vulnerability_index_impact/04.2S_Vulnerability_Impact_Supp.qmd", label = "Supplementary Figure 6"),
  list(file = "Code/3_Pop_impact/03.1S_Pop_Impact_Supp.qmd", label = "Supplementary Figure 7"),
  list(file = "Code/4_Vulnerability_index_impact/04.2S_Vulnerability_Impact_Supp.qmd", label = "Supplementary Figure 8")
)

# Initialize Word Document
doc <- read_docx() %>%
  body_add_par("Manuscript Figures and Tables: Titles and Captions", style = "heading 1") %>%
  body_add_par(paste("Generated on:", Sys.Date()), style = "Normal") %>%
  body_add_break()

# Function to extract caption parts
extract_caption <- function(file_path, label_tag) {
  if (!file.exists(file_path)) return(list(title = "[File Not Found]", caption = "[N/A]"))
  
  lines <- readLines(file_path, warn = FALSE)
  
  # Find the indices containing the label_tag (e.g., "Figure 1")
  # We prioritise matches in comments to avoid finding the label in the code itself if possible
  all_indices <- which(str_detect(lines, fixed(label_tag)))
  if (length(all_indices) == 0) return(list(title = "[Tag Not Found]", caption = "[N/A]"))
  
  # Scan around each occurrence for Title/Caption
  # If we find them near one occurrence, we take it
  for (idx in all_indices) {
    search_range <- max(1, idx - 25):min(length(lines), idx + 25)
    block_lines <- lines[search_range]
    
    title_line <- block_lines[str_detect(block_lines, "#\\s*Title:")]
    caption_line <- block_lines[str_detect(block_lines, "#\\s*Caption:")]
    
    if (length(title_line) > 0 || length(caption_line) > 0) {
      title <- if (length(title_line) > 0) str_replace(title_line[1], ".*?#\\s*Title:\\s*", "") else "[Title Missing]"
      caption <- if (length(caption_line) > 0) str_replace(caption_line[1], ".*?#\\s*Caption:\\s*", "") else "[Caption Missing]"
      return(list(title = title, caption = caption))
    }
  }
  
  return(list(title = "[Metadata Near Tag Missing]", caption = "[Metadata Near Tag Missing]"))
}

# Process Inventory
for (item in inventory) {
  if (item$label == "Table 1") {
    info <- list(
      title = "Walking speeds by land cover and road class under baseline and flood conditions.",
      caption = "Walking speeds, in km h\u207B\u00B9, assigned to land cover types and road classes under baseline and flood conditions. Flood-phase speeds reflect reduced mobility under inundation. \u2018Bare areas\u2019 correspond primarily to dry riverbeds or sandbanks identified in land cover data."
    )
  } else if (item$label == "Supplementary Table 1") {
    info <- list(
      title = "Geospatial data sources used in the analysis.",
      caption = "Summary of key geospatial datasets, their providers, and native spatial resolutions used in the accessibility modelling pipeline."
    )
  } else {
    info <- extract_caption(here(item$file), item$label)
  }
  
  doc <- doc %>%
    body_add_par(item$label, style = "Normal") %>%
    # Bold Title
    body_add_par(paste0(item$label, ". ", info$title), style = "Normal") %>%
    # Regular Caption
    body_add_par(info$caption, style = "Normal") %>%
    body_add_par("", style = "Normal") # Spacer
}

# Export
output_path <- here("Tables", "Manuscript_Captions.docx")
if (!dir.exists(dirname(output_path))) dir.create(dirname(output_path), recursive = TRUE)

print(doc, target = output_path)
message("Captions exported to: ", output_path)

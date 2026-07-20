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

# Inventory, ordered by type and number to match the submitted caption list.
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

  # Supplementary Figures
  list(file = "Code/4_Vulnerability_index_impact/04.1_Index_equal_weight.qmd", label = "Supplementary Figure 1"),
  list(file = "Code/4_Vulnerability_index_impact/04.1B_PCA_and_Comparison.qmd", label = "Supplementary Figure 2"),
  list(file = "Code/3_Pop_impact/03.1S_Pop_Impact_Supp.qmd", label = "Supplementary Figure 3"),
  list(file = "Code/3_Pop_impact/03.1S_Pop_Impact_Supp.qmd", label = "Supplementary Figure 4"),
  list(file = "Code/4_Vulnerability_index_impact/04.2S_Vulnerability_Impact_Supp.qmd", label = "Supplementary Figure 5"),
  list(file = "Code/4_Vulnerability_index_impact/04.2S_Vulnerability_Impact_Supp.qmd", label = "Supplementary Figure 6"),
  list(file = "Code/3_Pop_impact/03.1S_Pop_Impact_Supp.qmd", label = "Supplementary Figure 7"),
  list(file = "Code/4_Vulnerability_index_impact/04.2S_Vulnerability_Impact_Supp.qmd", label = "Supplementary Figure 8"),
  list(file = "Code/4_Vulnerability_index_impact/04.3_Spatial_association.qmd", label = "Supplementary Figure 9"),
  list(file = "Code/4_Vulnerability_index_impact/04.3_Spatial_association.qmd", label = "Supplementary Figure 10"),
  list(file = "Code/4_Vulnerability_index_impact/04.1C_RWI_Comparison.qmd", label = "Supplementary Figure 11"),

  # Supplementary Tables
  list(file = NA, label = "Supplementary Table 1"),
  list(file = "Code/2_delta_travel_time/02.1S_Baseline_Accessibility_Supp.qmd", label = "Supplementary Table 2"),
  list(file = "Code/4_Vulnerability_index_impact/04.3_Spatial_association.qmd", label = "Supplementary Table 3"),

  # Supplementary Data
  list(file = "Code/3_Pop_impact/03.1S_Pop_Impact_Supp.qmd", label = "Supplementary Data 1"),
  list(file = "Code/4_Vulnerability_index_impact/04.2S_Vulnerability_Impact_Supp.qmd", label = "Supplementary Data 2")
)

# Initialize Word Document
doc <- read_docx() %>%
  body_add_par("Manuscript Figures and Tables: Titles and Captions", style = "heading 1") %>%
  body_add_par(paste("Generated on:", Sys.Date()), style = "Normal") %>%
  body_add_break()

# Lines that export a labelled item; each acts as the anchor for that label.
anchor_lines <- function(lines) {
  which(str_detect(lines, '"(Figure|Table|Supplementary (Figure|Table|Data)) [0-9]+"'))
}

# Extracts the Title/Caption pair belonging to `label_tag`.
#
# Metadata sits directly above the export call in most files but below it in
# 02_Baseline_geography.qmd, so the nearest pair in either direction is taken.
# Pairs separated from the anchor by another label's export call belong to that
# other item and are rejected, which is what previously caused Figure 6 and
# Table 3 to inherit Figure 5's caption.
extract_caption <- function(file_path, label_tag) {
  if (!file.exists(file_path)) return(list(title = "[File Not Found]", caption = "[N/A]"))

  lines <- readLines(file_path, warn = FALSE)

  anchor <- which(str_detect(lines, fixed(paste0('"', label_tag, '"'))))
  if (length(anchor) == 0) return(list(title = "[Tag Not Found]", caption = "[N/A]"))
  anchor <- anchor[1]

  anchors <- setdiff(anchor_lines(lines), anchor)
  titles <- which(str_detect(lines, "^\\s*#\\s*Title:"))
  if (length(titles) == 0) return(list(title = "[Title Missing]", caption = "[Caption Missing]"))

  # Reject any title block with another export call between it and our anchor
  blocked <- vapply(titles, function(t) {
    lo <- min(t, anchor); hi <- max(t, anchor)
    any(anchors > lo & anchors < hi)
  }, logical(1))
  titles <- titles[!blocked]
  if (length(titles) == 0) return(list(title = "[Title Missing]", caption = "[Caption Missing]"))

  t_idx <- titles[which.min(abs(titles - anchor))]
  title <- str_replace(lines[t_idx], ".*?#\\s*Title:\\s*", "")

  # The caption is the first "# Caption:" line following its title
  c_idx <- which(str_detect(lines, "^\\s*#\\s*Caption:") & seq_along(lines) > t_idx)
  caption <- if (length(c_idx) > 0 && c_idx[1] - t_idx <= 3) {
    str_replace(lines[c_idx[1]], ".*?#\\s*Caption:\\s*", "")
  } else {
    "[Caption Missing]"
  }

  list(title = title, caption = caption)
}

# Process Inventory
for (item in inventory) {
  if (item$label == "Table 1") {
    info <- list(
      title = "Walking speeds by land cover and road class under baseline and flood conditions.",
      caption = "Walking speeds, in km h⁻¹, assigned to land cover types and road classes under baseline and flood conditions. Flood-phase speeds reflect reduced mobility under inundation. ‘Bare areas’ correspond primarily to dry riverbeds or sandbanks identified in land cover data."
    )
  } else if (item$label == "Supplementary Table 1") {
    info <- list(
      title = "Geospatial data sources used in the analysis.",
      caption = "Summary of key geospatial datasets, their providers, and native spatial resolutions used in the accessibility modelling pipeline."
    )
  } else {
    info <- extract_caption(here(item$file), item$label)
  }

  if (str_detect(info$title, "^\\[") || str_detect(info$caption, "^\\[")) {
    warning("Caption harvest incomplete for ", item$label, ": ", info$title, " / ", info$caption)
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

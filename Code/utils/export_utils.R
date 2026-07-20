# export_utils.R
# Standardised filename construction and export wrappers for manuscript
# figures (PDF) and tables (DOCX/XLSX).

library(here)
library(ggplot2)
library(flextable)
library(officer)
library(writexl)

# --- Bivariate Palettes ------------------------------------------------------

# Custom bivariate palettes following the "corners model" of Strode et al.
# (2020, Cartographic Perspectives 94): the high-high corner is the focal cell
# and carries the message, so it is the most saturated colour in the grid.
# Corner anchors: #F2F2F0 grey (both low), #EE9B00 amber (x high only),
# #0A9396 teal (y high only), #9B2226 crimson (both high).
# The amber x-axis is what keeps the grid readable under red-green deficiency.
# Minimum pairwise Lab distance, 4x4: 13.0 normal, 12.5 deuteranopia,
# 12.1 protanopia, 10.5 tritanopia (Nowosad safety threshold is 6).
bivar_pal_3 <- c(
  "1-1" = "#F2F2F0", "2-1" = "#F0C678", "3-1" = "#EE9B00",
  "1-2" = "#7EC2C3", "2-2" = "#A1906B", "3-2" = "#C45E13",
  "1-3" = "#0A9396", "2-3" = "#525A5E", "3-3" = "#9B2226"
)

bivar_pal_4 <- c(
  "1-1" = "#F2F2F0", "2-1" = "#F0D5A0", "3-1" = "#EFB850", "4-1" = "#EE9B00",
  "1-2" = "#A4D2D2", "2-2" = "#B3B290", "3-2" = "#C3924E", "4-2" = "#D2720C",
  "1-3" = "#57B2B4", "2-3" = "#778F80", "3-3" = "#966D4C", "4-3" = "#B64A19",
  "1-4" = "#0A9396", "2-4" = "#3A6D70", "3-4" = "#6A474B", "4-4" = "#9B2226"
)

# --- Filename Construction ---------------------------------------------------

# Constructs the full path for a manuscript figure, creating the target
# directory if it does not exist.
get_fig_path <- function(name, subdir = "Main", ext = "pdf") {
  dir_path <- here("Figures", subdir)
  if (!dir.exists(dir_path)) dir.create(dir_path, recursive = TRUE)
  file.path(dir_path, paste0(name, ".", ext))
}

# Constructs the full path for a manuscript table, creating the target
# directory if it does not exist.
get_table_path <- function(name, subdir = "Main", ext = "docx") {
  dir_path <- here("Tables", subdir)
  if (!dir.exists(dir_path)) dir.create(dir_path, recursive = TRUE)
  file.path(dir_path, paste0(name, ".", ext))
}

# --- Export Wrappers ---------------------------------------------------------

# Exports a ggplot object to PDF at standardised manuscript dimensions (cm).
save_manuscript_pdf <- function(plot, name, subdir = "Main", width = 18, height = 15) {
  dest <- get_fig_path(name, subdir, "pdf")
  message("Exporting figure: ", dest)
  ggsave(
    filename = dest,
    plot = plot,
    width = width,
    height = height,
    units = "cm",
    device = cairo_pdf
  )
}

# Exports a flextable to a Word document (.docx) with a heading title.
# When pdf = TRUE, additionally writes a PDF rendering of the table (matching
# the .docx + .pdf pairing used for the other supplementary tables). The PDF is
# produced from a grid grob, so no headless browser (webshot/chromote) is needed.
save_manuscript_table <- function(ft, name, subdir = "Main", title = "", pdf = FALSE) {
  dest <- get_table_path(name, subdir, "docx")
  message("Exporting table: ", dest)

  # Ensure title uses "Supplementary Table" if in Supp subdir
  if (subdir == "Supp" && !grepl("Supplementary Table", title) && nzchar(title)) {
    title <- gsub("Table S", "Supplementary Table ", title)
  }

  doc <- read_docx()
  if (nzchar(title)) {
    doc <- doc %>% body_add_par(title, style = "heading 1")
  }

  doc <- doc %>% body_add_flextable(ft)

  print(doc, target = dest)

  if (pdf) {
    pdf_dest <- get_table_path(name, subdir, "pdf")
    message("Exporting table (PDF): ", pdf_dest)
    fdim <- flextable::flextable_dim(ft)   # total width/height in inches
    grob <- flextable::gen_grob(ft, fit = "auto", just = "centre")
    grDevices::cairo_pdf(pdf_dest, width = fdim$width + 0.2, height = fdim$height + 0.2)
    grid::grid.newpage()
    grid::grid.draw(grob)
    grDevices::dev.off()
  }
}

# Exports a dataframe or list of dataframes to an Excel file (.xlsx) 
# for Supplementary Data or Source Data.
save_excel_data <- function(data_obj, name, subdir = "Source_Data") {
  dir_path <- here("Data", subdir)
  if (!dir.exists(dir_path)) dir.create(dir_path, recursive = TRUE)
  dest <- file.path(dir_path, paste0(name, ".xlsx"))
  
  message("Exporting Excel data: ", dest)
  writexl::write_xlsx(data_obj, path = dest)
}

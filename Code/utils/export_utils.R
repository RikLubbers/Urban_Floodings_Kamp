# export_utils.R
# Standardised filename construction and export wrappers for manuscript
# figures (PDF) and tables (DOCX/XLSX).

library(here)
library(ggplot2)
library(flextable)
library(officer)
library(writexl)

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
save_manuscript_table <- function(ft, name, subdir = "Main", title = "") {
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

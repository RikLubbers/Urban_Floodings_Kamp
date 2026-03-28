# export_utils.R
# Standardised filename construction and export wrappers for manuscript
# figures (PDF) and tables (DOCX).

library(here)
library(ggplot2)
library(flextable)
library(officer)

# --- Filename Construction ---------------------------------------------------

# Constructs the full path for a manuscript figure, creating the target
# directory if it does not exist.
get_fig_path <- function(name, subdir = "Main", ext = "pdf") {
  dir_path <- here("Figures", "Pdf_final", subdir)
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

# Exports a ggplot object to PDF at standardised manuscript dimensions.
# Default dimensions: 18 × 15 cm. PDF version 1.4 enables alpha transparency;
# Dingbats fonts are disabled for cross-platform compatibility.
save_manuscript_pdf <- function(plot, name, subdir = "Main", width = 18, height = 15) {
  dest <- get_fig_path(name, subdir, "pdf")
  message("Exporting figure: ", dest)
  ggsave(
    filename = dest,
    plot = plot,
    width = width,
    height = height,
    units = "cm",
    version = "1.4",
    useDingbats = FALSE
  )
}

# Exports a flextable to a Word document (.docx) with a heading title.
save_manuscript_table <- function(ft, name, subdir = "Main", title = "") {
  dest <- get_table_path(name, subdir, "docx")
  message("Exporting table: ", dest)
  
  doc <- read_docx() %>%
    body_add_par(title, style = "heading 1") %>%
    body_add_flextable(ft)
  
  print(doc, target = dest)
}

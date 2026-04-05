# R helper functions for the T pipeline
# Handles reading anonymized data and computing clinical summaries

r_read_csv <- function(path) {
  readr::read_delim(path, delim = "|", show_col_types = FALSE)
}

r_write_csv <- function(df, path) {
  readr::write_delim(df, path, delim = "|")
}

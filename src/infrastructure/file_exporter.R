# ==============================================================================
# FILE EXPORTER
# ==============================================================================
# Responsible for exporting results

#' Export results to Excel file
#'
#' @param data Data frame to export
#' @param file_path Output file path
#' @return NULL (side effect: creates file)
export_to_excel <- function(data, file_path) {
  xlsx::write.xlsx(data, file = file_path, row.names = FALSE)
  message(paste("Results exported to:", file_path))
}
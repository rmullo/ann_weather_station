# ==============================================================================
# NORMALIZATION UTILITIES
# ==============================================================================

#' Normalize data using min-max scaling
#'
#' @param x Numeric vector to normalize
#' @return Normalized vector with values between 0 and 1
normalize_minmax <- function(x) {
  return((x - min(x)) / (max(x) - min(x)))
}

#' Denormalize data from min-max scaling
#'
#' @param x_normalized Normalized vector
#' @param x_original Original vector (for min/max reference)
#' @return Denormalized vector in original scale
denormalize_minmax <- function(x_normalized, x_original) {
  return(x_normalized * (max(x_original) - min(x_original)) + min(x_original))
}

# ==============================================================================
# DATA PREPROCESSOR
# ==============================================================================
# Serviços de preprocessamento de dados para machine learning

source("src/utils/normalization.R")
source("src/domain/evapotranspiration_calculator.R")

#' Calculate reference ETo for entire dataset
#'
#' @param df Data frame with weather data
#' @param metadata List with latitude, longitude, altitude
#' @return Data frame with calculated ETo column
calculate_reference_eto <- function(df, metadata) {
  
  # Add progress indicator
  total_rows <- nrow(df)
  progress_interval <- max(1, floor(total_rows / 10))
  
  for (i in 1:nrow(df)) {
    
    # Show progress
    if (i %% progress_interval == 0) {
      message(sprintf("Calculando ETo: %d/%d (%.1f%%)", i, total_rows, (i/total_rows)*100))
    }
    
    # Parse date components safely
    tryCatch({
      date_parts <- unlist(strsplit(as.character(df[i, 1]), "-"))
      if (length(date_parts) != 3) {
        df[i, 'mes'] <- NA
        df[i, 23] <- NA
        next
      }
      
      day <- as.numeric(date_parts[3])
      month <- as.numeric(date_parts[2])
      year <- as.numeric(date_parts[1])
      df[i, 'mes'] <- month
      
      # Extract weather variables with safe conversion
      hour <- as.numeric(as.character(df[i, 2]))
      solar_radiation <- as.numeric(as.character(df[i, 8])) / 1000  # Convert kJ to MJ
      wind_speed <- as.numeric(as.character(df[i, 22]))
      rh_max <- as.numeric(as.character(df[i, 17]))
      rh_min <- as.numeric(as.character(df[i, 18]))
      relative_humidity <- (rh_max + rh_min) / 2
      t_max <- as.numeric(as.character(df[i, 12]))
      t_min <- as.numeric(as.character(df[i, 13]))
      
      # Calculate ETo
      df[i, 23] <- calculate_hourly_eto(
        t_max = t_max,
        t_min = t_min,
        altitude = metadata$altitude,
        relative_humidity = relative_humidity,
        wind_speed = wind_speed,
        solar_radiation = solar_radiation,
        hour = hour,
        day = day,
        month = month,
        year = year,
        latitude = metadata$latitude,
        longitude = metadata$longitude
      )
      
    }, error = function(e) {
      # Silently skip problematic rows
      df[i, 'mes'] <- NA
      df[i, 23] <- NA
    })
  }
  
  message("Cálculo de ETo concluído!")
  return(df)
}

#' Prepare data for neural network training
#'
#' @param df Data frame with all features
#' @return List with normalized train and test sets
prepare_training_data <- function(df, train_ratio = 0.8) {
  # Convert all columns to numeric
  for (i in 1:ncol(df)) {
    df[, i] <- as.numeric(as.character(df[, i]))
  }
  
  # Remove date column (first column)
  df <- df[, -1]
  
  # Remove rows with missing values
  rows_before <- nrow(df)
  df_clean <- df[complete.cases(df), ]
  rows_after <- nrow(df_clean)
  
  message(sprintf("Registros totais: %d", rows_before))
  message(sprintf("Registros válidos: %d (%.1f%%)", rows_after, (rows_after/rows_before)*100))
  message(sprintf("Registros removidos: %d (dados faltantes)", rows_before - rows_after))
  
  if (nrow(df_clean) < 100) {
    stop("Poucos dados válidos! Verifique a qualidade do arquivo CSV.")
  }
  
  # Shuffle data
  df_shuffled <- df_clean[sample(nrow(df_clean), nrow(df_clean)), ]
  
  # Normalize all features
  df_normalized <- as.data.frame(lapply(df_shuffled, normalize_minmax))
  
  # Split into train and test sets
  train_size <- floor(nrow(df_normalized) * train_ratio)
  train_set <- df_normalized[1:train_size, ]
  test_set <- df_normalized[(train_size + 1):nrow(df_normalized), ]
  
  return(list(
    train = train_set,
    test = test_set,
    original = df_shuffled
  ))
}

#' Extract input features from dataset
#'
#' @param dataset Data frame with all columns
#' @param feature_names Vector of feature column names
#' @return Data frame with only input features
extract_features <- function(dataset, feature_names) {
  return(subset(dataset, select = feature_names))
}
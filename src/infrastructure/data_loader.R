# ==============================================================================
# DATA LOADER
# ==============================================================================
# Responsável por carregar e estruturar dados meteorológicos

#' Load weather station metadata
#'
#' @param file_path Path to CSV file
#' @return List with latitude, longitude, and altitude
load_station_metadata <- function(file_path) {
  header_data <- read.csv(file = file_path, header = TRUE, fill = TRUE, sep = ";")
  
  metadata <- list(
    latitude = as.numeric(unlist(strsplit(header_data[2, 1], " "))[2]),
    longitude = as.numeric(unlist(strsplit(header_data[3, 1], " "))[2]),
    altitude = as.numeric(unlist(strsplit(header_data[4, 1], " "))[2])
  )
  
  return(metadata)
}

#' Load and standardize weather data
#'
#' @param file_path Path to CSV file
#' @param skip_lines Number of header lines to skip
#' @return Data frame with standardized column names
load_weather_data <- function(file_path, skip_lines) {
  df <- read.csv(
    file = file_path, 
    skip = skip_lines - 1, 
    header = TRUE, 
    fill = TRUE, 
    sep = ";",
    fileEncoding = "latin1"  # Handle special characters
  )
  
  # Print actual column names for debugging
  message("Colunas detectadas no CSV:")
  print(names(df))
  
  # Create a flexible mapping function
  find_column <- function(patterns) {
    for (pattern in patterns) {
      matches <- grep(pattern, names(df), ignore.case = TRUE, value = TRUE)
      if (length(matches) > 0) return(matches[1])
    }
    return(NA)
  }
  
  # Map columns flexibly
  column_mapping <- list(
    ETo = "X",
    data = find_column(c("Data.Medicao", "DATA")),
    hora = find_column(c("Hora.Medicao", "HORA")),
    precipitacao = find_column(c("PRECIPITACAO", "PRECIPITAÇÃO")),
    pressao_atmosferica = find_column(c("PRESSAO.ATMOSFERICA.AO.NIVEL", "PRESSÃO.ATMOSFÉRICA")),
    pressao_atmosferica_maxima = find_column(c("PRESSAO.ATMOSFERICA.MAX", "PRESSÃO.*MAX")),
    pressao_atmosferica_minima = find_column(c("PRESSAO.ATMOSFERICA.MIN", "PRESSÃO.*MIN")),
    pressao_atmosferica_reduzida = find_column(c("PRESSAO.ATMOSFERICA.REDUZIDA", "REDUZIDA")),
    radiacao = find_column(c("RADIACAO.GLOBAL", "RADIAÇÃO", "RADIACAO")),
    temperatura_cpu = find_column(c("TEMPERATURA.DA.CPU", "CPU")),
    temperatura_bulbo_seco = find_column(c("TEMPERATURA.DO.AR", "BULBO.SECO")),
    temperatura_ponto_de_orvalho = find_column(c("PONTO.DE.ORVALHO", "ORVALHO")),
    temperatura_maxima = find_column(c("TEMPERATURA.MAXIMA.NA.HORA", "TEMP.*MAX")),
    temperatura_minima = find_column(c("TEMPERATURA.MINIMA.NA.HORA", "TEMP.*MIN")),
    temperatura_orvalho_maxima = find_column(c("TEMPERATURA.ORVALHO.MAX", "ORVALHO.*MAX")),
    temperatura_orvalho_minima = find_column(c("TEMPERATURA.ORVALHO.MIN", "ORVALHO.*MIN")),
    tensao_bateria = find_column(c("TENSAO.DA.BATERIA", "BATERIA")),
    umidade_relativa_maxima = find_column(c("UMIDADE.REL.*MAX", "UMIDADE.*MAX")),
    umidade_relativa_minima = find_column(c("UMIDADE.REL.*MIN", "UMIDADE.*MIN")),
    umidade_relativa = find_column(c("UMIDADE.RELATIVA.DO.AR", "UMIDADE.REL")),
    vento_direcao = find_column(c("VENTO.*DIRECAO", "DIREÇÃO")),
    vento_rajada = find_column(c("VENTO.*RAJADA", "RAJADA")),
    vento_velocidade = find_column(c("VENTO.*VELOCIDADE", "VELOCIDADE.HORARIA"))
  )
  
  # Create rename vector (only for existing columns)
  rename_vector <- setNames(
    unlist(column_mapping[!is.na(column_mapping)]),
    names(column_mapping[!is.na(column_mapping)])
  )
  
  # Apply renaming
  df <- dplyr::rename(df, !!!rename_vector)
  
  # Check for missing critical columns
  required_cols <- c("data", "hora", "radiacao", "temperatura_bulbo_seco", 
                    "temperatura_maxima", "temperatura_minima", 
                    "umidade_relativa_maxima", "umidade_relativa_minima",
                    "vento_velocidade", "pressao_atmosferica", "precipitacao")
  
  missing_cols <- required_cols[!required_cols %in% names(df)]
  if (length(missing_cols) > 0) {
    warning(paste("Colunas críticas não encontradas:", paste(missing_cols, collapse = ", ")))
  }
  
  return(df)
}

#' Fix date/time shifting issue in the data
#'
#' @param df Data frame with date and hour columns
#' @return Data frame with corrected date/time
fix_datetime_shift <- function(df) {
  temp_data <- c(nrow(df))
  temp_hora <- c(nrow(df))
  
  for (i in 4:nrow(df)) {
    temp_data[i + 3] <- df$data[i]
    temp_hora[i + 3] <- df$hora[i]
  }
  
  for (i in 1:(nrow(df) - 3)) {
    df$data[i] <- temp_data[i]
    df$hora[i] <- temp_hora[i]
  }
  
  return(df)
}
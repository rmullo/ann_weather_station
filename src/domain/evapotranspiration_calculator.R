# ==============================================================================
# EVAPOTRANSPIRATION CALCULATOR
# ==============================================================================
# Implementação da equação de Penman-Monteith FAO-56 para dados horários

#' Calculate hourly reference evapotranspiration using Penman-Monteith FAO-56
#'
#' @param t_max Maximum temperature (°C)
#' @param t_min Minimum temperature (°C)
#' @param altitude Station altitude (m)
#' @param relative_humidity Relative humidity (%)
#' @param wind_speed Wind speed at 2m height (m/s)
#' @param solar_radiation Solar radiation (MJ/m²)
#' @param hour Hour of measurement (0-23)
#' @param day Day of month
#' @param month Month (1-12)
#' @param year Year
#' @param latitude Latitude in decimal degrees
#' @param longitude Longitude in decimal degrees
#' @return Hourly reference evapotranspiration (mm/hour), or NA if invalid inputs
calculate_hourly_eto <- function(t_max, t_min, altitude, relative_humidity, 
                                  wind_speed, solar_radiation, hour, day, 
                                  month, year, latitude, longitude) {
  
  longitude <- abs(longitude)
  t_hourly <- (t_max + t_min) / 2
  
  # Validate inputs
  if (sum(is.na(c(t_hourly, altitude, relative_humidity, wind_speed, solar_radiation))) > 0) {
    return(NA)
  }
  
  # Ensure non-negative solar radiation
  if (solar_radiation < 0) {
    solar_radiation <- 0
  }
  
  # 1. Slope of saturation vapor pressure curve (kPa/°C)
  delta <- (4098 * (0.61088 * exp((17.27 * t_hourly) / (t_hourly + 237.3)))) / 
           ((t_hourly + 237.3)^2)
  
  # 2. Latent heat of vaporization (MJ/kg)
  lambda <- 2.501 - 2.361e-3 * t_hourly
  
  # 3. Atmospheric pressure (kPa)
  pressure <- 101.3 * ((293 - 0.0065 * altitude) / 293)^5.26
  
  # 4. Psychrometric constant (kPa/°C)
  gamma <- 1.63e-3 * pressure / lambda
  
  # 5. Saturation vapor pressure (kPa)
  e_t_max <- 0.61088 * exp((17.27 * t_max) / (t_max + 237.3))
  e_t_min <- 0.61088 * exp((17.27 * t_min) / (t_min + 237.3))
  e_sat <- (e_t_max + e_t_min) / 2
  
  # 6. Actual vapor pressure (kPa)
  e_hourly <- 0.6108 * exp((17.27 * t_hourly) / (t_hourly + 237.3))
  e_actual <- e_hourly * (relative_humidity / 100)
  
  # 7. Julian day
  julian_day <- as.integer(275 * month / 9 - 30 + day) - 2
  
  if (month < 3) {
    julian_day <- julian_day + 2
  }
  
  # Adjust for leap years
  if ((year %% 4) == 0) {
    if ((year %% 100) == 0) {
      if ((year %% 400) == 0 && month > 2) {
        julian_day <- julian_day + 1
      }
    } else if (month > 2) {
      julian_day <- julian_day + 1
    }
  }
  
  # 8. Latitude in radians
  phi <- (pi / 180) * latitude
  
  # 9. Inverse relative distance Earth-Sun
  dr <- 1 + 0.033 * cos((2 * pi / 365) * julian_day)
  
  # 10. Solar declination (rad)
  delta_solar <- 0.409 * sin((2 * pi / 365) * julian_day - 1.39)
  
  # 11. Seasonal correction for solar time
  b <- (2 * pi * (julian_day - 81)) / 364
  sc <- 0.1645 * sin(2 * b) - 0.1255 * cos(b) - 0.025 * sin(b)
  
  # 12. Standard longitude for local time zone
  lz <- if (longitude >= 3) round(longitude / 15, 0) * 15 else 0
  
  # 13. Solar time angle at midpoint of hourly period (rad)
  t <- hour / 100 - 0.5
  omega <- (pi / 12) * ((t + 0.06667 * (lz - longitude) + sc) - 12)
  omega1 <- omega - (pi / 24)
  omega2 <- omega + (pi / 24)
  
  # 14. Extraterrestrial radiation (MJ/m²/hour)
  ra <- (12 * 60 / pi) * 0.082 * dr * 
        ((omega2 - omega1) * sin(phi) * sin(delta_solar) + 
         cos(phi) * cos(delta_solar) * (sin(omega2) - sin(omega1)))
  
  # 15. Clear sky solar radiation (MJ/m²/hour)
  rso <- if (solar_radiation <= 0) 0 else (0.75 + 2 * altitude * 10^(-5)) * ra
  
  # 16. Net shortwave radiation (MJ/m²/hour)
  rns <- (1 - 0.23) * solar_radiation
  
  # Reset Ra to 0 if no net shortwave radiation
  if (rns == 0) {
    ra <- 0
  }
  
  # 17. Net longwave radiation (MJ/m²/hour)
  if (rso <= 0) {
    rnl <- (2.043 * 10^(-10)) * ((t_max + 273.16)^4) * 
           (0.34 - 0.14 * sqrt(e_actual)) * (1.35 * 0.8 - 0.35)
  } else {
    rnl <- (2.043 * 10^(-10)) * ((t_max + 273.16)^4) * 
           (0.34 - 0.14 * sqrt(e_actual)) * (1.35 * (solar_radiation / rso) - 0.35)
  }
  
  # 18. Net radiation (MJ/m²/hour)
  rn <- rns - rnl
  
  # 19. Soil heat flux (MJ/m²/hour)
  g <- if (solar_radiation <= 0) 0.5 * rn else 0.1 * rn
  
  # 20. Penman-Monteith equation for hourly ETo (mm/hour)
  eto <- (0.408 * delta * (rn - g) + (gamma * (37 / (t_hourly + 273)) * 
          wind_speed * (e_sat - e_actual))) / 
         (delta + gamma * (1 + 0.34 * wind_speed))
  
  # Ensure non-negative ETo
  if (eto < 0) {
    eto <- 0
  }
  
  return(round(eto, digits = 2))
}

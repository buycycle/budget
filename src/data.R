# Load necessary libraries
library(dplyr)
library(tidyr)
fill_missing_days <- function(df) {

  #' Fill Missing Days in a Time Series Data Frame
  #'
  #' This function takes a data frame with a date and value columns and
  #' fills in missing days with the previous day's value. The function
  #' returns a new data frame with daily data continuity.
  #'
  #' @param df A data frame containing at least two columns: 'date' and 'value'.
  #'           The 'date' column should be of Date type and sorted in ascending order.
  #' @return A data frame with no missing days. Missing values are filled using
  #'         the Last Observation Carried Forward (LOCF) method.
  #'
  #' @examples
  df$date = as.Date(df$date,  format = "%Y-%m-%d")

  # Ensure the data is sorted by date
  df <- df %>%
    arrange(date)

  # Create a sequence of all days from the min to the max date
  all_dates <- seq(min(df$date), max(df$date), by = "day")

  # Create a complete data frame with all dates
  complete_df <- tibble(date = all_dates) %>%
    left_join(df, by = "date")

  # Fill missing values with the last observation carried forward
  filled_df <- complete_df %>%
    fill(everything(), .direction = "down")

  return(filled_df)
}

approx_weibull <- function(desired_day, target_cdf = 0.95) {
  shape <- 2  # Initial guess for shape
  scale <- desired_day / qweibull(target_cdf, shape, lower.tail = TRUE)
  return(list(shape = shape, scale = scale))
}


assign_hyperparameters <- function(
  paid_media_spends,
  organic_vars,
  alpha_range,
  gamma_range,
  digital_shape,
  digital_scale,
  organic_shape,
  organic_scale,
  tv_shape,
  tv_scale,
  prefix_media = c("ga_", "google_", "meta_", "bing_"),
  prefix_tv = "tv_spent_"
) {
  # Initialize hyperparameters list
  hyperparameters <- list()

  # Construct regular expressions from prefixes
  digital_pattern <- paste0("^(", paste(prefix_media, collapse = "|"), ")")
  tv_pattern <- paste0("^", prefix_tv)

  # Loop over each media type
  for (media in paid_media_spends) {
    if (grepl(digital_pattern, media)) {
      # Set hyperparameters for digital channels
      hyperparameters[[paste0(media, "_alphas")]] <- alpha_range
      hyperparameters[[paste0(media, "_gammas")]] <- gamma_range
      hyperparameters[[paste0(media, "_shapes")]] <- c(0.0001, digital_shape)
      hyperparameters[[paste0(media, "_scales")]] <- c(0, digital_scale)
    } else if (grepl(tv_pattern, media)) {
      # Set hyperparameters for TV channels
      hyperparameters[[paste0(media, "_alphas")]] <- alpha_range
      hyperparameters[[paste0(media, "_gammas")]] <- gamma_range
      hyperparameters[[paste0(media, "_shapes")]] <- c(0.0001, tv_shape)
      hyperparameters[[paste0(media, "_scales")]] <- c(0, tv_scale)
    }
  }
  for (oranic in organic_vars) {
      # Set hyperparameters for digital channels
      hyperparameters[[paste0(organic, "_alphas")]] <- alpha_range
      hyperparameters[[paste0(organic, "_gammas")]] <- gamma_range
      hyperparameters[[paste0(organic, "_shapes")]] <- c(0.0001, organic_shape)
      hyperparameters[[paste0(organic, "_scales")]] <- c(0, organic_scale)
  }

  return(hyperparameters)
}

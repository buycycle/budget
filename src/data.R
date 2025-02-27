# Load necessary libraries
library(dplyr)
library(tidyr)
library(lubridate)
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
  prefix_tv = "tv_"
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
      hyperparameters[[paste0(media, "_thetas")]] <- c(0, 0.3)
    } else if (grepl(tv_pattern, media)) {
      # Set hyperparameters for TV channels
      hyperparameters[[paste0(media, "_alphas")]] <- alpha_range
      hyperparameters[[paste0(media, "_gammas")]] <- gamma_range
      hyperparameters[[paste0(media, "_thetas")]] <- c(0, 0.7)
    }
  }
  for (organic in organic_vars) {
      # Set hyperparameters for digital channels
      hyperparameters[[paste0(organic, "_alphas")]] <- alpha_range
      hyperparameters[[paste0(organic, "_gammas")]] <- gamma_range
      hyperparameters[[paste0(organic, "_thetas")]] <- c(0, 0.3)
  }

  return(hyperparameters)
}

get_future_data <- function(
  historical_df,
  prediction_date_range,
  target_gmv = 12000000
){
  #' build daily spend for future periods based on historical data and monthly targets.
  #'
  #' @param historical_df DataFrame containing historical data.
  #' @param prediction_date_range A vector of Date objects representing the start date and end date. ex: february 2025 -> c("2025-02-01", "2025-03-01")
  #' @param target_gmv Target Gross Merchandise Value to achieve in the future period.
  #'
  #' @return A data frame with daily adjusted numeric columns for the prediction period.

  if (is.null(historical_df)) {
    stop("historical_df is NULL. Please provide historical data.")
    return(NULL)
  }

  print(names(historical_df))
  
  # Function to extend a month's data, df should be complete data of the month
  extend_month_data <- function(df) {
    last_date <- max(df$date)
    target_month_start <- floor_date(last_date + days(1), "month")
    target_month_end <- target_month_start + months(1) - days(1)  # floor_date removed

    last_month_data <- df[month(df$date) == month(last_date) & year(df$date) == year(last_date), ]

    target_days <- seq(target_month_start, target_month_end, by = "day")

    extended_data <- data.frame()
    for (i in 1:length(target_days)) {
      row_index <- min(i, nrow(last_month_data))  
      extended_data <- rbind(extended_data, last_month_data[row_index, ])
      extended_data[i, "date"] <- target_days[i]
    }

    complete_df <- rbind(df, extended_data)
    return(complete_df)
  }

  # Fill missing days in the last month of historical data
  last_date <- max(historical_df$date)
  last_month_end <- floor_date(last_date, "month") + months(1) - days(1)
  missing_days <- as.integer(last_month_end - last_date)

  if (missing_days > 0) {
    last_day_rows <- historical_df %>% filter(date == last_date)
    for (i in 1:missing_days) {
      new_rows <- last_day_rows
      new_rows$date <- last_date + i
      historical_df <- rbind(historical_df, new_rows)
    }
  }

  # Fill missing months and prediction month
  prediction_start <- as.Date(prediction_date_range[1])
  prediction_end <- as.Date(prediction_date_range[2]) - days(1) 

  # Extend to the end of the prediction month
  while (max(historical_df$date) < prediction_end) {  
    historical_df <- extend_month_data(historical_df)
  }

  # Scale based on target_gmv
  prediction_df <- historical_df[historical_df$date >= prediction_start & historical_df$date <= prediction_end, ]

  # Check if the sum is valid (not NA or zero)
  if (is.na(sum(prediction_df$gmv)) || sum(prediction_df$gmv) == 0) {
    stop("The sum of 'gmv' in the prediction period is NA or 0. Scaling cannot be performed.")
  } else {
        scaler <- target_gmv / sum(prediction_df$gmv)
  }

  numeric_cols <- names(prediction_df)[sapply(prediction_df, is.numeric)]
  prediction_df[, numeric_cols] <- prediction_df[, numeric_cols] * scaler

  for (col in numeric_cols) {
    if (is.integer(historical_df[[col]])) {
      prediction_df[[col]] <- as.integer(round(prediction_df[[col]]))
    }
  }
  
  historical_df[historical_df$date >= prediction_start & historical_df$date <= prediction_end, numeric_cols] <- prediction_df[, numeric_cols] 

  if (anyNA(historical_df$country)) {
    print("Warning: NA values found in 'country' column.")
  }

  return(historical_df)
}






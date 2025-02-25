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


predict_data <- function(
  InputCollect,
  OutputCollect,
  select_model,
  prediction_date_range,
  monthly_targets
){
  #' build daily spend for future periods based on historical data and monthly targets.
  #'
  #' @param InputCollect An InputCollect object containing historical data.
  #' @param OutputCollect An OutputCollect object containing Robyn model output.
  #' @param select_model The index or name of the selected Robyn model.
  #' @param prediction_date_range A vector of Date objects representing the start date and end date. ex: february 2025 -> c("2025-02-01", "2025-03-01")
  #' @param monthly_targets A data frame with monthly spend targets for each channel.
  #'
  #' @return A data frame with daily spend for each channel in the prediction period.

  if (is.null(InputCollect$dt_input)) {
    stop("InputCollect$dt_input is NULL. Please provide historical data.")
    returb(NULL)
  }
  df <- InputCollect$dt_input

  # 1. Get the reference month data
  # 1.1 take the previous month as reference month
  pred_month <- month(min(prediction_date_range))
  pred_year <- year(min(prediction_date_range))

  ref_month <- pred_month - 1
  ref_year <- pred_year
  if (ref_month == 0) {  # Handle January
    ref_month <- 12
    ref_year <- ref_year - 1
  }
  reference_month_data <- df %>%
    filter(month(date) == ref_month, year(date) == ref_year)

  # 1.2 if previous data lacks, get the last available month with data
  if (nrow(reference_month_data) == 0) {
    last_available_date <- max(df$date)
    ref_month <- month(last_available_date)
    ref_year <- year(last_available_date)
    reference_month_data <- df %>%
      filter(month(date) == ref_month, year(date) == ref_year)
  }

  # 1.3 Shift the dates in reference_month_data by one month and ensure valid dates
  reference_month_data <- reference_month_data %>%
    mutate(date = as.Date(paste(pred_year, pred_month, day(date), sep = "-"))) %>%
    filter(!is.na(date))  # Remove invalid dates (e.g., February 29th in non-leap years)

  # 1.4 Duplicate data for missing date to match the length of prediction_date_range
  n_days_prediction <- n_days_prediction <- as.numeric(difftime(as.Date(prediction_date_range[2]), as.Date(prediction_date_range[1]), units = "days")) 
  n_days_reference <- as.numeric(difftime(max(reference_month_data$date), min(reference_month_data$date), units = "days")) + 1

  if (n_days_prediction > n_days_reference) {
    last_day <- max(reference_month_data$date)
    last_day_rows <- reference_month_data %>% filter(date == last_day)
    extra_days <- 31 - day(last_day)

    for (i in 1:extra_days) {
      new_rows <- last_day_rows
      new_rows$date <- last_day + i
      reference_month_data <- rbind(reference_month_data, new_rows)
    }
  }

  # 2. Calculate the daily proportions based on the gmv target
  # 2.1 Extract the target GMV from the monthly_targets data
  target_gmv = monthly_targets$target_gmv_eur
  if (is.null(target_gmv)) {
    target_gmv = 12000000
  }

  # 2.2 Calculate the scaler for each channel
  scaler <- target_gmv / sum(reference_month_data$crossborder_gmv)

  # 3. Distribute the optimized spend proportionally, by channel
  future_data <- reference_month_data %>%
    mutate(across(
      -date,
      ~.x * scaler  # Overwrite the existing columns
    ))

  return(future_data)
}





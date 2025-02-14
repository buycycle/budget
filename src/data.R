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
  for (organic in organic_vars) {
      # Set hyperparameters for digital channels
      hyperparameters[[paste0(organic, "_alphas")]] <- alpha_range
      hyperparameters[[paste0(organic, "_gammas")]] <- gamma_range
      hyperparameters[[paste0(organic, "_shapes")]] <- c(0.0001, organic_shape)
      hyperparameters[[paste0(organic, "_scales")]] <- c(0, organic_scale)
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
  
  # 1. Run Robyn Allocator on original data
  validation_date_range <- OutputCollect$calibration_input$date_range

  AllocatorCollect <- robyn_allocator(
    InputCollect = InputCollect,
    OutputCollect = OutputCollect,
    select_model = select_model,
    date_range = validation_date_range,
    total_budget = NULL,
    channel_constr_low = 0.5,
    channel_constr_up = 1.5,
    channel_constr_multiplier = 3,
    scenario = "max_historical_response",
    export = FALSE
  )

  # 2. Calculate Scaling Factor
  scaling_factor <- monthly_targets / sum(AllocatorCollect$opt_alloc$optimised_spend)

  # 3. Extract Optimized Spend and Scale
  scaled_allocation <- AllocatorCollect$opt_alloc %>%
    mutate(optimised_spend = optimised_spend * scaling_factor)

  # 4. Extract Reference Month Data
  # Get previous month's data
  reference_month <- InputCollect$all_data %>%
    filter(
      month(date) == month(min(prediction_date_range)) - 1,  
      year(date) == year(min(prediction_date_range))        
    )

  # If no data for the previous month in the same year, use previous year
  if (nrow(reference_month) == 0){
      reference_month <- InputCollect$all_data %>%
      filter(
        month(date) == 12,
        year(date) < year(min(prediction_date_range)) - 1
      )
  }

  # 5. Calculate the daily proportions
  if (nrow(reference_month) > 0){
    # Number of days in reference and prediction months
    n_days_reference <- nrow(reference_month)
    n_days_prediction <- length(prediction_date_range)

    # Adjust reference_month to match the length of prediction_date_range
    if (n_days_reference < n_days_prediction) {
      # Duplicate last day's data to extend
      extra_days <- n_days_prediction - n_days_reference
      last_row <- reference_month[nrow(reference_month), ]  # Get the last row
      duplicate_rows <- do.call("rbind", replicate(extra_days, last_row, simplify = FALSE))  # Duplicate the last row
      reference_month <- rbind(reference_month, duplicate_rows)  # Add the duplicated rows
    } else if (n_days_reference > n_days_prediction) {
      # Cut off extra days
      reference_month <- reference_month[1:n_days_prediction, ]
    }

    # Ensure the dates in reference_month match prediction_date_range
    reference_month$date <- prediction_date_range

    # calculate the daily proportions
    daily_proportions <- reference_month %>%
      mutate(across(
        all_of(channel_cols),
        ~.x / sum(.x)
      )) %>%
      select(date, all_of(channel_cols)) 

  } else {
    # If no reference month data, distribute evenly
    daily_proportions <- tibble(
      date = prediction_date_range,
    !!!setNames(as.list(rep(1 / length(prediction_date_range), length(channel_cols))), channel_cols)
    )
  }

  # 6. Distribute the optimized spend proportionally, by channel
  future_data <- daily_proportions %>%
    mutate(across(
      all_of(channel_cols),
      ~.x * scaled_allocation$optimised_spend[match(cur_column(), scaled_allocation$channel)]
    )) %>%
    select(date, all_of(channel_cols)) %>%
    mutate(Total = rowSums(across(where(is.numeric)))) %>%
    bind_rows(summarize(., across(where(is.numeric), sum)))
 
  return(future_data)
}





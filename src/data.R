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

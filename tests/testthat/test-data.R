library(testthat)
library(dplyr)
library(lubridate)

# Load the source file containing the predict_data function
source("src/data.R")

# Create mock data for testing
historical_df <- tibble(
    date = seq.Date(from = as.Date("2024-01-01"), to = as.Date("2024-12-31"), by = "day"),
    crossborder_gmv = runif(366, min = 1000, max = 5000),
    ga_supply_search_cost = runif(366, min = 500, max = 2000)  # Add new column with random values
  )

# Save the resulting data frame to a CSV file
output_dir <- "tests/testthat/outputs"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}
write.csv(historical_df, file.path(output_dir, "predict_data_original.csv"), row.names = FALSE)


# Test february prediction
test_that("predict_data returns a data frame with the correct structure", {
  result <- get_future_data(
    historical_df = historical_df,
    prediction_date_range = c("2025-02-01", "2025-03-01"),
    target_gmv = 12000000
  )
  
  expect_s3_class(result, "data.frame")
  expect_true("date" %in% colnames(result))
  expect_true("crossborder_gmv" %in% colnames(result))
  expect_equal(as.numeric(difftime(max(result$date), min(result$date), units = "days")) + 1, 28)
  

  # Save the resulting data frame to a CSV file
  write.csv(result, file.path(output_dir, "predict_data_result.csv"), row.names = FALSE)
})

# Test march prediction
test_that("predict_data returns a data frame with the correct structure", {
  result <- get_future_data(
    historical_df = historical_df,
    prediction_date_range = c("2025-03-01", "2025-04-01"),
    target_gmv = 12000000
  )
  
  expect_s3_class(result, "data.frame")
  expect_true("date" %in% colnames(result))
  expect_true("crossborder_gmv" %in% colnames(result))
  expect_equal(as.numeric(difftime(max(result$date), min(result$date), units = "days")) + 1, 31)
})


test_that("predict_data scales the GMV correctly", {
  result <- get_future_data(
    historical_df = historical_df,
    prediction_date_range = c("2025-03-01", "2025-04-01"),
    target_gmv = 12000000
  )
  
  total_gmv <- sum(result$crossborder_gmv)
  expect_equal(total_gmv, 12000000, tolerance = 1e-6)
})
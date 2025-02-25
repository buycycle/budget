#### Unit Tests for data.R ####

# To run tests, execute `rscript tests/testthat/test-data.R` from the project root.

library(testthat)
library(dplyr)
library(lubridate)

# Load the function to be tested.
source("src/data.R")

## Case 1: Test the case where the prediction period is less than the reference period. Also when the previous month is missing.
# Create mock data for case 1
historical_df <- tibble(
    date = seq.Date(from = as.Date("2024-01-01"), to = as.Date("2024-12-31"), by = "day"),
    crossborder_gmv = runif(366, min = 1000, max = 5000),
    ga_supply_search_cost = runif(366, min = 500, max = 2000)  # Add new column with random values
  )

output_dir <- "tests/testthat/outputs"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}
write.csv(historical_df, file.path(output_dir, "predict_data_original_1.csv"), row.names = FALSE)

# Expect: Data from December is used. Redudant data is removed.
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
  total_gmv <- sum(result$crossborder_gmv)
  expect_equal(total_gmv, 12000000, tolerance = 1e-6)
  
  write.csv(result, file.path(output_dir, "predict_data_result_1.csv"), row.names = FALSE)
})

## Case 2: Test the case where the prediction period is greater than the reference period. The synthetic data is generated for this case.
# Create mock data for case 2
historical_df <- tibble(
    date = seq.Date(from = as.Date("2024-01-01"), to = as.Date("2025-2-28"), by = "day"),
    crossborder_gmv = runif(425, min = 1000, max = 5000),
    ga_supply_search_cost = runif(425, min = 500, max = 2000)  # Add new column with random values
  )

write.csv(historical_df, file.path(output_dir, "predict_data_original_2.csv"), row.names = FALSE)

# Expect: Data from February is used. Synthetic data is generated for the remaining days.
test_that("predict_data returns a data frame with the correct structure", {
  result <- get_future_data(
    historical_df = historical_df,
    prediction_date_range = c("2025-01-01", "2025-02-01"),
    target_gmv = 12000000
  )
  
  expect_s3_class(result, "data.frame")
  expect_true("date" %in% colnames(result))
  expect_true("crossborder_gmv" %in% colnames(result))
  expect_equal(as.numeric(difftime(max(result$date), min(result$date), units = "days")) + 1, 31)
  total_gmv <- sum(result$crossborder_gmv)
  expect_equal(total_gmv, 12000000, tolerance = 1e-6)

  # Save the resulting data frame to a CSV file
  write.csv(result, file.path(output_dir, "predict_data_result_2.csv"), row.names = FALSE)
})



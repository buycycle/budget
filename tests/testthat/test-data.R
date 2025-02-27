#### Unit Tests for data.R ####

# To run tests, execute `rscript tests/testthat/test-data.R` from the project root.

library(testthat)
library(dplyr)
library(lubridate)

# Load the function to be tested.
source("src/data.R")

# Create mock data for case 
historical_df <- tibble(
    date = seq.Date(from = as.Date("2025-01-01"), to = as.Date("2025-02-23"), by = "day"),
    gmv = runif(54, min = 1000, max = 5000), 
    ga_supply_search_cost = runif(54, min = 500, max = 2000),
    country = "DE",
    management_region = "DACH" 
  )

output_dir <- "tests/testthat/outputs"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}
write.csv(historical_df, file.path(output_dir, "predict_data_original.csv"), row.names = FALSE)

# Expect: missing data from Feb is filled and the data in March is scaled to match the target GMV.
test_that("predict_data returns a data frame with the correct structure", {
  result <- get_future_data(
    historical_df = historical_df,
    prediction_date_range = c("2025-03-01", "2025-04-01"),
    target_gmv = 12000000
  )
  
  expect_s3_class(result, "data.frame")
  expect_true("date" %in% colnames(result))
  expect_true("gmv" %in% colnames(result))
  expect_equal(max(result$date), as.Date("2025-03-31"))
  filtered_result <- result %>% filter(date >= as.Date("2025-03-01") & date <= as.Date("2025-03-31"))
  total_gmv <- sum(filtered_result$gmv)
  expect_equal(total_gmv, 12000000, tolerance = 1e-6)
  
  write.csv(result, file.path(output_dir, "predict_data_result_1.csv"), row.names = FALSE)
})

# Expect: missing data from Feb and missing month in March is filled and the data in April is scaled to match the target GMV.
test_that("predict_data returns a data frame with the correct structure", {
  result <- get_future_data(
    historical_df = historical_df,
    prediction_date_range = c("2025-04-01", "2025-05-01"),
    target_gmv = 12000000
  )
  
  expect_s3_class(result, "data.frame")
  expect_true("date" %in% colnames(result))
  expect_true("gmv" %in% colnames(result))
  expect_equal(max(result$date), as.Date("2025-04-30"))
  filtered_result <- result %>% filter(date >= as.Date("2025-04-01") & date <= as.Date("2025-04-30"))
  total_gmv <- sum(filtered_result$gmv)
  expect_equal(total_gmv, 12000000, tolerance = 1e-6)
  
  write.csv(result, file.path(output_dir, "predict_data_result_2.csv"), row.names = FALSE)
})
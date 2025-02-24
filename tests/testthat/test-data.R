library(testthat)
library(dplyr)
library(lubridate)

# Load the source file containing the predict_data function
source("src/data.R")

# Create mock data for testing
InputCollect <- list(
  all_data = tibble(
    date = seq.Date(from = as.Date("2024-01-01"), to = as.Date("2024-12-31"), by = "day"),
    crossborder_gmv = runif(366, min = 1000, max = 5000),
    ga_supply_search_cost = runif(366, min = 500, max = 2000)  # Add new column with random values
  )
)

# Save the resulting data frame to a CSV file
output_dir <- "tests/testthat/outputs"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}
write.csv(InputCollect$all_data, file.path(output_dir, "predict_data_original.csv"), row.names = FALSE)


select_model <- "model_1"
prediction_date_range <- c("2025-02-01", "2025-03-01")
monthly_targets <- tibble(
  target_gmv_eur = 12000000
)

# Define the test cases
test_that("predict_data returns a data frame with the correct structure", {
  result <- predict_data(
    InputCollect = InputCollect,
    OutputCollect = OutputCollect,
    select_model = select_model,
    prediction_date_range = prediction_date_range,
    monthly_targets = monthly_targets
  )
  
  expect_s3_class(result, "data.frame")
  expect_true("date" %in% colnames(result))
  expect_true("crossborder_gmv" %in% colnames(result))

  # Save the resulting data frame to a CSV file
  write.csv(InputCollect$all_data, file.path(output_dir, "predict_data_result.csv"), row.names = FALSE)
})


test_that("predict_data scales the GMV correctly", {
  result <- predict_data(
    InputCollect = InputCollect,
    OutputCollect = OutputCollect,
    select_model = select_model,
    prediction_date_range = prediction_date_range,
    monthly_targets = monthly_targets
  )
  
  total_gmv <- sum(result$crossborder_gmv)
  expect_equal(total_gmv, 12000000, tolerance = 1e-6)
})
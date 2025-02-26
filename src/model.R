library(Robyn)

# Load the reticulate package
library(reticulate)


source("src/data.R")


countries <- list("DE",
                 "FR",
                 "US",
                 "IT",
                 "ES"
)
management_regions <- c(US = "NA",
                 IT = "SEU",
                 ES= "SEU",
                 FR= "FRA",
                 DE= "DACH")

gmv_targets <- c(US = 100000,
                 IT = 150000,
                 ES= 120000,
                 FR= 200000,
                 DE= 200000)

# Loop over the countries and map the GMV target
for (country in countries) {
  management_region <- management_regions[[country]]
  # Access the GMV target for the current country
  gmv_target <- gmv_targets[[country]]

# Construct the command to call the Python script
fetch_data <- sprintf("python src/data.py %s %s", country, management_region)
# Execute the command
system(fetch_data)

# read csv snowflake export
data_path <- "data/data.csv"
df <- read.csv(data_path)

print("Columns in df:")
print(names(df))

df <- fill_missing_days(df)

validation_date_range = c("2024-10-01", "2024-11-01")
reference_data_range = c("2025-02-01", "2025-02-28")
prediction_date_range = c("2025-03-01", "2025-03-31")

# Programmatically define variable types
# 1. Get the column names for potential independent vars
column_names <- names(df)
independent_columns <- setdiff(column_names, c("date", "gmv", "national_gmv", "crossborder_gmv", "management_region", "country"))

# 2. Identify columns with no variance
no_variance_cols <- independent_columns[sapply(df[independent_columns], function(x) length(unique(x)) == 1)]
print(paste("Columns with no variance:", paste(no_variance_cols, collapse = ", ")))
independent_columns <- setdiff(independent_columns, no_variance_cols) # Remove columns with no variance

# 3. Define variables based on column names
paid_media_spends <- independent_columns[grepl("_cost$", independent_columns)]
paid_media_vars <- paid_media_spends
print(paste("paid_media_vars:", paste(paid_media_vars, collapse = ", ")))
organic_vars <- independent_columns[grepl("_sessions$", independent_columns)]
print(paste("organic_vars:", paste(organic_vars, collapse = ", ")))
context_vars <- setdiff(independent_columns, c(paid_media_spends, organic_vars))
print(paste("context_vars:", paste(context_vars, collapse = ", ")))
factor_vars <- intersect(c("tv_is_on"), independent_columns) # Ensure tv_is_on is still available
print(paste("factor_vars:", paste(factor_vars, collapse = ", ")))


# Define hyperparameter for paid_media_vars and organic_vars
# Calculate shape and scale for digital and TV channels
digital_weibull <- approx_weibull(7)
organic_weibull <- approx_weibull(7)
tv_weibull <- approx_weibull(30)

# Derived parameter values for digital, TV and organic
digital_shape <- digital_weibull$shape
# bing_competitor_cost_scales's hyperparameter must have upper bound <=1
digital_scale <- pmin(digital_weibull$scale, 1) # Ensure upper bound of 1

organic_shape <- organic_weibull$shape
organic_scale <- pmin(organic_weibull$scale, 1)

tv_shape <- tv_weibull$shape
tv_scale <- tv_weibull$scale

# Define parameter ranges and fits
alpha_range <- c(0.5, 3)
gamma_range <- c(0.3, 1)

# Assign hyperparameters with custom prefixes
hyperparameters <- assign_hyperparameters(
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
)

# Print the assigned hyperparameters for debugging
print("Assigned hyperparameters:")
for (name in names(hyperparameters)) {
  print(paste(name, ":", paste(hyperparameters[[name]], collapse = ", ")))
}

InputCollect <- robyn_inputs(
  dt_input = df,
  dt_holidays = dt_prophet_holidays,
  date_var = "date",

  dep_var = "gmv", # there should be only one dependent variable
  dep_var_type = "revenue", # "revenue" (roi) or "conversion" (cpa)

  prophet_vars = c("trend","season", "weekday", "holiday"),
  prophet_country = country,

  context_vars = context_vars,
  paid_media_spends = paid_media_spends,
  paid_media_vars = paid_media_vars,
  organic_vars = organic_vars,
  factor_vars = factor_vars,
  hyperparameters=hyperparameters,
  adstock = "geometric" # geometric, weibull_cdf or weibull_pdf.
)

hyper_names(adstock = InputCollect$adstock, all_media = InputCollect$all_media)

InputCollect <- robyn_inputs(InputCollect = InputCollect)

OutputModel <- robyn_run(
  InputCollect = InputCollect,
  cores = 8, # Number of CPU cores to use
  iterations = 2000, # Number of iterations for the model
  trials = 1, # Number of trials for hyperparameter optimization, should be >= 5
  ts_validation = TRUE,
  train_size = 0.9
)

saveRDS(OutputModel, file = "data/OutputModel.rds")

OutputCollect <- robyn_outputs(
  InputCollect, OutputModel,
  # pareto_fronts = "auto",
  csv_out = "pareto", # "pareto", "all", or NULL (for none)
  clusters = TRUE, # Set to TRUE to cluster similar models by ROAS. See ?robyn_clusters
  plot_pareto = TRUE, # Set to FALSE to deactivate plotting and saving model one-pagers
  plot_folder = "plot/", # path for plots export
  export = FALSE # this will create files locally
)



# Automatically select the model with the best combined score
pareto_models <- OutputCollect$allSolutions
metrics <- OutputCollect$resultHypParam[OutputCollect$resultHypParam$solID %in% pareto_models, ]

# Calculate combined score (lower is better)
metrics$score <- sqrt(metrics$nrmse^2 + metrics$decomp.rssd^2)


# Select the best model
best_model <- metrics$solID[which.min(metrics$score)]
select_model <- best_model

# For safety, you might want to add:
if(length(select_model) == 0) {
  stop("No valid model selected. Check model selection logic.")
}

print(paste("Automatically selected model:", select_model))

#### Since 3.7.1: JSON export and import (faster and lighter than RDS files)
#ExportedModel <- robyn_write(InputCollect, OutputCollect, select_model)

#run historic max_response Budget Allocator.
HistoricAllocatorCollect <- robyn_allocator(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  date_range = validation_date_range,
  total_budget = NULL, # When NULL, use total spend of date_range
  channel_constr_low = 0.5,
  channel_constr_up = 1.5,
  channel_constr_multiplier = 3,
  scenario = "max_historical_response",
  export = TRUE
)

# Predict future values
PredictedData <- get_future_data(
  historical_df = df,
  prediction_date_range = prediction_date_range,
  target_gmv = gmv_target
)

print("ran future data generation")
InputCollectPredict <- robyn_inputs(
  dt_input = PredictedData,
  dt_holidays = dt_prophet_holidays,
  date_var = "date",

  dep_var = "gmv", # there should be only one dependent variable
  dep_var_type = "revenue", # "revenue" (roi) or "conversion" (cpa)

  prophet_vars = c("trend","season", "weekday"),  #"trend","season", "weekday" & "holiday"
  prophet_country = country, # input one country. dt_prophet_holidays includes 59 countries by default

  context_vars = context_vars,
  paid_media_spends = paid_media_spends,
  paid_media_vars = paid_media_vars,
  organic_vars = organic_vars,
  factor_vars = factor_vars,
  hyperparameters=hyperparameters,
  adstock = "weibull_pdf" # geometric, weibull_cdf or weibull_pdf.
)

hyper_names(adstock = InputCollectPredict$adstock, all_media = InputCollectPredict$all_media)

InputCollectPredict <- robyn_inputs(InputCollect = InputCollectPredict)
# Run future max_response Budget Allocator with predicted data
FutureAllocatorCollect <- robyn_allocator(
  InputCollect = InputCollectPredict,
  OutputCollect = OutputCollect,
  select_model = select_model,
  scenario = "max_response",
  channel_constr_low = 0.5,
  channel_constr_up = 1.5,
  total_budget = NULL,
  date_range = prediction_date_range,
  export = TRUE,
  dt_input = PredictedData # Use predicted data for allocation
)
}
